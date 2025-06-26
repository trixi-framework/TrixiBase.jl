using MPI

@testset verbose=true "MPI helper functions" begin
    @test TrixiBase.mpi_isparallel() == false
    @test TrixiBase.mpi_isroot() == true

    MPI.Init()
    @test TrixiBase.mpi_isparallel() == true
    @test TrixiBase.mpi_isroot() == true
end
