@testset "trixi_include" begin
    @trixi_testset "Basic" begin
        example = """
            x = 4
            """

        filename = tempname()
        try
            open(filename, "w") do file
                write(file, example)
            end

            # Use `@trixi_testset`, which wraps code in a temporary module, and call
            # `trixi_include` with `@__MODULE__` in order to isolate this test.
            @test_nowarn trixi_include(@__MODULE__, filename)
            @test @isdefined x
            @test x == 4

            @test_nowarn trixi_include(@__MODULE__, filename, x=7)
            @test x == 7

            # Verify default version (that includes in `Main`)
            @test_nowarn trixi_include(filename, x=11)
            @test Main.x == 11

            @test_throws "assignment `y` not found in expression" trixi_include(@__MODULE__,
                                                                                filename,
                                                                                y=3)
        finally
            rm(filename, force=true)
        end
    end

    @trixi_testset "With `solve` Without `maxiters`" begin
        # `trixi_include` assumes this to be the `solve` function of OrdinaryDiffEq,
        # and therefore tries to insert the kwarg `maxiters`, which will fail here.
        example = """
            solve() = 0
            x = solve()
            """

        filename = tempname()
        try
            open(filename, "w") do file
                write(file, example)
            end

            # Use `@trixi_testset`, which wraps code in a temporary module, and call
            # `trixi_include` with `@__MODULE__` in order to isolate this test.
            @test_throws "no method matching solve(; maxiters" trixi_include(@__MODULE__,
                                                                             filename)

            @test_throws "no method matching solve(; maxiters" trixi_include(@__MODULE__,
                                                                             filename,
                                                                             maxiters=3)
        finally
            rm(filename, force=true)
        end
    end

    @trixi_testset "With `solve` with `maxiters`" begin
        # We need another example file that we include with `Base.include` first, in order to
        # define the `solve` method without `trixi_include` trying to insert `maxiters` kwargs.
        # Then, we can test that `trixi_include` inserts the kwarg in the `solve()` call.
        # Finally, we verify the logic that prevents adding multiple `maxiters` in case it
        # is already present (either before or after the `;`)
        example1 = """
            solve(; maxiters=0) = maxiters
            """

        example2 = """
            x = solve()
            """

        example3 = """
            y = solve(maxiters=0)
            """

        example4 = """
            y = solve(; maxiters=0)
            """

        filename1 = tempname()
        filename2 = tempname()
        filename3 = tempname()
        filename4 = tempname()
        try
            open(filename1, "w") do file
                write(file, example1)
            end
            open(filename2, "w") do file
                write(file, example2)
            end
            open(filename3, "w") do file
                write(file, example3)
            end
            open(filename4, "w") do file
                write(file, example4)
            end

            # Use `@trixi_testset`, which wraps code in a temporary module, and call
            # `Base.include` and `trixi_include` with `@__MODULE__` in order to isolate this test.
            Base.include(@__MODULE__, filename1)
            @test_nowarn trixi_include(@__MODULE__, filename2)
            @test @isdefined x
            # This is the default `maxiters` inserted by `trixi_include`
            @test x == 10^5

            @test_nowarn trixi_include(@__MODULE__, filename2, maxiters = 7)
            # Test that `maxiters` got overwritten
            @test x == 7

            # Verify that adding `maxiters` to `maxiters` results in exactly one of them
            # case 1) `maxiters` is *before* semicolon in included file
            @test_nowarn trixi_include(@__MODULE__, filename3, maxiters = 11)
            @test y == 11
            # case 2) `maxiters` is *after* semicolon in included file
            @test_nowarn trixi_include(@__MODULE__, filename3, maxiters = 14)
            @test y == 14
        finally
            rm(filename1, force=true)
            rm(filename2, force=true)
            rm(filename3, force=true)
            rm(filename4, force=true)
        end
    end
end
