ENV["GKSwstype"] = "100"
using DataFrames, Plots, Statistics
include(joinpath(dirname(Base.active_project()), "src", "SIRPetri.jl"))
include(joinpath(dirname(Base.active_project()), "src", "StudyIO.jl"))
using .SIRPetri, .StudyIO

group = "sirpetri-initial-study"
rows = NamedTuple[]
det_rows = NamedTuple[]
for initial_i in (5, 10, 25)
    config = SIRConfig(susceptible=1000-initial_i, infected=initial_i)
    exact = refined_peak(config)
    push!(det_rows, (initial_I=initial_i, refined_peak=exact.infected, peak_time=exact.time))
    for replicate in 1:12
        path = stochastic_trajectory(config; seed=6000 + 100initial_i + replicate)
        metrics = trajectory_metrics(path)
        push!(rows, (initial_I=initial_i, replicate=replicate,
                     peak_I=metrics.peak_I, peak_time=metrics.peak_time,
                     final_R=metrics.final_R))
    end
end
replicates = DataFrame(rows)
deterministic = DataFrame(det_rows)
summary = combine(groupby(replicates, :initial_I),
    :peak_I => mean => :mean_peak,
    :peak_I => std => :sd_peak,
    :peak_time => mean => :mean_peak_time,
    :final_R => mean => :mean_final_R)
save_csv(group, "ssa_replicates.csv", replicates)
save_csv(group, "ssa_summary.csv", summary)
save_csv(group, "deterministic_reference.csv", deterministic)

p1 = scatter(replicates.initial_I, replicates.peak_I; group=replicates.initial_I,
    label=false, xlabel="I(0)", ylabel="Пик I", title="12 повторов SSA")
p2 = plot(deterministic.initial_I, deterministic.peak_time; marker=:diamond,
    label=false, xlabel="I(0)", ylabel="Время пика", title="Уточнённое ODE-решение")
save_plot(group, "initial-infection-study.png", plot(p1, p2; layout=(1, 2), size=(1100, 480)))
println("Реальных SSA-прогонов: $(nrow(replicates))")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
