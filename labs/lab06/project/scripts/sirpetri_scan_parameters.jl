# # Сканирование коэффициента заражения
#
# Обязательная сетка β=0.1:0.05:0.8 при γ=0.1. Для каждого значения сохраняем
# максимум на сетке 0.5 и уточнённый ранний пик непрерывного решения.

ENV["GKSwstype"] = "100"
using DataFrames, Plots
include(joinpath(dirname(Base.active_project()), "src", "SIRPetri.jl"))
include(joinpath(dirname(Base.active_project()), "src", "StudyIO.jl"))
using .SIRPetri, .StudyIO

group = "sirpetri-scan"
rows = NamedTuple[]
for beta in 0.1:0.05:0.8
    config = SIRConfig(beta=Float64(beta), gamma=0.1)
    coarse = deterministic_trajectory(config; saveat=0.5)
    precise = refined_peak(config)
    push!(rows, (beta=Float64(beta), gamma=0.1,
                 grid_peak=maximum(coarse.I), refined_peak=precise.infected,
                 peak_time=precise.time, analytical_peak=precise.analytical,
                 final_recovered=coarse.R[end]))
end
scan = DataFrame(rows)
save_csv(group, "beta_scan.csv", scan)

peak_plot = plot(scan.beta, scan.grid_peak; marker=:circle, label="сетка Δt=0.5",
    xlabel="β", ylabel="Максимум I", title="Пик эпидемии и точность сетки")
plot!(peak_plot, scan.beta, scan.refined_peak; marker=:diamond, label="уточнённый пик")
final_plot = plot(scan.beta, scan.final_recovered; marker=:circle, color="#27864b",
    label=false, xlabel="β", ylabel="R(100)", title="Итоговое число переболевших")
save_plot(group, "beta-scan.png", plot(peak_plot, final_plot; layout=(1, 2), size=(1200, 520)))

println("Обработано значений β: $(nrow(scan))")
println("Порог начала роста: β > γ/S₀ = $(0.1 / 990)")
println("На обязательной сетке минимальный β=0.1 уже значительно выше порога.")
