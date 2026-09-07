using DrWatson
@quickactivate "EventSystemsStudy"
ENV["GKSwstype"] = "100"
include(srcdir("EventSystemsStudy.jl"))
using .EventSystemsStudy.QueueFlow, .EventSystemsStudy.EvidenceIO
using DataFrames, Plots

result = run_queue(clients=10, channels=2, arrival_rate=0.9,
    service_rate=0.5, seed=123)
observed = queue_indicators(result)
theory = erlang_c_indicators(0.9, 0.5, 2)
store_table("queue_baseline", "clients.csv", result.ledger)
store_table("queue_baseline", "states.csv", result.states)
store_table("queue_baseline", "comparison.csv", DataFrame([
    (source="simulation", Wq=observed.Wq, W=observed.W, Lq=observed.Lq,
        L=observed.L, p_wait=observed.p_wait),
    (source="Erlang C", Wq=theory.Wq, W=theory.W, Lq=theory.Lq,
        L=theory.L, p_wait=theory.p_wait)]))

println(first(result.ledger, 10))
println("completion = ", round(result.completion, digits=4))
println("rho = ", theory.rho, ", theoretical Wq = ", round(theory.Wq, digits=4))
figure = queue_state_plot(result.states; title="M/M/2: десять клиентов")
store_figure("queue_baseline", "queue_timeline.png", figure)
figure

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
