using KernelAbstractions: KernelAbstractions, @kernel, @index
using Polyester: Polyester
using Base.Threads: Threads
using GPUArraysCore: AbstractGPUArray

abstract type AbstractThreadingBackend end

"""
    SerialBackend()

Pass as first argument to the [`@threaded`](@ref) macro to run the loop serially.
"""
struct SerialBackend <: AbstractThreadingBackend end

"""
    PolyesterBackend()

Pass as first argument to the [`@threaded`](@ref) macro to make the loop multithreaded
with `Polyester.@batch`.
"""
struct PolyesterBackend <: AbstractThreadingBackend end

"""
    ThreadsDynamicBackend()

Pass as first argument to the [`@threaded`](@ref) macro to make the loop multithreaded
with `Threads.@threads :dynamic`.
"""
struct ThreadsDynamicBackend <: AbstractThreadingBackend end

"""
    ThreadsStaticBackend()


Pass as first argument to the [`@threaded`](@ref) macro to make the loop multithreaded
with `Threads.@threads :static`.
"""
struct ThreadsStaticBackend <: AbstractThreadingBackend end

const ParallelizationBackend = Union{AbstractThreadingBackend, KernelAbstractions.Backend}

"""
    default_backend(x)

Select the recommended backend for an array `x`.
This allows to write generic code that works for both CPU and GPU arrays.

The default backend for CPU arrays is currently `PolyesterBackend()`.
For GPU arrays, the respective `KernelAbstractions.Backend` is returned.
"""
@inline default_backend(::AbstractArray) = PolyesterBackend()
@inline default_backend(x::AbstractGPUArray) = KernelAbstractions.get_backend(x)

"""
    @par backend for ... end

Run either a threaded CPU loop or launch a kernel on the GPU, depending on the `backend`.
Semantically the same as `Threads.@threads` when iterating over a `AbstractUnitRange`
but without guarantee that the underlying implementation uses `Threads.@threads`
or works for more general `for` loops.

Possible parallelization backends are:
- [`SerialBackend`](@ref) to disable multithreading
- [`PolyesterBackend`](@ref) to use `Polyester.@batch`
- [`ThreadsDynamicBackend`](@ref) to use `Threads.@threads :dynamic`
- [`ThreadsStaticBackend`](@ref) to use `Threads.@threads :static`
- Any `KernelAbstractions.Backend` to execute the loop as a GPU kernel

Use `default_backend(x)` to select the recommended backend for an array `x`.
This allows to write generic code that works for both CPU and GPU arrays.

!!! warning "Warning"
    This macro does not necessarily work for general `for` loops. For example,
    it does not necessarily support general iterables such as `eachline(filename)`.
"""
macro par(backend, expr)
    expr.head != :for && error("@par can only be used with for loops")
    iter = expr.args[1]
    iter.head != :(=) && error("@par can only be used with for loops of the form `for i in iterator`")

    body = expr.args[2]
    induction_var = iter.args[1]
    iterator = iter.args[2]


    # Assemble the `for` loop again as a call to `parallel_foreach`, using `$induction_var` to use the
    # same loop variable as used in the for loop.
    expr = quote 
        $parallel_foreach($iterator, $backend) do $induction_var
            $body
        end
    end

    return esc(expr)
end

# Serial loop
@inline function parallel_foreach(f::F, iterator, ::SerialBackend) where F
    for i in iterator
        @inline f(i)
    end
end

# Use `Polyester.@batch`
@inline function parallel_foreach(f::F, iterator, ::PolyesterBackend) where F
    Polyester.@batch for i in iterator
        @inline f(i)
    end
end

# Use `Threads.@threads :dynamic`
@inline function parallel_foreach(f::F, iterator, ::ThreadsDynamicBackend) where F
    Threads.@threads :dynamic for i in iterator
        @inline f(i)
    end
end

# Use `Threads.@threads :static`
@inline function parallel_foreach(f::F, iterator, ::ThreadsStaticBackend) where F
    Threads.@threads :static for i in iterator
        @inline f(i)
    end
end

# On GPUs, execute `f` inside a GPU kernel with KernelAbstractions.jl
@inline function parallel_foreach(f::F, iterator, backend::KernelAbstractions.Backend) where F
    # On the GPU, we can only loop over `1:N`. Therefore, we loop over `1:length(iterator)`
    # and index with `iterator[eachindex(iterator)[i]]`.
    # Note that this only works with vector-like iterators that support arbitrary indexing.
    indices = eachindex(iterator)
    ndrange = length(indices)

    # Skip empty loops
    ndrange == 0 && return

    # Call the generic kernel that is defined below, which only calls a function with
    # the global GPU index.
    generic_kernel(backend)(ndrange = ndrange) do i
        @inbounds @inline f(iterator[indices[i]])
    end
end

# TODO: We could also use the slightly more optimized version from AcceleratedKernels
@kernel function generic_kernel(f)
    i = @index(Global)
    @inline f(i)
end

# TODO: parallel_mapreduce
