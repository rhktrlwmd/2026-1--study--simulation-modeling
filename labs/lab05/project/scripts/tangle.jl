using DrWatson
@quickactivate "PetriDiningLab"
using Literate

execute_notebooks = "--execute" in ARGS
sources = filter(!=("--execute"), ARGS)

function build_derivatives(source::AbstractString)
    name = splitext(basename(source))[1]
    script_target = scriptsdir(name)
    notebook_target = projectdir("notebooks", name)
    markdown_target = projectdir("markdown", name)
    foreach(mkpath, (script_target, notebook_target, markdown_target))

    Literate.script(source, script_target; name=name, credit=false)
    Literate.notebook(source, notebook_target; name=name,
                      execute=execute_notebooks, credit=false)
    Literate.markdown(source, markdown_target; name=name,
                      flavor=Literate.QuartoFlavor(), credit=false)
    Literate.markdown(source, markdown_target;
        name=name * "-report", flavor=Literate.QuartoFlavor(), credit=false,
        postprocess=text -> replace(
            replace(text, "```{julia}" => "```julia"),
            r"^(#{1,4}) "m => heading -> "##" * heading,
        ))
end

foreach(build_derivatives, sources)
