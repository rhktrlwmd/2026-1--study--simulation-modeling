using Test, ContactEpidemics.ContactProcesses
@testset "Conservation and reproducibility" begin
    m = simulate()
    @test check_balance(m)
    @test table(m) == table(simulate())
    @test first(table(m).I) == 10
    @test last(table(m).t) == 40.0
    @test all(diff(table(m).S) .<= 0)
end
@testset "No transmission and deterministic recovery" begin
    m = simulate(config=Settings(beta=0.0,fixed=true),T=5.0)
    @test m.counts == [990,0,0,10]
    @test all(row.t == 4.0 for row in m.log if row.event == :recovery)
    @test simulate(u0=(1,0,0)).counts == [1,0,0,0]
    @test simulate(u0=(0,0,0)).counts == [0,0,0,0]
end
@testset "Competing processes cannot resurrect people" begin
    m = simulate(u0=(10,10,0),T=30.0,
        config=Settings(mortality=5.0,latent=0.5))
    @test check_balance(m)
    @test isempty(m.living)
    dead = Set{Int}()
    for row in m.log
        @test !(row.person in dead)
        row.event == :death && push!(dead,row.person)
    end
    @test !transition!(m,1,4,:recovery)
end
@testset "Vaccination and latent infection" begin
    m = simulate(config=Settings(vaccination_time=0.0,
        vaccination_fraction=1.0),T=80.0)
    @test m.cases == 10
    @test m.vaccinated == 990
    @test check_balance(m)
    seir = simulate(config=Settings(latent=0.5),T=80.0)
    @test maximum(table(seir).E) > 0
    @test check_balance(seir)
end
@testset "Demographic balance and sampling" begin
    m = simulate(config=Settings(mortality=0.05,births=50.0))
    @test check_balance(m)
    @test m.born > 0 && m.died > 0
    d = table(m)
    @test sample_path(d,[0.0,40.0]) == [10,last(d.I)]
    @test_throws ArgumentError prepare(config=Settings(beta=1.1))
    @test_throws ArgumentError activate!(m)
end
