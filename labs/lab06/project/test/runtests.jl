using Test, DataFrames
include(joinpath(@__DIR__, "..", "src", "SIRPetri.jl"))
using .SIRPetri

@testset "SIR Petri model" begin
    network = build_sir_network()
    @test incidence_matrix(network) == [-1 0; 1 -1; 0 1]
    config = SIRConfig()
    ode = deterministic_trajectory(config; saveat=0.5)
    ssa = stochastic_trajectory(config; seed=123)
    @test nrow(ode) == 201
    @test ode.S + ode.I + ode.R ≈ fill(1000.0, nrow(ode)) atol=1e-7
    @test all(ssa.S + ssa.I + ssa.R .== 1000)
    @test nrow(ssa) > 1000
    peak = refined_peak(config)
    @test abs(peak.infected - peak.analytical) < 1e-5
    @test peak.time < 0.5
    sampled = sample_right_continuous(ssa, [0.0, 0.5, 100.0])
    @test sampled.time == [0.0, 0.5, 100.0]
end
