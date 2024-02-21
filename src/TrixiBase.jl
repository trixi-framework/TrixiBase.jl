module TrixiBase

include("trixi_include.jl")

export trixi_include

function _precompile_manual_()
    @assert Base.precompile(Tuple{typeof(trixi_include), String})
    return nothing
end

_precompile_manual_()

end # module TrixiBase
