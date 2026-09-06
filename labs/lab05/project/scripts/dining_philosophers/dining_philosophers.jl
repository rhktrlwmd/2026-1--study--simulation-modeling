using DrWatson
@quickactivate "PetriDiningLab"

ENV["GKSwstype"] = "100"
using CairoMakie
using CSV
using DataFrames
using Random

include(srcdir("DiningPhilosophers.jl"))
using .DiningPhilosophers

const PHILOSOPHERS = 5
const HORIZON = 50.0
const BASE_RATES = vcat(fill(2.4, PHILOSOPHERS),
                        fill(0.8, PHILOSOPHERS),
                        fill(1.1, PHILOSOPHERS))

mkpath(datadir())
mkpath(plotsdir())

classic_net, classic_initial = build_classical_network(PHILOSOPHERS)
arbiter_net, arbiter_initial = build_arbiter_network(PHILOSOPHERS)

classic = simulate_stochastic(classic_net, classic_initial, HORIZON;
    rates=BASE_RATES, rng=MersenneTwister(20260501))
arbiter = simulate_stochastic(arbiter_net, arbiter_initial, HORIZON;
    rates=BASE_RATES, rng=MersenneTwister(20260502))

CSV.write(datadir("dining_classic.csv"), classic.trajectory)
CSV.write(datadir("dining_arbiter.csv"), arbiter.trajectory)
CSV.write(datadir("dining_classic_events.csv"), classic.events)
CSV.write(datadir("dining_arbiter_events.csv"), arbiter.events)

classic_ode = simulate_ode(classic_net, classic_initial, HORIZON;
    rates=BASE_RATES, saveat=0.1)
arbiter_ode = simulate_ode(arbiter_net, arbiter_initial, HORIZON;
    rates=BASE_RATES, saveat=0.1)
CSV.write(datadir("dining_classic_ode.csv"), classic_ode)
CSV.write(datadir("dining_arbiter_ode.csv"), arbiter_ode)

summary = DataFrame([
    event_summary(classic, HORIZON, "Классическая сеть"),
    event_summary(arbiter, HORIZON, "Сеть с арбитром"),
])
CSV.write(datadir("dining_summary.csv"), summary)

println("=== Стохастические сети Петри: N=$(PHILOSOPHERS), T=$(HORIZON) ===")
show(summary; allrows=true, allcols=true)
println()
println("Deadlock обнаружен (классическая сеть): $(classic.deadlock)")
println("Deadlock обнаружен (сеть с арбитром): $(arbiter.deadlock)")

classic_figure = plot_marking_evolution(classic.trajectory, PHILOSOPHERS;
    title="Классическая сеть: развитие маркировки")
save(plotsdir("classic_simulation.png"), classic_figure, px_per_unit=1.5)
classic_figure

arbiter_figure = plot_marking_evolution(arbiter.trajectory, PHILOSOPHERS;
    title="Сеть с арбитром: развитие маркировки")
save(plotsdir("arbiter_simulation.png"), arbiter_figure, px_per_unit=1.5)
arbiter_figure
