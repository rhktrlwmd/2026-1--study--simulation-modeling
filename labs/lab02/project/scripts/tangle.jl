#!/usr/bin/env julia

using DrWatson
@quickactivate "BasicModelsLab"
using Literate

function without_execution_markers(content)
    replace(content, r"(?m)^#nb\s?" => "")
end

function generate_formats(source::AbstractString)
    isfile(source) || error("Source file not found: $(source)")
    name = splitext(basename(source))[1]
    clean_dir = scriptsdir(name)
    quarto_dir = projectdir("markdown", name)
    notebook_dir = projectdir("notebooks", name)
    mkpath.([clean_dir, quarto_dir, notebook_dir])
    Literate.script(source, clean_dir; name, credit=false)
    Literate.notebook(source, notebook_dir; name, execute=false, credit=false)
    Literate.markdown(source, quarto_dir; name,
                      flavor=Literate.QuartoFlavor(), credit=false,
                      preprocess=without_execution_markers)
    println("Generated Julia, notebook, and Quarto formats for $(name)")
end

isempty(ARGS) && error("Usage: julia --project=. scripts/tangle.jl <source.jl> ...")
foreach(generate_formats, ARGS)
