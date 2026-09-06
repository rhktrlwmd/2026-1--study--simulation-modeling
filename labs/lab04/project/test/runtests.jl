using Test
using DataFrames
using DrWatson
@quickactivate "AgentSIRLab"
include(srcdir("sir_model.jl"))
using .SIRModel

@testset "Migration matrix" begin
    matrix = migration_matrix(3, 0.12)
    @test size(matrix) == (3, 3)
    @test all(isapprox.(vec(sum(matrix; dims=2)), 1.0))
    @test [matrix[i, i] for i in 1:3] == fill(0.88, 3)
    @test_throws ArgumentError migration_matrix(1, 0.1)
    @test_throws ArgumentError migration_matrix(3, 1.1)
end

@testset "Initialization and invariants" begin
    model = initialize_sir(Ns=[30, 40, 50], Is=[1, 2, 3],
        β_und=fill(0.3, 3), β_det=fill(0.03, 3), seed=7)
    @test total_count(model) == 120
    @test infected_count(model) == 6
    @test susceptible_count(model) == 114
    history = DataFrame(collect_history(model, 30))
    @test nrow(history) == 31
    @test history.time == 0:30
    @test all(history.susceptible .+ history.infected .+ history.recovered .== history.living)
    @test all(history.living .+ history.deaths .== 120)
    @test all((0 .<= history.infected_fraction) .& (history.infected_fraction .<= 1))
end

@testset "Reproducibility" begin
    kwargs = (Ns=[60, 60, 60], Is=[2, 0, 0], β_und=fill(0.45, 3),
              β_det=fill(0.045, 3), seed=44, n_steps=40)
    _, first = run_sir(; kwargs...)
    _, second = run_sir(; kwargs...)
    @test first == second
end

@testset "City statistics and quarantine" begin
    model = initialize_sir(Ns=[50, 50, 50], Is=[8, 0, 0],
        β_und=fill(0.5, 3), β_det=fill(0.05, 3),
        quarantine_enabled=true, quarantine_threshold=0.05,
        migration_rates=migration_matrix(3, 0.1), seed=19)
    @test model.closed[1]
    rows = DataFrame(collect_history(model, 10; by_city=true))
    @test nrow(rows) == 33
    @test sort(unique(rows.city)) == [1, 2, 3]
    @test all(rows.susceptible .+ rows.infected .+ rows.recovered .== rows.living)
end

@testset "Epidemiological quantities" begin
    @test basic_reproduction_number(0.5, 14) == 7.0
    @test basic_reproduction_number(1 / 14, 14) ≈ 1.0
    @test_throws ArgumentError initialize_sir(Ns=[10, 10], Is=[0, 0],
        β_und=[0.2], β_det=[0.02])
end
