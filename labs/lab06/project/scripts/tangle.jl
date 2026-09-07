using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using Literate

execute = "--execute" in ARGS
sources = filter(arg -> !startswith(arg, "--"), ARGS)
isempty(sources) && (sources = sort(filter(name -> startswith(name, "sirpetri_") && endswith(name, ".jl"), readdir(@__DIR__))))

function report_fragment(source, output)
    code = read(source, String)
    title = replace(first(filter(line -> startswith(line, "# # "), split(code, '\n'))), "# # " => "")
    prose = filter(line -> startswith(line, "#") && !startswith(line, "# #"), split(code, '\n'))
    open(output, "w") do io
        println(io, "## ", title)
        println(io, "\n", join(replace.(prose, r"^# ?" => ""), "\n"))
        println(io, "\n```julia\n", code, "\n```")
    end
end

for item in sources
    source = isabspath(item) ? item : joinpath(@__DIR__, basename(item))
    name = splitext(basename(source))[1]
    clean_dir = joinpath(@__DIR__, name)
    notebook_dir = joinpath(@__DIR__, "..", "notebooks", name)
    markdown_dir = joinpath(@__DIR__, "..", "markdown", name)
    foreach(mkpath, [clean_dir, notebook_dir, markdown_dir])
    Literate.script(source, clean_dir; documenter=false)
    Literate.notebook(source, notebook_dir; execute=execute, documenter=false)
    Literate.markdown(source, markdown_dir; documenter=false)
    qmd = joinpath(markdown_dir, "$(name).md")
    isfile(qmd) && mv(qmd, joinpath(markdown_dir, "$(name).qmd"); force=true)
    report_fragment(source, joinpath(markdown_dir, "$(name)-report.qmd"))
end
println("Generated $(length(sources)) literary scenarios; execute=$(execute)")
