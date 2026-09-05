using Agents
using CairoMakie
using CSV
using DataFrames
using DrWatson
using Statistics

include(joinpath(@__DIR__, "daisyworld.jl"))
using .Daisyworld

set_theme!(Theme(font="DejaVu Sans", fontsize=16))

scenario_data(name, file) = (mkpath(datadir(name)); datadir(name, file))
scenario_plot(name, file) = (mkpath(plotsdir(name)); plotsdir(name, file))
report_figure(file) = (
    mkpath(projectdir("..", "image", "results"));
    projectdir("..", "image", "results", file)
)

function save_figure(fig, scenario, filename; report_name=nothing)
    save(scenario_plot(scenario, filename), fig)
    isnothing(report_name) || save(report_figure(report_name), fig)
    return fig
end

function snapshot_figure(model; title="Пространственное состояние Daisyworld")
    fig = Figure(size=(880, 710))
    ax = Axis(fig[1, 1], title="$title, t=$(model.tick)", xlabel="x", ylabel="y", aspect=1)
    heat = heatmap!(ax, model.temperature; colormap=:thermal, colorrange=(-20, 60))
    for (breed, colour, stroke) in ((:black, :black, :white), (:white, :white, :black))
        points = [Point2f(a.pos...) for a in allagents(model) if a.breed == breed]
        isempty(points) || scatter!(ax, points; color=colour, markersize=8,
                                    strokecolor=stroke, strokewidth=0.5)
    end
    Colorbar(fig[1, 2], heat; label="Температура, °C")
    return fig
end

function count_figure(frame; title="Динамика численности маргариток")
    fig = Figure(size=(1000, 560))
    ax = Axis(fig[1, 1], title=title, xlabel="Модельный шаг", ylabel="Число растений")
    lines!(ax, frame.time, frame.black; color=:black, linewidth=2, label="Чёрные")
    lines!(ax, frame.time, frame.white; color=:orange, linewidth=2, label="Белые")
    axislegend(ax; position=:rt)
    return fig
end

function dynamics_figure(frame; title="Обратная связь живой и неживой среды")
    fig = Figure(size=(1000, 960))
    ax1 = Axis(fig[1, 1], title=title, ylabel="Число растений")
    ax2 = Axis(fig[2, 1], ylabel="Температура, °C")
    ax3 = Axis(fig[3, 1], ylabel="Светимость")
    ax4 = Axis(fig[4, 1], ylabel="Альбедо", xlabel="Модельный шаг")
    lines!(ax1, frame.time, frame.black; color=:black, label="Чёрные")
    lines!(ax1, frame.time, frame.white; color=:orange, label="Белые")
    axislegend(ax1; position=:rt)
    lines!(ax2, frame.time, frame.temperature; color=:firebrick)
    lines!(ax3, frame.time, frame.luminosity; color=:royalblue)
    lines!(ax4, frame.time, frame.albedo; color=:darkgreen)
    linkxaxes!(ax1, ax2, ax3, ax4)
    hidexdecorations!(ax1; grid=false)
    hidexdecorations!(ax2; grid=false)
    hidexdecorations!(ax3; grid=false)
    return fig
end

parameter_sets() = dict_list(Dict(
    :griddims=>(30, 30), :max_age=>[25, 40],
    :init_white=>[0.2, 0.8], :init_black=>0.2,
    :albedo_white=>0.75, :albedo_black=>0.25,
    :surface_albedo=>0.4, :solar_change=>0.005,
    :solar_luminosity=>1.0, :scenario=>:default, :seed=>165,
))

function history_frame(model, steps)
    return DataFrame(collect_history(model, steps))
end

function save_history(frame, scenario; filename="trajectory.csv")
    CSV.write(scenario_data(scenario, filename), frame)
    return frame
end

function extinction_time(frame)
    index = findfirst(==(0), frame.total)
    return isnothing(index) ? missing : frame.time[index]
end
