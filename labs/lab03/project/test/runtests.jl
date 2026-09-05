using Test
using Agents
using DataFrames

include("../src/daisyworld.jl")
using .Daisyworld

@testset "Daisyworld initialization" begin
    model = create_world()
    state = observe(model)
    @test state.white == 180
    @test state.black == 180
    @test state.empty == 540
    @test nagents(model) == 360
    @test length(unique(a.pos for a in allagents(model))) == nagents(model)
    @test all(isfinite, model.temperature)
end

@testset "Parameter validation" begin
    @test_throws ArgumentError create_world(griddims=(2, 2))
    @test_throws ArgumentError create_world(max_age=0)
    @test_throws ArgumentError create_world(init_white=0.9, init_black=0.2)
    @test_throws ArgumentError create_world(surface_albedo=1.2)
    @test_throws ArgumentError create_world(diffusion_ratio=-0.1)
    @test_throws ArgumentError create_world(scenario=:unknown)
end

@testset "Reproducibility and invariants" begin
    first = create_world(seed=165)
    second = create_world(seed=165)
    advance!(first, 45)
    advance!(second, 45)
    @test observe(first) == observe(second)
    @test first.temperature == second.temperature
    @test first.tick == 45
    @test nagents(first) <= 900
    @test all(a -> a.age < first.max_age, allagents(first))
    @test 0 <= observe(first).albedo <= 1
end

@testset "Empty world and solar schedule" begin
    empty = create_world(init_white=0.0, init_black=0.0)
    advance!(empty, 20)
    @test nagents(empty) == 0

    ramp = create_world(scenario=:ramp, init_white=0.0, init_black=0.0)
    advance!(ramp, 200)
    @test ramp.solar_luminosity ≈ 1.0
    advance!(ramp, 200)
    @test ramp.solar_luminosity ≈ 2.0
    advance!(ramp, 100)
    @test ramp.solar_luminosity ≈ 2.0
    advance!(ramp, 250)
    @test ramp.solar_luminosity ≈ 1.375
end

@testset "History schema" begin
    frame = DataFrame(collect_history(create_world(seed=7), 10))
    @test nrow(frame) == 11
    @test frame.time == 0:10
    @test all(frame.total .+ frame.empty .== 900)
    @test all(isfinite, frame.temperature)
    @test all((0 .<= frame.albedo) .& (frame.albedo .<= 1))
end
