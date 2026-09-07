using Test, DataFrames, Statistics
include(joinpath(@__DIR__, "..", "src", "EventSystemsStudy.jl"))
using .EventSystemsStudy.QueueFlow
using .EventSystemsStudy.RepairReserve

@testset "M/M/c simulation and Erlang C" begin
    a = run_queue(clients=1000, channels=2, arrival_rate=0.7, service_rate=0.5, seed=17)
    b = run_queue(clients=1000, channels=2, arrival_rate=0.7, service_rate=0.5, seed=17)
    @test a.ledger == b.ledger
    @test all(a.ledger.departure .>= a.ledger.service_start .>= a.ledger.arrival)
    @test maximum(a.states.busy) <= 2
    exact = erlang_c_indicators(0.9, 0.5, 2)
    @test exact.rho ≈ 0.9
    @test exact.Wq ≈ 8.526315789473687
    @test exact.Lq ≈ 7.673684210526319
    @test_throws ArgumentError run_queue(clients=1)
end

@testset "Ross CTMC and rewards" begin
    base = run_reserve(seed=150)
    again = run_reserve(seed=150)
    @test base.summary == again.summary
    @test base.summary.failure_time > 0
    @test last(base.trace.transition) == "system_failure"
    @test last(base.trace.working) == 9
    @test all(0 .<= base.trace.busy_repairers .<= 1)
    exact = reserve_theory()
    @test exact.mean_time ≈ 12340 atol=1e-8
    @test exact.residual < 1e-9
    @test reserve_theory(spares=0).mean_time ≈ 10.0
    @test reserve_theory(repairers=2).mean_time > exact.mean_time
    @test_throws ArgumentError run_reserve(required=0)
end
