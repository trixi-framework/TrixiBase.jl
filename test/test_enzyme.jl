using Enzyme: Enzyme, Active, Duplicated, Reverse, autodiff

@testset verbose=true "`@trixi_timeit` with Enzyme.jl" begin
    function inner_timed!(y, x)
        @trixi_timeit timer() "inner" begin
            y .= x .^ 2
        end
        return nothing
    end
    function outer_timed(y, x)
        @trixi_timeit timer() "outer" begin
            inner_timed!(y, x)
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
    @test to["outer"]["inner"].ncalls == 1
    @test to["outer (reverse)"].ncalls == 1
    @test to["outer (reverse)"]["inner (reverse)"].ncalls == 1
    @test isempty(Base.get_extension(TrixiBase, :TrixiBaseEnzymeCoreExt).REVERSE_STATES)
end
