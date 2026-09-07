using DrWatson
@quickactivate "EventSystemsStudy"
ENV["GKSwstype"] = "100"
include(srcdir("EventSystemsStudy.jl"))
using .EventSystemsStudy.RepairReserve, .EventSystemsStudy.EvidenceIO
using DataFrames, Statistics, Plots

runs = NamedTuple[]
traces = DataFrame[]
for run in 1:5
    result = run_reserve(required=10, spares=3, repairers=1,
        failure_mean=100.0, repair_mean=1.0, seed=149+run)
    push!(runs, merge((run=run,), result.summary))
    push!(traces, result.trace)
end
run_table = DataFrame(runs)
first_trace = first(traces)
theory = reserve_theory(required=10, spares=3, repairers=1,
    failure_mean=100.0, repair_mean=1.0)
comparison = DataFrame(observed_mean=[mean(run_table.failure_time)],
    analytical_mean=[theory.mean_time], observed_utilization=[mean(run_table.utilization)],
    analytical_utilization=[theory.utilization], observed_queue=[mean(run_table.mean_queue)],
    analytical_queue=[theory.mean_queue])
store_table("reserve_baseline", "five_runs.csv", run_table)
store_table("reserve_baseline", "first_trace.csv", first_trace)
store_table("reserve_baseline", "analytical_comparison.csv", comparison)
store_table("reserve_baseline", "state_occupation.csv", theory.occupation)

println(run_table[:, [:run, :failure_time, :utilization, :mean_queue, :transitions]])
println(comparison)
figure = reserve_trace_plot(first_trace, 10)
store_figure("reserve_baseline", "failure_path.png", figure)
figure

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
