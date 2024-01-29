# Note: We can't call the method below `TrixiBase.include` since that is created automatically
# inside `module TrixiBase` to `include` source files and evaluate them within the global scope
# of `TrixiBase`. However, users will want to evaluate in the global scope of `Main` or something
# similar to manage dependencies on their own.
"""
    trixi_include([mod::Module=Main,] elixir::AbstractString; kwargs...)

`include` the file `elixir` and evaluate its content in the global scope of module `mod`.
You can override specific assignments in `elixir` by supplying keyword arguments.
Its basic purpose is to make it easier to modify some parameters while running simulations from the
REPL. Additionally, this is used in tests to reduce the computational burden for CI while still
providing examples with sensible default values for users.

Before replacing assignments in `elixir`, the keyword argument `maxiters` is inserted
into calls to `solve` with it's default value used in the SciML ecosystem
for ODEs, see the "Miscellaneous" section of the
[documentation](https://docs.sciml.ai/DiffEqDocs/stable/basics/common_solver_opts/).

# Examples

```jldoctest
julia> redirect_stdout(devnull) do
         trixi_include(@__MODULE__, joinpath(examples_dir(), "tree_1d_dgsem", "elixir_advection_extended.jl"),
                       tspan=(0.0, 0.1))
         sol.t[end]
       end
[ Info: You just called `trixi_include`. Julia may now compile the code, please be patient.
0.1
```
"""
function trixi_include(mod::Module, elixir::AbstractString; kwargs...)
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
    Base.include(ex -> replace_assignments(insert_maxiters(ex); kwargs...), mod, elixir)
end

function trixi_include(elixir::AbstractString; kwargs...)
    trixi_include(Main, elixir; kwargs...)
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

# This is just a dummy function. We only implement a real
# version if MPI.jl is loaded to avoid letting TrixiBase.jl
# depend explicitly on MPI.jl.
mpi_isparallel() = false
