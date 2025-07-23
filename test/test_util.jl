# All `using` calls are in this file, so that one can run any test file
# after running only this file.
using Test: @test, @testset, @inferred
using TrixiTest: @trixi_test_nowarn, @trixi_testset
using TrixiBase
