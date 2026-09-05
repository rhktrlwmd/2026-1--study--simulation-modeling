using Test
using BasicModelsLab.BasicModels

@testset "SIR model" begin
    p = [0.05, 10.0, 0.25]
    df = sir_dataframe(solve_sir(; p))
    @test length(df.t) == 401
    @test maximum(abs.(df.N .- 1000.0)) < 1e-6
    @test all(df.S .>= 0) && all(df.I .>= 0) && all(df.R .>= 0)
    @test maximum(df.I) > 150
    @test df.S[end] < df.S[1] && df.R[end] > df.R[1]
end

@testset "Lotka–Volterra model" begin
    p = [0.1, 0.02, 0.01, 0.3]
    df = lv_dataframe(solve_lv(; p), p)
    conserved = invariant_lv(df.prey, df.predator, p)
    @test length(df.t) == 2001
    @test all(df.prey .> 0) && all(df.predator .> 0)
    @test maximum(abs.(conserved .- first(conserved))) < 1e-6
    @test first_local_peak(df.prey, df.t).index > 0
    @test first_local_peak(df.predator, df.t).index > 0
end
