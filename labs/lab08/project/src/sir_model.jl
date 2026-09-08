module ContactProcesses
using ConcurrentSim, ResumableFunctions, Distributions, Random
using StableRNGs, DataFrames
export Settings, Population, prepare, simulate, table, check_balance
export vaccinate!, transition!, activate!, finish!, sample_path

Base.@kwdef struct Settings
    beta::Float64 = 0.05
    contact::Float64 = 10.0
    recovery::Float64 = 0.25
    latent::Float64 = Inf
    fixed::Bool = false
    mortality::Float64 = 0.0
    births::Float64 = 0.0
    vaccination_time::Float64 = Inf
    vaccination_fraction::Float64 = 0.0
end

const Record = NamedTuple{(:t,:event,:person,:S,:E,:I,:R,:B,:D,:V,:cases),
    Tuple{Float64,Symbol,Int,Int,Int,Int,Int,Int,Int,Int,Int}}

mutable struct Population
    clock::Simulation
    config::Settings
    rng::StableRNG
    state::Vector{Int}
    living::Vector{Int}
    slot::Vector{Int}
    counts::Vector{Int}
    initial::Int
    born::Int
    died::Int
    vaccinated::Int
    cases::Int
    log::Vector{Record}
    active::Bool
end

function record!(m, event, id)
    s,e,i,r = m.counts
    push!(m.log, (t=Float64(now(m.clock)), event=event, person=id,
        S=s,E=e,I=i,R=r,B=m.born,D=m.died,V=m.vaccinated,cases=m.cases))
end

"""Change a living person's compartment and append one atomic ledger row."""
function transition!(m, id, destination, event)
    previous = m.state[id]
    previous == 0 && return false
    previous == destination && return false
    m.counts[previous] -= 1
    m.state[id] = destination
    if destination == 0
        position = m.slot[id]
        replacement = last(m.living)
        m.living[position] = replacement
        m.slot[replacement] = position
        pop!(m.living)
        m.slot[id] = 0
        m.died += 1
    else
        m.counts[destination] += 1
    end
    event == :infection && (m.cases += 1)
    event == :vaccination && (m.vaccinated += 1)
    record!(m, event, id)
    true
end

@resumable function disease(clock::Simulation, m::Population, id::Int)
    while m.state[id] == 1
        @yield timeout(clock, rand(m.rng, Exponential(1/m.config.contact)))
        # A pending timeout does not override death or vaccination.
        m.state[id] == 1 || return
        n = length(m.living)
        n <= 1 && continue
        draw = rand(m.rng, 1:n-1)
        draw >= m.slot[id] && (draw += 1)
        other = m.living[draw]
        if m.state[other] == 3 && rand(m.rng) < m.config.beta
            target = isfinite(m.config.latent) ? 2 : 3
            transition!(m,id,target,:infection)
        end
    end
    if m.state[id] == 2
        @yield timeout(clock,rand(m.rng,Exponential(1/m.config.latent)))
        m.state[id] == 2 || return
        transition!(m,id,3,:onset)
    end
    if m.state[id] == 3
        duration = m.config.fixed ? 1/m.config.recovery :
            rand(m.rng,Exponential(1/m.config.recovery))
        @yield timeout(clock,duration)
        m.state[id] == 3 || return
        transition!(m,id,4,:recovery)
    end
end

@resumable function death(clock::Simulation, m::Population, id::Int)
    @yield timeout(clock,rand(m.rng,Exponential(1/m.config.mortality)))
    transition!(m,id,0,:death)
end

function launch!(m,id)
    @process disease(m.clock,m,id)
    if m.config.mortality > 0
        @process death(m.clock,m,id)
    end
end

@resumable function immigration(clock::Simulation,m::Population)
    while true
        @yield timeout(clock,rand(m.rng,Exponential(1/m.config.births)))
        id = length(m.state)+1
        push!(m.state,1)
        push!(m.living,id)
        push!(m.slot,length(m.living))
        m.counts[1] += 1
        m.born += 1
        record!(m,:birth,id)
        launch!(m,id)
    end
end

"""Vaccinate a random fraction of current susceptibles, without new cases."""
function vaccinate!(m, fraction)
    0 <= fraction <= 1 || throw(ArgumentError("invalid fraction"))
    candidates = filter(id -> m.state[id] == 1,m.living)
    shuffle!(m.rng,candidates)
    for id in candidates[1:floor(Int,fraction*length(candidates))]
        transition!(m,id,4,:vaccination)
    end
end

@resumable function vaccination(clock::Simulation,m::Population)
    @yield timeout(clock,m.config.vaccination_time)
    vaccinate!(m,m.config.vaccination_fraction)
end

"""Build a fresh unstarted model; compartments are S=1, E=2, I=3, R=4."""
function prepare(; u0=(990,10,0), seed=1234, config=Settings())
    all(x -> x >= 0,u0) || throw(ArgumentError("negative population"))
    0 <= config.beta <= 1 || throw(ArgumentError("invalid beta"))
    config.contact > 0 && config.recovery > 0 && config.latent > 0 ||
        throw(ArgumentError("rates must be positive"))
    config.mortality >= 0 && config.births >= 0 ||
        throw(ArgumentError("negative demographic rate"))
    config.vaccination_time >= 0 || throw(ArgumentError("negative time"))
    0 <= config.vaccination_fraction <= 1 ||
        throw(ArgumentError("invalid fraction"))
    s,i,r = u0
    n = sum(u0)
    states = vcat(fill(1,s),fill(3,i),fill(4,r))
    m = Population(Simulation(),config,StableRNG(seed),states,
        collect(1:n),collect(1:n),[s,0,i,r],n,0,0,0,i,Record[],false)
    record!(m,:initial,0)
    m
end

function activate!(m)
    m.active && throw(ArgumentError("model already active"))
    m.active = true
    for id in copy(m.living)
        launch!(m,id)
    end
    m.config.births > 0 && (@process immigration(m.clock,m))
    isfinite(m.config.vaccination_time) && (@process vaccination(m.clock,m))
    m
end

function finish!(m,T)
    T > now(m.clock) || throw(ArgumentError("horizon must advance"))
    run(m.clock,Float64(T))
    record!(m,:horizon,0)
    m
end

function simulate(; T=40.0,kwargs...)
    finish!(activate!(prepare(;kwargs...)),T)
end

table(m) = DataFrame(m.log)

"""Check conservation at every event, plus the live-index bijection."""
function check_balance(m)
    all(row -> row.S+row.E+row.I+row.R == m.initial+row.B-row.D &&
        min(row.S,row.E,row.I,row.R) >= 0,m.log) &&
    sum(m.counts) == length(m.living) &&
    all(k -> m.slot[m.living[k]] == k,eachindex(m.living)) &&
    all(j -> count(==(j),m.state) == m.counts[j],1:4)
end

"""Right-continuous sampling preserves event jumps and duplicate times."""
function sample_path(data,grid; column=:I)
    [data[searchsortedlast(data.t,t),column] for t in grid]
end
end
