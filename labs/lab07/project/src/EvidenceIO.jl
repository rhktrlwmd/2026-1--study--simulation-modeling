module EvidenceIO

using CSV, DataFrames, Plots

export data_path, plot_path, store_table, store_figure
export queue_state_plot, queue_comparison_plot, reserve_trace_plot

root() = normpath(joinpath(@__DIR__, ".."))
data_path(parts...) = joinpath(root(), "data", parts...)
plot_path(parts...) = joinpath(root(), "plots", parts...)

function store_table(group, filename, table)
    path = data_path(group, filename)
    mkpath(dirname(path)); CSV.write(path, table); path
end

function store_figure(group, filename, figure)
    path = plot_path(group, filename)
    mkpath(dirname(path)); savefig(figure, path); path
end

function queue_state_plot(states; title="Состояние очереди M/M/c")
    top = plot(states.time, states.waiting; seriestype=:steppost, label="в очереди",
        color="#1f5aa6", linewidth=2, ylabel="клиенты", title)
    plot!(top, states.time, states.busy; seriestype=:steppost, label="занятые каналы",
        color="#d1495b", linewidth=2)
    bottom = scatter(states.time, states.client; group=states.kind, markersize=3,
        xlabel="модельное время", ylabel="номер клиента", legend=:outerright)
    plot(top, bottom; layout=(2,1), size=(1050,650))
end

function queue_comparison_plot(table)
    p = plot(; xlabel="число каналов c", ylabel="среднее ожидание Wq",
        title="Имитация и формула Эрланга C")
    palette = ["#1f5aa6", "#c74732", "#27864b"]
    for (index, rate) in enumerate(sort(unique(table.lambda)))
        rows = table[table.lambda .== rate, :]
        plot!(p, rows.c, rows.sim_Wq; marker=:circle, linewidth=2,
            color=palette[index], label="имитация λ=$(rate)")
        plot!(p, rows.c, rows.theory_Wq; linestyle=:dash, linewidth=2,
            color=palette[index], label="Эрланг C λ=$(rate)")
    end
    p
end

function reserve_trace_plot(trace, required)
    p1 = plot(trace.time, trace.working; seriestype=:steppost, label="работают",
        ylabel="машины", color="#1f5aa6", linewidth=2, ylim=(required-1, required+1))
    plot!(p1, trace.time, trace.spares; seriestype=:steppost, label="резерв",
        color="#27864b", linewidth=2)
    p2 = plot(trace.time, trace.busy_repairers; seriestype=:steppost,
        label="занято ремонтников", ylabel="ремонт", color="#c74732", linewidth=2)
    plot!(p2, trace.time, trace.repair_queue; seriestype=:steppost,
        label="очередь ремонта", color="#7b4ab5", linewidth=2)
    plot(p1, p2; layout=(2,1), xlabel="время", size=(1050,650),
        plot_title="Система Росса до отказа")
end

end
