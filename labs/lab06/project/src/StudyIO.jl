module StudyIO

using CSV, DataFrames, Plots

export project_root, data_dir, plot_dir, ensure_outputs, save_csv, save_plot
export sir_plot, petri_diagram, animation_plot

project_root() = normpath(joinpath(@__DIR__, ".."))
data_dir(parts...) = joinpath(project_root(), "data", parts...)
plot_dir(parts...) = joinpath(project_root(), "plots", parts...)

function ensure_outputs(group)
    mkpath(data_dir(group))
    mkpath(plot_dir(group))
end

function save_csv(group, name, table)
    ensure_outputs(group)
    path = data_dir(group, name)
    CSV.write(path, table)
    path
end

function save_plot(group, name, figure)
    ensure_outputs(group)
    path = plot_dir(group, name)
    savefig(figure, path)
    path
end

function sir_plot(data; title="SIR dynamics", stepped=false)
    plot(data.time, data.S; label="S", color="#2468a2", linewidth=2.5,
         xlabel="Время", ylabel="Численность", title=title,
         seriestype=stepped ? :steppost : :path, legend=:right)
    plot!(data.time, data.I; label="I", color="#cb3c33", linewidth=2.5,
          seriestype=stepped ? :steppost : :path)
    plot!(data.time, data.R; label="R", color="#27864b", linewidth=2.5,
          seriestype=stepped ? :steppost : :path)
end

function petri_diagram()
    plot(; xlim=(0, 10), ylim=(0, 4), axis=false, legend=false,
         size=(1100, 430), title="Сеть Петри модели SIR")
    scatter!([1.2, 5.0, 8.8], [2.0, 2.0, 2.0]; markersize=42,
             markercolor="#eaf1fb", markerstrokecolor="#174a7e")
    annotate!([(1.2, 2.0, text("S", 20, :black)),
               (5.0, 2.0, text("I", 20, :black)),
               (8.8, 2.0, text("R", 20, :black))])
    vline!([3.1, 6.9]; color="#c43b3b", linewidth=8, label=false)
    annotate!([(3.1, 3.25, text("infection", 13)), (6.9, 3.25, text("recovery", 13))])
    for (x1, x2, y) in [(1.6, 2.85, 2.25), (4.55, 3.35, 1.55),
                         (3.35, 4.55, 2.25), (5.45, 6.65, 2.25), (7.15, 8.35, 2.25)]
        plot!([x1, x2], [y, y]; arrow=true, color="#263238", linewidth=2)
    end
    current()
end

function animation_plot(data, upto; title="SIR: динамика маркировки")
    segment = data[1:upto, :]
    left = sir_plot(segment; title=title)
    xlims!(left, 0, maximum(data.time)); ylims!(left, 0, 1000)
    right = bar(["S", "I", "R"], [data.S[upto], data.I[upto], data.R[upto]];
                color=["#2468a2", "#cb3c33", "#27864b"], legend=false,
                ylim=(0, 1000), title="t = $(round(data.time[upto], digits=1))")
    plot(left, right; layout=(1, 2), size=(1200, 520))
end

end
