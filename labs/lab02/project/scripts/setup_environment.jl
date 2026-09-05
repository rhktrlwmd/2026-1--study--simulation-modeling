#!/usr/bin/env julia

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()
Pkg.precompile()

using IJulia
ENV["JUPYTER_DATA_DIR"] = joinpath(first(DEPOT_PATH), "jupyter")
IJulia.installkernel("Julia lab02", "--project=$(abspath(joinpath(@__DIR__, "..")))")
println("Julia environment and kernel julia-lab02-1.11 are ready")
