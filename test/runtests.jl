include("test_util.jl")

@testset verbose=true "TrixiBase.jl Tests" begin
    include("test_aqua.jl")
    include("test_mpi.jl")
    include("trixi_include.jl")
    include("test_timers.jl")
end;
