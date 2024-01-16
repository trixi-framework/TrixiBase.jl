module TestDummy

using Test
using TrixiBase

@testset verbose=true showtiming=true "test_dummy.jl" begin

@testset verbose=true showtiming=true "greet" begin
    @test_nowarn TrixiBase.greet()
end

end # @testset "test_dummy.jl"

end # module
