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
            local to = $(esc(timer_output))
            local enabled = to.enabled
            if enabled
                local accumulated_data = $(TimerOutputs.push!)(to, $(esc(label)))
            else
                # dummy to avoid issues with JET.jl complaining about potentially undefined variables
                local accumulated_data = TimerOutputs.TimeData(0, 0, 0, 0)
            end
            local b0 = $(TimerOutputs.gc_bytes)()
            local t0 = $(TimerOutputs.time_ns)()
        end
        local val = $(esc(expr))
        if timeit_debug_enabled() && enabled
            $(TimerOutputs.do_accumulate!)(accumulated_data, t0, b0)
            $(TimerOutputs.pop!)(to)
        end
        val
    end
end
