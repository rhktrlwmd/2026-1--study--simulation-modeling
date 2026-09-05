module Daisyworld

using Agents
using Random
using Statistics
using StatsBase: sample

export Daisy, create_world, advance!, observe, collect_history,
       update_surface_temperature!, diffuse_temperature!, propagate!, solar_activity!

@agent struct Daisy(GridAgent{2})
    breed::Symbol
    age::Int
    albedo::Float64
end

function local_heating(albedo, luminosity)
    absorbed = (1 - albedo) * luminosity
    return absorbed > 0 ? 72 * log(absorbed) + 80 : 80.0
end

function update_surface_temperature!(pos, model)
    albedo = isempty(pos, model) ? model.surface_albedo :
             model[id_in_position(pos, model)].albedo
    target = local_heating(albedo, model.solar_luminosity)
    model.temperature[pos...] = (model.temperature[pos...] + target) / 2
    return nothing
end

function diffuse_temperature!(model)
    before = copy(model.temperature)
    for pos in positions(model)
        neighbours = collect(nearby_positions(pos, model))
        neighbour_mean = mean(before[p...] for p in neighbours)
        model.temperature[pos...] =
            (1 - model.diffusion_ratio) * before[pos...] +
            model.diffusion_ratio * neighbour_mean
    end
    return nothing
end

function propagate!(pos, model)
    isempty(pos, model) && return nothing
    parent = model[id_in_position(pos, model)]
    temperature = model.temperature[pos...]
    probability = clamp(
        0.1457 * temperature - 0.0032 * temperature^2 - 0.6443,
        0.0,
        1.0,
    )
    rand(abmrng(model)) < probability || return nothing
    target = random_nearby_position(pos, model, 1, p -> isempty(p, model))
    isnothing(target) || add_agent!(target, model, parent.breed, 0, parent.albedo)
    return nothing
end

function daisy_step!(agent::Daisy, model)
    agent.age += 1
    agent.age >= model.max_age && remove_agent!(agent, model)
    return nothing
end

function solar_activity!(model)
    if model.scenario == :ramp
        200 < model.tick <= 400 && (model.solar_luminosity += model.solar_change)
        500 < model.tick <= 750 && (model.solar_luminosity -= model.solar_change / 2)
    elseif model.scenario == :change
        model.solar_luminosity += model.solar_change
    end
    return nothing
end

function world_step!(model)
    for pos in positions(model)
        update_surface_temperature!(pos, model)
    end
    diffuse_temperature!(model)
    for pos in positions(model)
        propagate!(pos, model)
    end
    model.tick += 1
    solar_activity!(model)
    return nothing
end

function create_world(;
    griddims=(30, 30), max_age=25,
    init_white=0.2, init_black=0.2,
    albedo_white=0.75, albedo_black=0.25,
    surface_albedo=0.4, solar_change=0.005,
    solar_luminosity=1.0, diffusion_ratio=0.5,
    scenario=:default, seed=165,
)
    all(>=(3), griddims) || throw(ArgumentError("grid dimensions must be at least 3"))
    max_age > 0 || throw(ArgumentError("max_age must be positive"))
    0 <= init_white <= 1 || throw(ArgumentError("init_white outside [0, 1]"))
    0 <= init_black <= 1 || throw(ArgumentError("init_black outside [0, 1]"))
    init_white + init_black <= 1 || throw(ArgumentError("initial cover exceeds the grid"))
    all(x -> 0 <= x <= 1, (albedo_white, albedo_black, surface_albedo)) ||
        throw(ArgumentError("albedo outside [0, 1]"))
    0 <= diffusion_ratio <= 1 || throw(ArgumentError("diffusion_ratio outside [0, 1]"))
    scenario in (:default, :ramp, :change) || throw(ArgumentError("unknown scenario"))

    properties = Dict{Symbol,Any}(
        :max_age=>max_age, :surface_albedo=>surface_albedo,
        :solar_luminosity=>solar_luminosity, :solar_change=>solar_change,
        :diffusion_ratio=>diffusion_ratio, :scenario=>scenario,
        :tick=>0, :temperature=>zeros(griddims),
    )
    model = StandardABM(
        Daisy, GridSpaceSingle(griddims; periodic=true);
        properties, rng=MersenneTwister(seed),
        agent_step! = daisy_step!, model_step! = world_step!,
        scheduler=Schedulers.fastest,
    )

    cells = collect(positions(model))
    white_cells = sample(abmrng(model), cells, floor(Int, init_white * length(cells)); replace=false)
    for pos in white_cells
        add_agent!(pos, model, :white, rand(abmrng(model), 0:max_age-1), albedo_white)
    end
    free_cells = setdiff(cells, white_cells)
    black_cells = sample(abmrng(model), free_cells, floor(Int, init_black * length(cells)); replace=false)
    for pos in black_cells
        add_agent!(pos, model, :black, rand(abmrng(model), 0:max_age-1), albedo_black)
    end
    for pos in positions(model)
        update_surface_temperature!(pos, model)
    end
    return model
end

advance!(model, steps=1) = Agents.step!(model, steps)

function observe(model)
    black = count(a -> a.breed == :black, allagents(model))
    white = count(a -> a.breed == :white, allagents(model))
    cell_albedo = mean(
        isempty(pos, model) ? model.surface_albedo : model[id_in_position(pos, model)].albedo
        for pos in positions(model)
    )
    mean_temperature = mean(model.temperature)
    return (
        time=model.tick, black, white, total=black + white,
        empty=length(model.temperature) - black - white,
        temperature=mean_temperature,
        luminosity=model.solar_luminosity,
        albedo=cell_albedo,
        regulation_error=abs(mean_temperature - 22.5),
    )
end

function collect_history(model, steps)
    rows = [observe(model)]
    for _ in 1:steps
        advance!(model)
        push!(rows, observe(model))
    end
    return rows
end

end
