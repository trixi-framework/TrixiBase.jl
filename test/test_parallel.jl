include("test_util.jl")

import KernelAbstractions: CPU
using Polyester

@testset verbose=true "@par macro" begin
    @par TrixiBase.SerialBackend() for i in 1:10
        @test i in 1:10
    end

    @par TrixiBase.ThreadsDynamicBackend() for i in 1:10
        @test i in 1:10
    end

    @par TrixiBase.ThreadsStaticBackend() for i in 1:10
        @test i in 1:10
    end

    @par TrixiBase.PolyesterBackend() for i in 1:10
        @test i in 1:10
    end

    @par CPU() for i in 1:10
        @test i in 1:10
    end
end
