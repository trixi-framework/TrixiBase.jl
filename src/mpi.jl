# These are just dummy functions. We only implement real
# versions if MPI.jl is loaded to avoid letting TrixiBase.jl
# depend explicitly on MPI.jl.

# This will be true if TrixiBaseMPIExt is loaded
const __MPI__AVAILABLE__ = Ref{Bool}(false)

# These functions are defined in the TrixiBaseMPIExt extension
function mpi_isparallel_internal end
function mpi_isroot_internal end

function mpi_isparallel()
    if __MPI__AVAILABLE__[]
        return mpi_isparallel_internal()
    else
        return false
    end
end

function mpi_isroot()
    if __MPI__AVAILABLE__[]
        return mpi_isroot_internal()
    else
        return true
    end
end
