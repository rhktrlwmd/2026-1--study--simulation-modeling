using CairoMakie
using CSV
using DataFrames
using DrWatson
using Statistics

include(joinpath(@__DIR__, "sir_model.jl"))
using .SIRModel

set_theme!(Theme(font="DejaVu Sans", fontsize=16, linewidth=2))

scenario_data(name, file) = (mkpath(datadir(name)); datadir(name, file))
scenario_plot(name, file) = (mkpath(plotsdir(name)); plotsdir(name, file))
report_figure(file) = (mkpath(projectdir("..", "image", "results")); projectdir("..", "image", "results", file))

function save_figure(fig, scenario, filename; report_name=nothing)
    save(scenario_plot(scenario, filename), fig)
    isnothing(report_name) || save(report_figure(report_name), fig)
    return fig
end

function sir_figure(frame; title="Динамика агентной модели SIR")
    fig = Figure(size=(1040, 620))
    ax = Axis(fig[1, 1]; title=title, xlabel="День", ylabel="Число агентов")
    lines!(ax, frame.time, frame.susceptible; label="S — восприимчивые", color=:royalblue)
    lines!(ax, frame.time, frame.infected; label="I — инфицированные", color=:firebrick)
    lines!(ax, frame.time, frame.recovered; label="R — выздоровевшие", color=:seagreen)
    lines!(ax, frame.time, frame.living; label="Живые", color=:gray35, linestyle=:dash)
    axislegend(ax; position=:rc)
    return fig
end

function save_frame(frame, scenario, filename)
    CSV.write(scenario_data(scenario, filename), frame)
    return frame
end

function epidemic_metrics(frame, initial_population)
    peak, idx = findmax(frame.infected_fraction)
    return (
        peak_fraction=peak, peak_day=frame.time[idx],
        final_infected=last(frame.infected_fraction),
        final_recovered=last(frame.recovered) / initial_population,
        deaths=last(frame.deaths), attack_rate=(initial_population - last(frame.susceptible)) / initial_population,
    )
end

function summarize_groups(frame, key)
    return combine(groupby(frame, key),
        :peak_fraction => mean => :mean_peak_fraction,
        :peak_day => mean => :mean_peak_day,
        :deaths => mean => :mean_deaths,
        :attack_rate => mean => :mean_attack_rate,
    )
end
