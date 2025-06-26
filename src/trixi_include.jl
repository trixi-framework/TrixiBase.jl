# Note: We can't call the method below `TrixiBase.include` since that is created automatically
# inside `module TrixiBase` to `include` source files and evaluate them within the global scope
# of `TrixiBase`. However, users will want to evaluate in the global scope of `Main` or something
# similar to manage dependencies on their own.
"""
    trixi_include([mapexpr::Function=identity,] [mod::Module=Main,] elixir::AbstractString; kwargs...)

`include` the file `elixir` and evaluate its content in the global scope of module `mod`.
You can override specific assignments in `elixir` by supplying keyword arguments.
Its basic purpose is to make it easier to modify some parameters while running simulations from the
REPL. Additionally, this is used in tests to reduce the computational burden for CI while still
providing examples with sensible default values for users.

Before replacing assignments in `elixir`, the keyword argument `maxiters` is inserted
into calls to `solve` with it's default value used in the SciML ecosystem
for ODEs, see the "Miscellaneous" section of the
[documentation](https://docs.sciml.ai/DiffEqDocs/stable/basics/common_solver_opts/).

The optional first argument `mapexpr` can be used to transform the included code before
it is evaluated: for each parsed expression `expr` in `elixir`, the `include` function
actually evaluates `mapexpr(expr)`. If it is omitted, `mapexpr` defaults to `identity`.

# Examples

```@example
julia> using TrixiBase, Trixi

julia> redirect_stdout(devnull) do
         trixi_include(@__MODULE__, joinpath(examples_dir(), "tree_1d_dgsem", "elixir_advection_extended.jl"),
                       tspan=(0.0, 0.1))
         sol.t[end]
       end
[ Info: You just called `trixi_include`. Julia may now compile the code, please be patient.
0.1
```
"""
function trixi_include(mapexpr::Function, mod::Module, elixir::AbstractString; kwargs...)
    # Check that all kwargs exist as assignments
    code = read(elixir, String)
    expr = Meta.parse("begin \n$code \nend")
    expr = insert_maxiters(expr)

    for (key, val) in kwargs
        # This will throw an error when `key` is not found
        find_assignment(expr, key)
    end

    # Print information on potential wait time only in non-parallel case
    if !mpi_isparallel()
        @info "You just called `trixi_include`. Julia may now compile the code, please be patient."
    end
    Base.include(ex -> mapexpr(replace_assignments(insert_maxiters(ex); kwargs...)),
                 mod, elixir)
end

function trixi_include(mod::Module, elixir::AbstractString; kwargs...)
    trixi_include(identity, mod, elixir; kwargs...)
end

function trixi_include(elixir::AbstractString; kwargs...)
    trixi_include(Main, elixir; kwargs...)
end

"""
    trixi_include_changeprecision(T, [mod::Module=Main,] elixir::AbstractString; kwargs...)

`include` the elixir `elixir` and evaluate its content in the global scope of module `mod`.
You can override specific assignments in `elixir` by supplying keyword arguments,
similar to [`trixi_include`](@ref).

The only difference to [`trixi_include`](@ref) is that the precision of floating-point
numbers in the included elixir is changed to `T`.
More precisely, the package [ChangePrecision.jl](https://github.com/JuliaMath/ChangePrecision.jl)
is used to convert all `Float64` literals, operations like `/` that produce `Float64` results,
and functions like `ones` that return `Float64` arrays by default, to the desired type `T`.
See the documentation of ChangePrecision.jl for more details.

The purpose of this function is to conveniently run a full simulation with `Float32`,
which is orders of magnitude faster on most GPUs than `Float64`, by just including
the elixir with `trixi_include_changeprecision(Float32, elixir)`.
Many constructors in the Trixi.jl framework are written in a way that changing all floating-point
arguments to `Float32` will change the element type to `Float32` as well.
In TrixiParticles.jl, including an elixir with this macro should be sufficient
to run the full simulation with single precision.
"""
function trixi_include_changeprecision(T, mod::Module, filename::AbstractString; kwargs...)
    trixi_include(expr -> ChangePrecision.changeprecision(T, replace_trixi_include(T, expr)),
                  mod, filename; kwargs...)
end

function trixi_include_changeprecision(T, filename::AbstractString; kwargs...)
    trixi_include_changeprecision(T, Main, filename; kwargs...)
end

function replace_trixi_include(T, expr)
    expr = TrixiBase.walkexpr(expr) do x
        if x isa Expr
            if x.head === :call && x.args[1] === :trixi_include
                x.args[1] = :trixi_include_changeprecision
                insert!(x.args, 2, :($T))
            end
        end
        return x
    end

    return expr
end

# Insert the keyword argument `maxiters` into calls to `solve` and `Trixi.solve`
# with default value `10^5` if it is not already present.
function insert_maxiters(expr)
    maxiters_default = 10^5

    expr = walkexpr(expr) do x
        if x isa Expr
            is_plain_solve = x.head === Symbol("call") && x.args[1] === Symbol("solve")
            is_trixi_solve = (x.head === Symbol("call") && x.args[1] isa Expr &&
                              x.args[1].head === Symbol(".") &&
                              x.args[1].args[1] === Symbol("Trixi") &&
                              x.args[1].args[2] isa QuoteNode &&
                              x.args[1].args[2].value === Symbol("solve"))

            if is_plain_solve || is_trixi_solve
                # Do nothing if `maxiters` is already set as keyword argument...
                for arg in x.args
                    # This detects the case where `maxiters` is set as keyword argument
                    # without or before a semicolon.
                    if (arg isa Expr && arg.head === Symbol("kw") &&
                        arg.args[1] === Symbol("maxiters"))
                        return x
                    end

                    # This detects the case where maxiters is set as keyword argument
                    # after a semicolon.
                    if (arg isa Expr && arg.head === Symbol("parameters"))
                        # We need to check each keyword argument listed here
                        for nested_arg in arg.args
                            if (nested_arg isa Expr &&
                                nested_arg.head === Symbol("kw") &&
                                nested_arg.args[1] === Symbol("maxiters"))
                                return x
                            end
                        end
                    end
                end

                # ...and insert it otherwise.
                push!(x.args, Expr(Symbol("kw"), Symbol("maxiters"), maxiters_default))
            end
        end
        return x
    end

    return expr
end

# Apply the function `f` to `expr` and all sub-expressions recursively.
walkexpr(f, expr::Expr) = f(Expr(expr.head, (walkexpr(f, arg) for arg in expr.args)...))
walkexpr(f, x) = f(x)

# Replace assignments to `key` in `expr` by `key = val` for all `(key,val)` in `kwargs`.
function replace_assignments(expr; kwargs...)
    # replace explicit and keyword assignments
    expr = walkexpr(expr) do x
        if x isa Expr
            for (key, val) in kwargs
                if (x.head === Symbol("=") || x.head === :kw) &&
                   x.args[1] === Symbol(key)
                    x.args[2] = :($val)
                    # dump(x)
                end
            end
        end
        return x
    end

    return expr
end

# Find a (keyword or common) assignment to `destination` in `expr`
# and return the assigned value.
function find_assignment(expr, destination)
    # Declare result to be able to assign to it in the closure
    local result
    found = false

    # Find explicit and keyword assignments
    walkexpr(expr) do x
        if x isa Expr
            if (x.head === Symbol("=") || x.head === :kw) &&
               x.args[1] === Symbol(destination)
                result = x.args[2]
                found = true
                # dump(x)
            end
        end
        return x
    end

    if !found
        throw(ArgumentError("assignment `$destination` not found in expression"))
    end

    result
end
