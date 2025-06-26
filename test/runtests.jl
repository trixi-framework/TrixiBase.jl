include("test_util.jl")

@testset verbose=true "TrixiBase.jl Tests" begin
    include("test_aqua.jl")
    include("test_mpi.jl")
    run(`$(mpiexec()) -n 2 $(Base.julia_cmd()) --threads=1 $(abspath("test_mpi.jl"))`)
    include("trixi_include.jl")
    include("test_timers.jl")
end;
