using Pkg

project = normpath(joinpath(@__DIR__, ".."))
Pkg.activate(project)
Pkg.instantiate()
Pkg.precompile()

using IJulia
IJulia.installkernel("Julia lab05", "--project=$(project)";
                     specname="julia-lab05")

println("Активный проект: $(Base.active_project())")
Pkg.status()
