
include("test_util.jl")

@testset verbose=true "MPI helper functions" begin
    @test TrixiBase.mpi_isparallel() == false
    @test TrixiBase.mpi_isroot() == true

    using MPI
    @test TrixiBase.mpi_isparallel() == false
    @test TrixiBase.mpi_isroot() == true
    MPI.Init()
    @test TrixiBase.mpi_isparallel() == (MPI.Comm_size(MPI.COMM_WORLD) > 1)
    @test TrixiBase.mpi_isroot() == (MPI.Comm_rank(MPI.COMM_WORLD) == 0)
end
