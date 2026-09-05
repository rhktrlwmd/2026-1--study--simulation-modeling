using Pkg

Pkg.instantiate()
Pkg.precompile()

using IJulia
project_path = dirname(Base.active_project())
IJulia.installkernel(
    "Julia Lab03 1.11",
    "--project=$(project_path)";
    env=Dict("JULIA_DEPOT_PATH"=>join(DEPOT_PATH, ':')),
)
