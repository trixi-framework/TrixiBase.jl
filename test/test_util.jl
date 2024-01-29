# All `using` calls are in this file, so that one can run any test file
# after running only this file.
using Test: @test, @testset
using TrixiBase

"""
    @trixi_testset "name of the testset" #= code to test #=

Similar to `@testset`, but wraps the code inside a temporary module to avoid
namespace pollution.
"""
macro trixi_testset(name, expr)
    @assert name isa String

    mod = gensym()

    # TODO: `@eval` is evil
    quote
        @eval module $mod
        using Test
        using TrixiBase

        @testset verbose=true $name $expr
        end

        nothing
    end
end
