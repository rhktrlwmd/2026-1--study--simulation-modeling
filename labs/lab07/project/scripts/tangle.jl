using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using Literate

execute = "--execute" in ARGS
defaults = ["queue_baseline.jl", "queue_load_study.jl",
    "reserve_baseline.jl", "repair_capacity_study.jl"]
sources = filter(item -> !startswith(item, "--"), ARGS)
isempty(sources) && (sources = defaults)

function report_fragment(source, output)
    code = read(source, String)
    lines = split(code, '\n')
    title_line = first(filter(line -> startswith(line, "# # "), lines))
    prose = filter(line -> startswith(line, "#") && !startswith(line, "# #"), lines)
    open(output, "w") do io
        println(io, "## ", replace(title_line, "# # "=>""))
        println(io, "\n", join(replace.(prose, r"^# ?"=>""), "\n"))
        println(io, "\n```julia\n", code, "\n```")
    end
end

for item in sources
    source = isabspath(item) ? item : joinpath(@__DIR__, basename(item))
    name = splitext(basename(source))[1]
    clean = joinpath(@__DIR__, name)
    notebook = joinpath(@__DIR__, "..", "notebooks", name)
    markdown = joinpath(@__DIR__, "..", "markdown", name)
    foreach(mkpath, [clean, notebook, markdown])
    Literate.script(source, clean; documenter=false)
    Literate.notebook(source, notebook; execute, documenter=false)
    Literate.markdown(source, markdown; documenter=false)
    md = joinpath(markdown, "$(name).md")
    isfile(md) && mv(md, joinpath(markdown, "$(name).qmd"); force=true)
    report_fragment(source, joinpath(markdown, "$(name)-report.qmd"))
end
println("Generated $(length(sources)) scenarios; execute=$execute")
