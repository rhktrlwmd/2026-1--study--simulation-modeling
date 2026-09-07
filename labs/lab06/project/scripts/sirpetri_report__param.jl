# # Сводка дополнительных экспериментов
#
# Сценарий читает подготовленные CSV и объединяет результаты, не выполняя
# моделирование. Ограниченная сетка честно отмечена как разведочная.

ENV["GKSwstype"] = "100"
using CSV, DataFrames, Plots
include(joinpath(dirname(Base.active_project()), "src", "StudyIO.jl"))
using .StudyIO

group = "sirpetri-param-report"
summary = CSV.read(data_dir("sirpetri-initial-study", "ssa_summary.csv"), DataFrame)
reference = CSV.read(data_dir("sirpetri-initial-study", "deterministic_reference.csv"), DataFrame)
grid = CSV.read(data_dir("sirpetri-beta-gamma", "beta-gamma-grid.csv"), DataFrame)
regimes = CSV.read(data_dir("sirpetri-regimes", "regime_manifest.csv"), DataFrame)

joined = innerjoin(summary, reference; on=:initial_I)
joined.bias_to_ode = joined.mean_peak .- joined.refined_peak
save_csv(group, "initial-condition-comparison.csv", joined)
save_csv(group, "scope.csv", DataFrame(
    item=["SSA repeats", "β×γ combinations", "regimes"],
    value=[sum(fill(12, nrow(summary))), nrow(grid), nrow(regimes)],
    status=["complete", "exploratory", "complete"]))

p1 = bar(string.(joined.initial_I), joined.bias_to_ode; label=false,
    xlabel="I(0)", ylabel="Средний SSA-пик − ODE-пик", title="Стохастическое отклонение")
p2 = scatter(grid.initial_growth, grid.peak_I; group=grid.gamma,
    xlabel="βS₀−γ", ylabel="Пик I", title="Начальный темп и максимум", legend=:bottomright)
save_plot(group, "parameter-report.png", plot(p1, p2; layout=(1, 2), size=(1100, 480)))
println("Параметрическая сводка собрана из CSV; разведочная сетка: 12 точек.")
