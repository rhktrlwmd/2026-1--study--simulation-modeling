module SIRModel

using Agents
using Agents.Graphs
using Distributions: Poisson
using Random
using StatsBase: Weights, sample

export Person, initialize_sir, migration_matrix, advance!, observe,
       city_observations, collect_history, run_sir, basic_reproduction_number,
       infected_count, recovered_count, susceptible_count, total_count

@agent struct Person(GraphAgent)
    days_infected::Int
    status::Symbol
end

function migration_matrix(cities::Integer, intensity::Real)
    cities >= 2 || throw(ArgumentError("at least two cities are required"))
    0 <= intensity <= 1 || throw(ArgumentError("migration intensity outside [0, 1]"))
    matrix = fill(Float64(intensity) / (cities - 1), cities, cities)
    for city in 1:cities
        matrix[city, city] = 1 - intensity
    end
    return matrix
end

function validate_parameters(Ns, β_und, β_det, infection_period, detection_time,
                             death_rate, reinfection_probability, Is, migration_rates)
    cities = length(Ns)
    cities >= 2 || throw(ArgumentError("at least two cities are required"))
    all(>(0), Ns) || throw(ArgumentError("city populations must be positive"))
    length(β_und) == cities == length(β_det) == length(Is) ||
        throw(ArgumentError("city parameter vectors must have equal length"))
    all(x -> x >= 0, β_und) && all(x -> x >= 0, β_det) ||
        throw(ArgumentError("transmission rates must be non-negative"))
    all((0 .<= Is) .& (Is .<= Ns)) || throw(ArgumentError("invalid initial infections"))
    infection_period > 0 || throw(ArgumentError("infection period must be positive"))
    1 <= detection_time <= infection_period || throw(ArgumentError("invalid detection time"))
    0 <= death_rate <= 1 || throw(ArgumentError("death rate outside [0, 1]"))
    0 <= reinfection_probability <= 1 || throw(ArgumentError("reinfection probability outside [0, 1]"))
    size(migration_rates) == (cities, cities) || throw(ArgumentError("invalid migration matrix"))
    all(migration_rates .>= 0) || throw(ArgumentError("negative migration probability"))
    all(isapprox.(vec(sum(migration_rates; dims=2)), 1.0; atol=1e-10)) ||
        throw(ArgumentError("migration matrix rows must sum to one"))
    return nothing
end

function initialize_sir(;
    Ns=[1000, 1000, 1000],
    migration_rates=nothing,
    β_und=[0.5, 0.5, 0.5],
    β_det=[0.05, 0.05, 0.05],
    infection_period=14,
    detection_time=7,
    death_rate=0.02,
    reinfection_probability=0.1,
    Is=[0, 0, 1],
    seed=42,
    quarantine_enabled=false,
    quarantine_threshold=0.08,
)
    cities = length(Ns)
    migration_rates = isnothing(migration_rates) ? migration_matrix(cities, 0.04) : Float64.(migration_rates)
    validate_parameters(Ns, β_und, β_det, infection_period, detection_time,
                        death_rate, reinfection_probability, Is, migration_rates)
    0 <= quarantine_threshold <= 1 || throw(ArgumentError("quarantine threshold outside [0, 1]"))

    properties = Dict{Symbol,Any}(
        :Ns=>collect(Int, Ns), :β_und=>collect(Float64, β_und),
        :β_det=>collect(Float64, β_det), :migration_rates=>migration_rates,
        :infection_period=>Int(infection_period), :detection_time=>Int(detection_time),
        :death_rate=>Float64(death_rate),
        :reinfection_probability=>Float64(reinfection_probability),
        :C=>cities, :day=>0, :deaths=>0, :deaths_by_city=>zeros(Int, cities),
        :quarantine_enabled=>quarantine_enabled,
        :quarantine_threshold=>Float64(quarantine_threshold),
        :closed=>falses(cities), :ever_infected=>sum(Is),
    )
    model = StandardABM(
        Person, GraphSpace(complete_graph(cities)); properties,
        rng=Xoshiro(seed), agent_step! = sir_agent_step!,
        model_step! = sir_model_step!, scheduler=Schedulers.fastest,
    )
    for city in 1:cities, _ in 1:Ns[city]
        add_agent!(city, model, 0, :S)
    end
    for city in 1:cities
        candidates = collect(ids_in_position(city, model))
        for id in sample(abmrng(model), candidates, Is[city]; replace=false)
            model[id].status = :I
            model[id].days_infected = 1
        end
    end
    update_quarantine!(model)
    return model
end

function migrate!(agent, model)
    model.closed[agent.pos] && return nothing
    target = sample(abmrng(model), 1:model.C, Weights(model.migration_rates[agent.pos, :]))
    target == agent.pos || move_agent!(agent, target, model)
    return nothing
end

function transmit!(agent, model)
    rate = agent.days_infected < model.detection_time ?
           model.β_und[agent.pos] : model.β_det[agent.pos]
    remaining = rand(abmrng(model), Poisson(rate))
    remaining == 0 && return nothing
    contacts = collect(ids_in_position(agent.pos, model))
    shuffle!(abmrng(model), contacts)
    for id in contacts
        id == agent.id && continue
        contact = model[id]
        infectable = contact.status == :S ||
                     (contact.status == :R && rand(abmrng(model)) <= model.reinfection_probability)
        infectable || continue
        contact.status = :I
        contact.days_infected = 1
        model.ever_infected += 1
        remaining -= 1
        remaining == 0 && break
    end
    return nothing
end

function recover_or_die!(agent, model)
    agent.status == :I && agent.days_infected >= model.infection_period || return nothing
    if rand(abmrng(model)) <= model.death_rate
        city = agent.pos
        model.deaths += 1
        model.deaths_by_city[city] += 1
        remove_agent!(agent, model)
    else
        agent.status = :R
        agent.days_infected = 0
    end
    return nothing
end

function sir_agent_step!(agent, model)
    migrate!(agent, model)
    agent.status == :I && transmit!(agent, model)
    agent.status == :I && (agent.days_infected += 1)
    recover_or_die!(agent, model)
    return nothing
end

function update_quarantine!(model)
    if model.quarantine_enabled
        for city in 1:model.C
            city_ids = collect(ids_in_position(city, model))
            infected = count(id -> model[id].status == :I, city_ids)
            model.closed[city] = !isempty(city_ids) && infected / length(city_ids) >= model.quarantine_threshold
        end
    else
        model.closed .= false
    end
    return nothing
end

function sir_model_step!(model)
    model.day += 1
    update_quarantine!(model)
    return nothing
end

advance!(model, steps=1) = Agents.step!(model, steps)
susceptible_count(model) = count(a -> a.status == :S, allagents(model))
infected_count(model) = count(a -> a.status == :I, allagents(model))
recovered_count(model) = count(a -> a.status == :R, allagents(model))
total_count(model) = nagents(model)
basic_reproduction_number(β, infection_period) = β * infection_period

function observe(model)
    return (
        time=model.day, susceptible=susceptible_count(model),
        infected=infected_count(model), recovered=recovered_count(model),
        living=total_count(model), deaths=model.deaths,
        infected_fraction=infected_count(model) / max(total_count(model), 1),
        closed_cities=count(model.closed),
    )
end

function city_observations(model)
    rows = NamedTuple[]
    for city in 1:model.C
        ids = collect(ids_in_position(city, model))
        push!(rows, (
            time=model.day, city, susceptible=count(id -> model[id].status == :S, ids),
            infected=count(id -> model[id].status == :I, ids),
            recovered=count(id -> model[id].status == :R, ids),
            living=length(ids), deaths=model.deaths_by_city[city], closed=model.closed[city],
        ))
    end
    return rows
end

function collect_history(model, steps; by_city=false)
    rows = by_city ? city_observations(model) : [observe(model)]
    for _ in 1:steps
        advance!(model)
        append!(rows, by_city ? city_observations(model) : [observe(model)])
    end
    return rows
end

function run_sir(; n_steps=100, by_city=false, kwargs...)
    model = initialize_sir(; kwargs...)
    return model, collect_history(model, n_steps; by_city)
end

end
