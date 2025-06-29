# Package extension for adding MPI-based features to TrixiBase.jl
module TrixiBaseMPIExt

using MPI
import TrixiBase

function __init__()
    TrixiBase.__MPI__AVAILABLE__[] = true
end

# These are really working functions - assuming the same
# communication pattern etc. used in Trixi.jl.
function TrixiBase.mpi_isparallel_internal()
    if MPI.Initialized()
        return MPI.Comm_size(MPI.COMM_WORLD) > 1
    else
        return false
    end
end

function TrixiBase.mpi_isroot_internal()
    if MPI.Initialized()
        return MPI.Comm_rank(MPI.COMM_WORLD) == 0
    else
        return true
    end
end
end
