using Test
using CSV
using DataFrames
using Random

include(joinpath(@__DIR__, "..", "src", "DiningPhilosophers.jl"))
using .DiningPhilosophers

@testset "Структура классической сети" begin
    net, initial = build_classical_network(5)
    @test size(net.input) == (20, 15)
    @test size(net.output) == (20, 15)
    @test sum(initial) == 10
    @test enabled_transitions(net, initial) == collect(1:5)
end

@testset "Арбитр и инварианты ресурсов" begin
    net, initial = build_arbiter_network(5)
    @test size(net.input) == (21, 15)
    @test initial[end] == 4
    result = simulate_stochastic(net, initial, 20.0;
        rng=MersenneTwister(605))
    @test !result.deadlock
    for philosopher in 1:5
        states = result.trajectory[!, Symbol("Think_$(philosopher)")] .+
                 result.trajectory[!, Symbol("Hungry_$(philosopher)")] .+
                 result.trajectory[!, Symbol("Eat_$(philosopher)")]
        @test all(states .== 1)
    end
    @test all(Matrix(result.trajectory[:, Not(:time)]) .>= 0)
end

@testset "Известная тупиковая маркировка" begin
    net, marking = build_classical_network(5)
    marking .= 0
    marking[6:10] .= 1
    @test detect_deadlock(net, marking)
end

@testset "Обязательные параметры и результаты" begin
    root = normpath(joinpath(@__DIR__, ".."))
    classic = CSV.read(joinpath(root, "data", "dining_classic.csv"), DataFrame)
    arbiter = CSV.read(joinpath(root, "data", "dining_arbiter.csv"), DataFrame)
    classic_net, _ = build_classical_network(5)
    arbiter_net, _ = build_arbiter_network(5)
    @test detect_deadlock(classic, classic_net)
    @test !detect_deadlock(arbiter, arbiter_net)
    @test last(arbiter.time) == 50.0
    @test all(Symbol("Eat_$(i)") in propertynames(classic) for i in 1:5)
end

@testset "Детерминированная аппроксимация" begin
    net, initial = build_arbiter_network(3)
    frame = simulate_ode(net, initial, 2.0; saveat=0.1)
    @test nrow(frame) == 21
    @test last(frame.time) == 2.0
    @test all(Matrix(frame[:, Not(:time)]) .>= 0)
end

@testset "Производные форматы всех сценариев" begin
    root = normpath(joinpath(@__DIR__, ".."))
    names = ("dining_philosophers", "dining_philosophers_animation",
             "dining_philosophers_report", "dining_philosophers__param")
    for name in names
        @test isfile(joinpath(root, "scripts", name, "$(name).jl"))
        @test isfile(joinpath(root, "notebooks", name, "$(name).ipynb"))
        @test isfile(joinpath(root, "markdown", name, "$(name).qmd"))
        notebook = read(joinpath(root, "notebooks", name, "$(name).ipynb"), String)
        @test occursin("\"execution_count\":", notebook)
        @test !occursin("\"execution_count\": null", notebook)
    end
end
