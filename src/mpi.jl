# These are just dummy functions. We only implement real
# versions if MPI.jl is loaded to avoid letting TrixiBase.jl
# depend explicitly on MPI.jl.
# We dispatch on the return type of get_extension to provide a fallback

mpi_isparallel() = mpi_isparallel_internal(Base.get_extension(TrixiBase, :TrixiBaseMPIExt))
mpi_isparallel_internal(ext::Nothing) = false

mpi_isroot() = mpi_isroot_internal(Base.get_extension(TrixiBase, :TrixiBaseMPIExt))
mpi_isroot_internal(ext::Nothing) = true
