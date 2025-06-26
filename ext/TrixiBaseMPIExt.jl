# Package extension for adding MPI-based features to TrixiBase.jl
module TrixiBaseMPIExt

import TrixiBase

# These are really working functions - assuming the same
# communication pattern etc. used in Trixi.jl.
function TrixiBase.mpi_isparallel_internal(::Module)
    if MPI.Initialized()
        return MPI.Comm_size(MPI.COMM_WORLD) > 1
    else
        return false
    end
end

function TrixiBase.mpi_isroot_internal(::Module)
    if MPI.Initialized()
        return MPI.Comm_rank(MPI.COMM_WORLD) == 0
    else
        return true
    end
end
end
