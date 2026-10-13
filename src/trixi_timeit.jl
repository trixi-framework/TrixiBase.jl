# Enable debug timings `@trixi_timeit timer() "name" stuff...`.
# This allows us to disable timings completely by executing
# `TimerOutputs.disable_debug_timings(TrixiBase)`
# and to enable them again by executing
# `TimerOutputs.enable_debug_timings(TrixiBase)`
timeit_debug_enabled() = true

"""
    disable_debug_timings()

Disable all [`@trixi_timeit`](@ref) timings.
The timings should be optimized away, allowing for truly zero-overhead.
Enable timings again with [`enable_debug_timings`](@ref).

See also [`enable_debug_timings`](@ref), [`@trixi_timeit`](@ref).
"""
disable_debug_timings() = TimerOutputs.disable_debug_timings(@__MODULE__)

"""
    enable_debug_timings()

Enable all [`@trixi_timeit`](@ref) timings (default behavior).

See also [`disable_debug_timings`](@ref), [`@trixi_timeit`](@ref).
"""
enable_debug_timings() = TimerOutputs.enable_debug_timings(@__MODULE__)

# Store main timer for global timing of functions.
# Always call timer() to hide implementation details.
const main_timer = TimerOutput()

"""
    timer()

Main timer for global timing, e.g., to be used with [`@trixi_timeit`](@ref).
"""
timer() = main_timer

"""
    @trixi_timeit timer() "some label" expression

Basically the same as a special case of `@timeit_debug` from
[TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl),
but without `try ... finally ... end` block. Thus, it's not exception-safe,
but it also avoids some related performance problems. Since we do not use
exception handling in Trixi.jl, that's not really an issue.

All `@trixi_timeit` timings can be disabled with [`disable_debug_timings`](@ref).
The timings should then be optimized away, allowing for truly zero-overhead.

See also [`disable_debug_timings`](@ref), [`enable_debug_timings`](@ref).
"""
macro trixi_timeit(timer_output, label, expr)
    timeit_block = quote
        if timeit_debug_enabled()
            local state = $(timeit_begin)($(esc(timer_output)), $(esc(label)))
        end
        local val = $(esc(expr))
        if timeit_debug_enabled()
            $(timeit_end)($(esc(timer_output)), $(esc(label)), state)
        end
        val
    end
end

# The state that `timeit_begin` gives to `timeit_end`. In the primal code, the compiler
# removes the allocation, since `timeit_begin` and `timeit_end` are inlined.
mutable struct TimeitState{G, B, T}
    enabled::Bool
    accumulated_data::TimerOutputs.Section
    gc0::G
    b0::B
    t0::T
    # Only for automatic differentiation. Enzyme.jl gives a shadow only to a type that can
    # hold differentiable data. This field makes Enzyme.jl duplicate the state, and the
    # reverse pass uses the shadow for the state of the reverse section.
    # See the `TrixiBaseEnzymeCoreExt` extension.
    shadow_marker::Float64
end

# The two halves of `@trixi_timeit`. They are separate functions so that automatic
# differentiation tools can attach rules to them, e.g., to time the reverse pass of
# Enzyme.jl (see the `TrixiBaseEnzymeCoreExt` extension).
"""
    TrixiBase.timeit_begin(to::TimerOutput, label)

Open the section `label` of the timer `to` and return the state that
[`TrixiBase.timeit_end`](@ref) needs to close it. Used by [`@trixi_timeit`](@ref).
"""
@inline function timeit_begin(to, label)
    enabled = to.enabled
    if enabled
        accumulated_data = TimerOutputs.push!(to, label)
    else
        # dummy to avoid issues with JET.jl complaining about potentially undefined variables
        accumulated_data = TimerOutputs.Section("")
    end
    gc0 = TimerOutputs.gc_time()
    b0 = TimerOutputs.gc_bytes()
    t0 = TimerOutputs.time_ns()
    return TimeitState(enabled, accumulated_data, gc0, b0, t0, 0.0)
end

"""
    TrixiBase.timeit_end(to::TimerOutput, label, state)

Close the section `label` of the timer `to` opened by [`TrixiBase.timeit_begin`](@ref),
which returned `state`. Used by [`@trixi_timeit`](@ref).
"""
@inline function timeit_end(to, label, state)
    (; enabled, accumulated_data, gc0, b0, t0) = state
    if enabled
        TimerOutputs.do_accumulate!(accumulated_data, t0, b0, gc0)
        TimerOutputs.pop!(to)
    end
    return nothing
end
