@testset verbose=true "Timers" begin
    @testset verbose=true "`timer()`" begin
        @test (@inferred timer()) isa TrixiBase.TimerOutput

        # Test empty timer output
        TrixiBase.TimerOutputs.reset_timer!(timer())

        timer_output = """
        ────────────────────────────────────────────────────────────
                                  Time              Allocations
                            ─────────────────    ──────────────────
         Tot / % measured:    4.36ms / 0.0%        185KiB / 0.0%
         ─────────────────  ─────────────────    ──────────────────
         Section    ncalls  time  %tot  avg      alloc  %tot  avg
        ────────────────────────────────────────────────────────────
        
        """
        # Remove "Tot / % measured" line and trailing white spaces
        expected = replace(timer_output, r"Tot / % measured: .*" => "",
                           r"\s+\n" => "\n")
        actual = replace(repr(timer()) * "\n", r"Tot / % measured: .*" => "",
                         r"\s+\n" => "\n")

        # Compare against empty timer output
        @test actual == expected
    end

    @testset verbose=true "`@trixi_timeit`" begin
        # Start with empty timer output
        TrixiBase.TimerOutputs.reset_timer!(timer())

        # Add timer entry with 2 calls
        @trixi_timeit timer() "test timer" sin(0.0)
        @trixi_timeit timer() "test timer" sin(0.0)

        timer_output = """
        ────────────────────────────────────────────────────────────────────────────────────────────
                                           Time                             Allocations
                             ────────────────────────────────    ──────────────────────────────────
         Tot / % measured:            23.7ms / 0.1%                        55.6KiB / 1.3%
         ──────────────────  ────────────────────────────────    ──────────────────────────────────
         Section     ncalls    time    %tot     avg                alloc    %tot      avg
        ────────────────────────────────────────────────────────────────────────────────────────────
         test timer       2  19.8μs  100.0%  9.89μs  ████████       752B  100.0%     376B  ████████
        ────────────────────────────────────────────────────────────────────────────────────────────
        
        """
        # Remove "Tot / % measured" line and trailing white spaces and replace
        # the "test timer" line (but don't remove it, we want to check that it's there).
        expected = replace(timer_output, r"Tot / % measured: .*" => "",
                           r"test timer\s+2\s.*" => "test timer 2",
                           r"\s+\n" => "\n")
        actual = replace(repr(timer()) * "\n", r"Tot / % measured: .*" => "",
                         r"test timer\s+2\s.*" => "test timer 2",
                         r"\s+\n" => "\n")

        # Compare against expected timer output
        @test actual == expected
    end

    @testset verbose=true "disable and enable timings using disable_debug_timings and enable_debug_timings" begin
        # Start with empty timer output
        TrixiBase.TimerOutputs.reset_timer!(timer())

        # Disable timings
        disable_debug_timings()

        # These two timings should be disabled
        @trixi_timeit timer() "test timer" sin(0.0)
        @trixi_timeit timer() "test timer" sin(0.0)

        # Enable timings
        enable_debug_timings()

        # This timing should be counted
        @trixi_timeit timer() "test timer 2" sin(0.0)

        timer_output = """
        ──────────────────────────────────────────────────────────────────────────────────────────────
                                             Time                             Allocations
                               ────────────────────────────────    ──────────────────────────────────
          Tot / % measured:             56.7ms / 0.0%                        3.20MiB / 0.0%
         ────────────────────  ────────────────────────────────    ──────────────────────────────────
         Section       ncalls    time    %tot     avg                alloc    %tot      avg
        ──────────────────────────────────────────────────────────────────────────────────────────────
         test timer 2       1  22.5μs  100.0%  22.5μs  ████████       704B  100.0%     704B  ████████
        ──────────────────────────────────────────────────────────────────────────────────────────────
        
        """
        # Remove "Tot / % measured" line and trailing white spaces and replace
        # the "test timer 2" line (but don't remove it, we want to check that it's there).
        expected = replace(timer_output, r"Tot / % measured: .*" => "",
                           r"test timer 2\s+1\s.*" => "test timer 2",
                           r"\s+\n" => "\n")
        actual = replace(repr(timer()) * "\n", r"Tot / % measured: .*" => "",
                         r"test timer 2\s+1\s.*" => "test timer 2",
                         r"\s+\n" => "\n")

        # Compare against expected timer output
        @test actual == expected
    end

    @testset verbose=true "disable and enable timings using disable_timer! and enable_timer!" begin
        # Start with empty timer output
        TrixiBase.TimerOutputs.reset_timer!(timer())

        # Disable timer
        TrixiBase.TimerOutputs.disable_timer!(timer())

        # These two timings should be disabled
        @trixi_timeit timer() "test timer" sin(0.0)
        @trixi_timeit timer() "test timer" sin(0.0)

        # Enable timer
        TrixiBase.TimerOutputs.enable_timer!(timer())

        # This timing should be counted
        @trixi_timeit timer() "test timer 2" sin(0.0)

        timer_output = """
        ──────────────────────────────────────────────────────────────────────────────────────────────
                                             Time                             Allocations
                               ────────────────────────────────    ──────────────────────────────────
          Tot / % measured:             56.7ms / 0.0%                        3.20MiB / 0.0%
         ────────────────────  ────────────────────────────────    ──────────────────────────────────
         Section       ncalls    time    %tot     avg                alloc    %tot      avg
        ──────────────────────────────────────────────────────────────────────────────────────────────
         test timer 2       1  22.5μs  100.0%  22.5μs  ████████       704B  100.0%     704B  ████████
        ──────────────────────────────────────────────────────────────────────────────────────────────
        
        """
        # Remove "Tot / % measured" line and trailing white spaces and replace
        # the "test timer 2" line (but don't remove it, we want to check that it's there).
        expected = replace(timer_output, r"Tot / % measured: .*" => "",
                           r"test timer 2\s+1\s.*" => "test timer 2",
                           r"\s+\n" => "\n")
        actual = replace(repr(timer()) * "\n", r"Tot / % measured: .*" => "",
                         r"test timer 2\s+1\s.*" => "test timer 2",
                         r"\s+\n" => "\n")

        # Compare against expected timer output
        @test actual == expected
    end
end;
