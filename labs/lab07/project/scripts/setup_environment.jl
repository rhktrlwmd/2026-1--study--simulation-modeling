using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()
using IJulia
IJulia.installkernel("Julia lab07", "--project=$(dirname(@__DIR__))")
Pkg.status()
