# These are just dummy functions. We only implement real
# versions if MPI.jl is loaded to avoid letting TrixiBase.jl
# depend explicitly on MPI.jl.

# There is an order problem here, with naive caching:
# TrixiBase.mpi_isparallel() -> false
# using MPI
# TrixiBase.mpi_isparallel() -> false
# Since we cached the check for MPI being loaded.
# We use an internal Julia feature "package_callbacks" to reset the cache when MPI is loaded.

# XXX: This should be replaced with OncePerProcess or similar in 1.12
const __MPI__AVAILABLE__ = Ref{Union{Nothing, Bool}}(nothing)

function reset_mpi_available(mod::Base.PkgId)
    if mod == Base.PkgId(Base.UUID("da04e1cc-30fd-572f-bb4f-1f8673147195"), "MPI")
        __MPI__AVAILABLE__[] = nothing
    end
    return nothing
end
function __init__()
    # Future-proof if Julia Base ever removes this code
    if isdefined(Base, :package_callbacks)
        push!(Base.package_callbacks, reset_mpi_available)
    end
end

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
