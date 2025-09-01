@testset verbose=true "`trixi_include`" begin
    @trixi_testset "Basic" begin
        example = """
            x = 4
            """

        mktemp() do path, io
            write(io, example)
            close(io)

            # Use `@trixi_testset`, which wraps code in a temporary module, and call
            # `trixi_include` with `@__MODULE__` in order to isolate this test.
            @trixi_test_nowarn trixi_include(@__MODULE__, path)
            @test @isdefined x
            @test x == 4

            @trixi_test_nowarn trixi_include(@__MODULE__, path, x = 7)

            @test x == 7

            # Verify default version (that includes in `Main`)
            @trixi_test_nowarn trixi_include(path, x = 11)
            @test Main.x == 11

            # Verify that the macro version uses the right module
            @trixi_include(path, x = 3)
            @test x == 3

            @test_throws "assignment `y` not found in expression" trixi_include(@__MODULE__,
                                                                                path,
                                                                                y = 3)
        end
    end

    @trixi_testset "With `solve` Without `maxiters`" begin
        # `trixi_include` assumes this to be the `solve` function of OrdinaryDiffEq,
        # and therefore tries to insert the kwarg `maxiters`, which will fail here.
        example = """
            solve() = 0
            x = solve()
            """

        mktemp() do path, io
            write(io, example)
            close(io)

            # Use `@trixi_testset`, which wraps code in a temporary module, and call
            # `trixi_include` with `@__MODULE__` in order to isolate this test.
            @test_throws "no method matching solve(; maxiters" trixi_include(@__MODULE__,
                                                                             path)

            @test_throws "no method matching solve(; maxiters" trixi_include(@__MODULE__,
                                                                             path,
                                                                             maxiters = 3)
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

        mktemp() do path1, io1
            write(io1, example1)
            close(io1)

            mktemp() do path2, io2
                write(io2, example2)
                close(io2)

                mktemp() do path3, io3
                    write(io3, example3)
                    close(io3)

                    mktemp() do path4, io4
                        write(io4, example4)
                        close(io4)

                        # Use `@trixi_testset`, which wraps code in a temporary module,
                        # and call `Base.include` and `trixi_include` with `@__MODULE__`
                        # in order to isolate this test.
                        Base.include(@__MODULE__, path1)
                        @trixi_test_nowarn trixi_include(@__MODULE__, path2)
                        @test @isdefined x
                        # This is the default `maxiters` inserted by `trixi_include`
                        @test x == 10^5

                        @trixi_test_nowarn trixi_include(@__MODULE__, path2, maxiters = 7)
                        # Test that `maxiters` got overwritten
                        @test x == 7

                        # Verify that existing `maxiters` is added exactly once in the
                        # following cases:
                        # case 1) `maxiters` is *before* semicolon in included file
                        @trixi_test_nowarn trixi_include(@__MODULE__, path3, maxiters = 11)
                        @test y == 11
                        # case 2) `maxiters` is *after* semicolon in included file
                        @trixi_test_nowarn trixi_include(@__MODULE__, path3, maxiters = 14)
                        @test y == 14
                    end
                end
            end
        end
    end
end

@trixi_testset "`trixi_include_changeprecision`" begin
    @trixi_testset "Basic" begin
        example = """
            x = 4.0
            y = zeros(3)
            """

        using TrixiBase: trixi_include_changeprecision
        mktemp() do path, io
            write(io, example)
            close(io)

            # Use `@trixi_testset`, which wraps code in a temporary module, and call
            # `trixi_include_changeprecision` with `@__MODULE__` in order to isolate this test.
            @trixi_test_nowarn trixi_include_changeprecision(Float32, @__MODULE__, path)
            @test @isdefined x
            @test x == 4
            @test typeof(x) == Float32
            @test @isdefined y
            @test eltype(y) == Float32

            # Manually overwritten assignments are also changed
            @trixi_test_nowarn trixi_include_changeprecision(Float32, @__MODULE__, path,
                                                             x = 7.0)

            @test x == 7
            @test typeof(x) == Float32

            # Verify default version (that includes in `Main`)
            @trixi_test_nowarn trixi_include_changeprecision(Float32, path, x = 11.0)
            @test Main.x == 11
            @test typeof(Main.x) == Float32
        end
    end

    @trixi_testset "Recursive" begin
        example1 = """
            x = 4.0
            y = zeros(3)
            """

        using TrixiBase: trixi_include_changeprecision
        mktemp() do path1, io1
            write(io1, example1)
            close(io1)

            # Use raw string to allow backslashes in Windows paths
            example2 = """
                trixi_include(@__MODULE__, raw"$path1", x = 7.0)
                """

            mktemp() do path2, io2
                write(io2, example2)
                close(io2)

                # Use `@trixi_testset`, which wraps code in a temporary module, and call
                # `trixi_include_changeprecision` with `@__MODULE__` in order to isolate this test.
                @trixi_test_nowarn trixi_include_changeprecision(Float32, @__MODULE__,
                                                                 path2)
                @test @isdefined x
                @test x == 7
                @test typeof(x) == Float32
                @test @isdefined y
                @test eltype(y) == Float32
            end
        end
    end
end
