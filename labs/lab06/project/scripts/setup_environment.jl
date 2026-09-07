using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()
using IJulia
IJulia.installkernel("Julia lab06", "--project=$(normpath(joinpath(@__DIR__, "..")))")
Pkg.status()
