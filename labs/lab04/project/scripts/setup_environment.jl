using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()
Pkg.precompile()
println("Среда AgentSIRLab готова: ", Base.active_project())
