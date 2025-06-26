# These are just dummy functions. We only implement real
# versions if MPI.jl is loaded to avoid letting TrixiBase.jl
# depend explicitly on MPI.jl.
mpi_isparallel(x) = false

# Dispatch on the return type of get_extension
mpi_isroot() = mpi_isroot_internal(Base.get_extension(TrixiBase, :TrixiBaseMPIExt))
mpi_isroot_internal(ext::Nothing) = true
