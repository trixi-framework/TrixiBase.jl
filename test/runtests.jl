using Test

@time @testset verbose=true showtiming=true "TrixiBase.jl tests" begin
    include("test_dummy.jl")
end

