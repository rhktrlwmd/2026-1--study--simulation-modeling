using Pkg
Pkg.activate(joinpath(@__DIR__,".."))
using Literate
root = dirname(@__DIR__)
execute = "--execute" in ARGS
names = ["sir_des","sir_des__param","sir_duration","sir_benchmark",
    "sir_csv_report","sir_demography","sir_vaccination","sir_seir",
    "sir_compare_ode"]
for name in names
    source = joinpath(@__DIR__,name*".jl")
    clean = joinpath(root,"generated",name)
    nb = joinpath(root,"notebooks",name)
    docs = joinpath(root,"markdown",name)
    Literate.script(source,clean;documenter=false)
    Literate.notebook(source,nb;execute,documenter=false)
    Literate.markdown(source,docs;flavor=Literate.QuartoFlavor())
    qmd = joinpath(docs,name*".qmd")
    # The full generated prose and code are included without rerunning in Word.
    text = replace(read(qmd,String),"```{julia}"=>"```julia")
    text = replace(text,r"(?m)^# [^\n]+"=>"### Литературный исходник")
    write(joinpath(docs,name*"-report.qmd"),text)
end
