using Aqua: Aqua
using ExplicitImports: check_no_implicit_imports, check_no_stale_explicit_imports

@testset "Aqua.jl" begin
    Aqua.test_all(TrixiBase)
    @test isnothing(check_no_implicit_imports(TrixiBase))
    @test isnothing(check_no_stale_explicit_imports(TrixiBase))
end

