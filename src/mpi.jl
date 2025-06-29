# These are just dummy functions. We only implement real
# versions if MPI.jl is loaded to avoid letting TrixiBase.jl
# depend explicitly on MPI.jl.

# XXX: There is an order problem here:
# TrixiBase.mpi_isparallel() -> false
# using MPI
# TrixiBase.mpi_isparallel() -> false
# Since we cached the check for MPI being loaded.

# XXX: This should be replaced with OncePerProcess or similar in 1.12
const __MPI__AVAILABLE__ = Ref{Union{Nothing, Bool}}(nothing)
function __mpi__available()
    val = __MPI__AVAILABLE__[]
    if val === nothing
        val = Base.get_extension(TrixiBase, :TrixiBaseMPIExt) !== nothing
        __MPI__AVAILABLE__[] = val
    end
    return val::Bool
end

function mpi_isparallel_internal end
function mpi_isroot_internal end

function mpi_isparallel()
    if __mpi__available()
        return mpi_isparallel_internal()
    else
        return false
    end
end

function mpi_isroot()
    if __mpi__available()
        return mpi_isroot_internal()
    else
        return true
    end
end
