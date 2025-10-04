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

            @test_throws "assignments [:y] not found" trixi_include(@__MODULE__,
                                                                    path, y = 3)
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

    @trixi_testset "Recursive assignment overwriting" begin
        # Test basic recursive kwargs passing
        example1 = """
            x = 1
            y = 2
            """

        example2 = """
            z = 3
            trixi_include(@__MODULE__, nested_path)
            """

        mktemp() do path1, io1
            write(io1, example1)
            close(io1)

            mktemp() do path2, io2
                # Use raw string to allow backslashes in Windows paths
                nested_code = replace(example2, "nested_path" => "raw\"$path1\"")
                write(io2, nested_code)
                close(io2)

                # Test that kwargs are passed recursively
                # Should warn about x,y not being in top file but allow due to nested calls
                @test_warn "assignments" trixi_include(@__MODULE__, path2;
                                                       x = 10, y = 20, z = 30,
                                                       replace_assignments_recursive = true)
                @test @isdefined x
                @test @isdefined y
                @test @isdefined z
                @test x == 10 # Overridden from nested file
                @test y == 20 # Overridden from nested file
                @test z == 30 # Overridden from top file

                # Test that kwargs are NOT passed recursively
                @trixi_test_nowarn trixi_include(@__MODULE__, path2;
                                                 x = 10, y = 20, z = 30,
                                                 replace_assignments_recursive = false,
                                                 enable_assignment_validation = false)

                @test x == 1 # Not overridden from nested file
                @test y == 2 # Not overridden from nested file
                @test z == 30 # Overridden from top file

                # Without disabling validation, this should result in an error:
                @test_throws "assignments [:x, :y] not found" trixi_include(@__MODULE__,
                                                                            path2; x = 10,
                                                                            y = 20, z = 30)
            end
        end

        # Test with existing kwargs in nested calls
        example3 = """
            a = 100
            trixi_include(@__MODULE__, nested_path; a = 200)
            """

        example4 = """
            a = 1
            b = 2
            """

        mktemp() do path3, io3
            write(io3, example4)
            close(io3)

            mktemp() do path4, io4
                nested_code = replace(example3, "nested_path" => "raw\"$path3\"")
                write(io4, nested_code)
                close(io4)

                # Test that top-level kwargs override existing nested kwargs
                trixi_include(@__MODULE__, path4; a = 500, b = 600,
                              replace_assignments_recursive = true)
                @test @isdefined a
                @test @isdefined b
                @test a == 500  # Top-level override wins over nested explicit kwarg
                @test b == 600  # Passed through to nested file
            end
        end

        # Test bare symbol syntax with recursion
        example5 = """
            x = 42
            trixi_include(@__MODULE__, nested_path; x)
            """

        example6 = """
            x = 1
            """

        mktemp() do path5, io5
            write(io5, example6)
            close(io5)

            mktemp() do path6, io6
                nested_code = replace(example5, "nested_path" => "raw\"$path5\"")
                write(io6, nested_code)
                close(io6)

                # Test bare symbol with recursive override
                @trixi_test_nowarn trixi_include(@__MODULE__, path6; x = 999,
                                                 replace_assignments_recursive = true)
                @test @isdefined x
                @test x == 999  # Top-level override
            end
        end

        # Test deep nesting (3 levels)
        example7 = """
            level1 = 1
            """

        example8 = """
            level2 = 2
            trixi_include(@__MODULE__, level1_path)
            """

        example9 = """
            level3 = 3
            trixi_include(@__MODULE__, level2_path; level2 = 22)
            """

        mktemp() do path7, io7
            write(io7, example7)
            close(io7)

            mktemp() do path8, io8
                level2_code = replace(example8, "level1_path" => "raw\"$path7\"")
                write(io8, level2_code)
                close(io8)

                mktemp() do path9, io9
                    level3_code = replace(example9, "level2_path" => "raw\"$path8\"")
                    write(io9, level3_code)
                    close(io9)

                    # Test 3-level deep recursive override
                    trixi_include(@__MODULE__, path9; level1 = 111,
                                  level2 = 222, level3 = 333,
                                  replace_assignments_recursive = true)
                    @test @isdefined level1
                    @test @isdefined level2
                    @test @isdefined level3
                    @test level1 == 111  # Passed through 3 levels
                    @test level2 == 222  # Top-level override wins over level3 explicit kwarg
                    @test level3 == 333  # Direct override
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
