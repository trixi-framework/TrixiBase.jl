using Enzyme: Enzyme, Active, BatchDuplicated, Const, Duplicated, Reverse, autodiff

@testset verbose=true "`@trixi_timeit` with Enzyme.jl" begin
    function inner_timed!(y, x)
        @trixi_timeit timer() "inner" begin
            y .= x .^ 2
        end
        return nothing
    end
    function outer_timed(y, x)
        @trixi_timeit timer() "outer" begin
            # Several sections with the same label must not share their reverse states
            for _ in 1:3
                inner_timed!(y, x)
            end
            s = sum(y)
        end
        return s
    end

    TrixiBase.TimerOutputs.reset_timer!(timer())
    x = [1.0, 2.0, 3.0]
    dx = zero(x)
    y = zero(x)
    autodiff(Reverse, outer_timed, Active, Duplicated(y, zero(y)), Duplicated(x, dx))
    @test dx == 2 .* x

    # The augmented forward pass is timed in the usual sections and the reverse pass in
    # sections "label (reverse)", which nest like the forward ones
    to = timer()
    @test to["outer"].ncalls == 1
    @test to["outer"]["inner"].ncalls == 3
    @test to["outer (reverse)"].ncalls == 1
    @test to["outer (reverse)"]["inner (reverse)"].ncalls == 3

    # A section with no differentiable code in it
    function inactive_timed(x, n)
        s = @trixi_timeit timer() "inactive" sum(1:n)
        return x^2 + s
    end
    TrixiBase.TimerOutputs.reset_timer!(timer())
    @test autodiff(Reverse, inactive_timed, Active, Active(3.0), Const(3))[1][1] == 6.0
    @test timer()["inactive"].ncalls == 1
    @test timer()["inactive (reverse)"].ncalls == 1

    # Batch mode
    TrixiBase.TimerOutputs.reset_timer!(timer())
    dxs = (zero(x), zero(x))
    autodiff(Reverse, inner_timed!, Const, BatchDuplicated(y, (ones(3), 2 .* ones(3))),
             BatchDuplicated(x, dxs))
    @test dxs == (2 .* x, 4 .* x)
    @test timer()["inner"].ncalls == 1
    @test timer()["inner (reverse)"].ncalls == 1
end
