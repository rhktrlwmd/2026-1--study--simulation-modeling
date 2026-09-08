module StudyTools
using ..ContactProcesses
using CSV, DataFrames, Plots, Statistics
export save_run, run_metrics, draw_states, imagefile, save_table, ensemble
const ROOT = normpath(joinpath(@__DIR__,".."))
const IMAGES = normpath(joinpath(ROOT,"..","image","results"))
imagefile(name) = (mkpath(IMAGES); joinpath(IMAGES,name*".png"))

function save_table(name,df)
    directory = joinpath(ROOT,"data","analysis")
    mkpath(directory)
    CSV.write(joinpath(directory,name*".csv"),df)
end

function run_metrics(m)
    d = table(m)
    peak = argmax(d.I)
    (; peak=maximum(d.I),time_peak=d.t[peak],R_T=last(d.R),
        cases=last(d.cases),I_T=last(d.I),vaccinated=last(d.V),
        population=length(m.living),balance=check_balance(m))
end

function save_run(m; label="sir",seed=1234,T=40.0)
    c = m.config
    name = "$(label)_N$(m.initial)_b$(c.beta)_c$(c.contact)" *
        "_g$(c.recovery)_seed$(seed)_T$(T).csv"
    folder = joinpath(ROOT,"data","sims")
    mkpath(folder)
    CSV.write(joinpath(folder,name),table(m))
end

function draw_states(m,name; title="SIR")
    d = table(m)
    columns = isfinite(m.config.latent) ? [:S,:E,:I,:R] : [:S,:I,:R]
    p = plot(d.t,Matrix(d[:,columns]),label=permutedims(string.(columns)),
        xlabel="Time",ylabel="People",title=title,linewidth=2,
        seriestype=:steppost,size=(1050,620))
    savefig(p,imagefile(name))
    p
end

"""Return separate per-run metrics and the mean path, never conflate peaks."""
function ensemble(config; repeats=20,T=80.0,u0=(990,10,0))
    rows = NamedTuple[]
    grid = collect(0.0:0.25:T)
    paths = Matrix{Float64}(undef,length(grid),repeats)
    for k in 1:repeats
        m = simulate(;config,T,u0,seed=1233+k)
        push!(rows,(;replicate=k,run_metrics(m)...))
        paths[:,k] = sample_path(table(m),grid)
    end
    (metrics=DataFrame(rows),path=DataFrame(t=grid,
        mean_I=vec(mean(paths;dims=2)),sd_I=vec(std(paths;dims=2))))
end
end
