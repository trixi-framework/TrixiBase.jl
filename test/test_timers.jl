@testset verbose=true "Timers" begin
    @testset verbose=true "`timer()`" begin
        @test timer() isa TrixiBase.TimerOutput

        # Test empty timer output
        TrixiBase.TimerOutputs.reset_timer!(timer())

        timer_output = """
         ────────────────────────────────────────────────────────────────────
                                    Time                    Allocations
                           ───────────────────────   ────────────────────────
         Tot / % measured:      91.5s /   0.0%           5.43MiB /   0.0%

         Section   ncalls     time    %tot     avg     alloc    %tot      avg
         ────────────────────────────────────────────────────────────────────
         ────────────────────────────────────────────────────────────────────
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
         ───────────────────────────────────────────────────────────────────────
                                       Time                    Allocations
                              ───────────────────────   ────────────────────────
           Tot / % measured:      61.4ms /  99.2%           5.60MiB /  99.6%

         Section      ncalls     time    %tot     avg     alloc    %tot      avg
         ───────────────────────────────────────────────────────────────────────
         test timer        2   60.9ms  100.0%  60.9ms   5.57MiB  100.0%  5.57MiB
         ───────────────────────────────────────────────────────────────────────
        """
        # Remove "Tot / % measured" line and trailing white spaces and replace
        # the "test timer" line (but don't remove it, we want to check that it's there).
        expected = replace(timer_output, r"Tot / % measured: .*" => "",
                           r"\s+\n" => "\n",
                           r"test timer        2 .*B\n" => "test timer        2")
        actual = replace(repr(timer()) * "\n", r"Tot / % measured: .*" => "",
                         r"\s+\n" => "\n",
                         r"test timer        2 .*B\n" => "test timer        2")

        # Compare against empty timer output
        @test actual == expected
    end
end;
