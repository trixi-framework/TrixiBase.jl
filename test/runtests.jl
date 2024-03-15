include("test_util.jl")

@testset verbose=true "TrixiBase.jl Tests" begin
    include("test_aqua.jl")
    include("trixi_include.jl")
end
