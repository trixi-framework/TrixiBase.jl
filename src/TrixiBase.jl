module TrixiBase

using ChangePrecision: ChangePrecision
using TimerOutputs: TimerOutput, TimerOutputs

include("mpi.jl")
include("trixi_include.jl")
include("trixi_timeit.jl")

export trixi_include, trixi_include_changeprecision
export @trixi_timeit, timer, timeit_debug_enabled,
       disable_debug_timings, enable_debug_timings

function _precompile_manual_()
    @assert Base.precompile(Tuple{typeof(trixi_include), String})
    return nothing
end

_precompile_manual_()

end # module TrixiBase
