# Package extension for adding MPI-based features to TrixiBase.jl
module TrixiBaseMPIExt
__precompile__(false)

# Load package extension code on Julia v1.9 and newer
if isdefined(Base, :get_extension)
    using MPI: MPI
end
import TrixiBase

# This is a really working version - assuming the same
# communication pattern etc. used in Trixi.jl.
function TrixiBase.mpi_isparallel()
    if MPI.Initialized()
        return MPI.Comm_size(MPI.COMM_WORLD) > 1
    else
        return false
    end
end

end
