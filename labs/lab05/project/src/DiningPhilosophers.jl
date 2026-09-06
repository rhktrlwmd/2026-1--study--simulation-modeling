module DiningPhilosophers

using CairoMakie
using DataFrames
using Random

export PetriSystem, SimulationResult, build_classical_network
export build_arbiter_network, enabled_transitions, fire!
export simulate_ode, simulate_stochastic, detect_deadlock
export plot_marking_evolution, philosopher_columns, event_summary

"""A place/transition net with separate input and output arc matrices."""
struct PetriSystem
    input::Matrix{Int}
    output::Matrix{Int}
    place_names::Vector{Symbol}
    transition_names::Vector{Symbol}
    variant::Symbol
end

struct SimulationResult
    trajectory::DataFrame
    events::DataFrame
    deadlock::Bool
    meal_counts::Vector{Int}
end

nplaces(net::PetriSystem) = length(net.place_names)
ntransitions(net::PetriSystem) = length(net.transition_names)
incidence(net::PetriSystem) = net.output - net.input

function philosopher_columns(group::AbstractString, count::Int)
    [Symbol("$(group)_$(i)") for i in 1:count]
end

function build_network(count::Int; arbiter::Bool)
    count >= 2 || throw(ArgumentError("At least two philosophers are required"))
    places = 4count + (arbiter ? 1 : 0)
    transitions = 3count
    input = zeros(Int, places, transitions)
    output = zeros(Int, places, transitions)

    names = reduce(vcat, [philosopher_columns(group, count)
                          for group in ("Think", "Hungry", "Eat", "Fork")])
    arbiter && push!(names, :Arbiter)
    actions = reduce(vcat, [philosopher_columns(group, count)
                            for group in ("TakeLeft", "TakeRight", "Release")])

    for i in 1:count
        think, hungry = i, count + i
        eat, left = 2count + i, 3count + i
        right = 3count + mod1(i + 1, count)
        take_left, take_right, release = i, count + i, 2count + i

        input[think, take_left] = 1
        input[left, take_left] = 1
        output[hungry, take_left] = 1

        input[hungry, take_right] = 1
        input[right, take_right] = 1
        output[eat, take_right] = 1

        input[eat, release] = 1
        output[think, release] = 1
        output[left, release] = 1
        output[right, release] = 1

        if arbiter
            permit = places
            input[permit, take_left] = 1
            output[permit, release] = 1
        end
    end

    initial = zeros(Int, places)
    initial[1:count] .= 1
    initial[(3count + 1):(4count)] .= 1
    arbiter && (initial[end] = count - 1)
    variant = arbiter ? :arbiter : :classical
    PetriSystem(input, output, names, actions, variant), initial
end

build_classical_network(count::Int) = build_network(count; arbiter=false)
build_arbiter_network(count::Int) = build_network(count; arbiter=true)

function enabled_transitions(net::PetriSystem, marking::AbstractVector)
    [j for j in 1:ntransitions(net)
     if all(marking .>= view(net.input, :, j))]
end

function fire!(net::PetriSystem, marking::Vector{Int}, transition::Int)
    transition in enabled_transitions(net, marking) ||
        throw(ArgumentError("Transition $(net.transition_names[transition]) is disabled"))
    marking .+= view(net.output, :, transition) .- view(net.input, :, transition)
    marking
end

function rate_vector(count::Int; left=2.4, right=0.8, release=1.1)
    vcat(fill(float(left), count), fill(float(right), count),
         fill(float(release), count))
end

function propensities(net::PetriSystem, marking::AbstractVector, rates::AbstractVector)
    length(rates) == ntransitions(net) ||
        throw(DimensionMismatch("One rate is required for every transition"))
    values = zeros(Float64, ntransitions(net))
    for transition in enabled_transitions(net, marking)
        activity = rates[transition]
        for place in 1:nplaces(net)
            demand = net.input[place, transition]
            demand > 0 && (activity *= marking[place]^demand)
        end
        values[transition] = activity
    end
    values
end

function trajectory_frame(times, states, names)
    frame = DataFrame(time=times)
    for (index, name) in enumerate(names)
        frame[!, name] = [state[index] for state in states]
    end
    frame
end

function simulate_stochastic(net::PetriSystem, initial::Vector{Int}, horizon::Real;
                             rates=rate_vector(div(length(net.transition_names), 3)),
                             rng=MersenneTwister(202605))
    horizon > 0 || throw(ArgumentError("The horizon must be positive"))
    marking = copy(initial)
    times = Float64[0.0]
    states = Vector{Int}[copy(marking)]
    event_times = Float64[]
    event_names = String[]
    philosopher_ids = Int[]
    meals = zeros(Int, div(ntransitions(net), 3))
    time = 0.0

    while time < horizon
        weights = propensities(net, marking, rates)
        total = sum(weights)
        total == 0 && break
        next_time = time - log(rand(rng)) / total
        if next_time > horizon
            push!(times, float(horizon))
            push!(states, copy(marking))
            break
        end
        threshold = rand(rng) * total
        chosen = findfirst(>=(threshold), cumsum(weights))
        fire!(net, marking, chosen)
        time = next_time
        push!(times, time)
        push!(states, copy(marking))
        push!(event_times, time)
        push!(event_names, string(net.transition_names[chosen]))
        philosopher = mod1(chosen, length(meals))
        push!(philosopher_ids, philosopher)
        chosen > 2length(meals) && (meals[philosopher] += 1)
    end

    trajectory = trajectory_frame(times, states, net.place_names)
    events = DataFrame(time=event_times, transition=event_names,
                       philosopher=philosopher_ids)
    SimulationResult(trajectory, events, detect_deadlock(net, marking), meals)
end

function continuous_rhs(net::PetriSystem, marking, rates)
    activity = similar(rates, Float64)
    for transition in 1:ntransitions(net)
        value = rates[transition]
        for place in 1:nplaces(net)
            demand = net.input[place, transition]
            demand > 0 && (value *= max(marking[place], 0.0)^demand)
        end
        activity[transition] = value
    end
    incidence(net) * activity
end

"""Fixed-step RK4 integration of the deterministic mass-action approximation."""
function simulate_ode(net::PetriSystem, initial::AbstractVector, horizon::Real;
                      rates=rate_vector(div(length(net.transition_names), 3)),
                      saveat=0.1)
    horizon > 0 || throw(ArgumentError("The horizon must be positive"))
    saveat > 0 || throw(ArgumentError("saveat must be positive"))
    times = collect(0.0:saveat:float(horizon))
    last(times) < horizon && push!(times, float(horizon))
    state = Float64.(initial)
    states = Vector{Float64}[copy(state)]
    current = 0.0
    for target in Iterators.drop(times, 1)
        step = target - current
        k1 = continuous_rhs(net, state, rates)
        k2 = continuous_rhs(net, state .+ step .* k1 ./ 2, rates)
        k3 = continuous_rhs(net, state .+ step .* k2 ./ 2, rates)
        k4 = continuous_rhs(net, state .+ step .* k3, rates)
        state .+= step .* (k1 .+ 2k2 .+ 2k3 .+ k4) ./ 6
        state .= max.(state, 0.0)
        push!(states, copy(state))
        current = target
    end
    trajectory_frame(times, states, net.place_names)
end

detect_deadlock(net::PetriSystem, marking::AbstractVector) =
    isempty(enabled_transitions(net, marking))

function detect_deadlock(frame::DataFrame, net::PetriSystem)
    final = [frame[end, name] for name in net.place_names]
    detect_deadlock(net, final)
end

function event_summary(result::SimulationResult, horizon::Real, variant::AbstractString)
    completed = sum(result.meal_counts)
    fairness = completed == 0 ? 0.0 :
        sum(result.meal_counts)^2 /
        (length(result.meal_counts) * sum(abs2, result.meal_counts))
    (variant=variant, deadlock=result.deadlock,
     last_time=last(result.trajectory.time), events=nrow(result.events),
     meals=completed, fairness=fairness, horizon=float(horizon))
end

function plot_marking_evolution(frame::DataFrame, count::Int; title="")
    colors = [:royalblue3, :darkorange2, :seagreen3, :firebrick2,
              :mediumpurple3, :goldenrod2, :deepskyblue3]
    figure = Figure(size=(1200, 900), fontsize=16)
    groups = ("Think", "Hungry", "Eat", "Fork")
    for (panel, group) in enumerate(groups)
        row = div(panel - 1, 2) + 1
        column = mod(panel - 1, 2) + 1
        axis = Axis(figure[row, column], title=group,
                    xlabel="Время", ylabel="Фишки")
        for philosopher in 1:count
            name = Symbol("$(group)_$(philosopher)")
            stairs!(axis, frame.time, frame[!, name]; step=:post,
                    color=colors[mod1(philosopher, length(colors))],
                    linewidth=2, label="Философ $(philosopher)")
        end
        axis.yticks = 0:1
        axislegend(axis; position=:rt, nbanks=count > 4 ? 2 : 1,
                   labelsize=11)
    end
    Label(figure[0, :], title, fontsize=23, font=:bold)
    figure
end

end
