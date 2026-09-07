module SIRPetri

using AlgebraicPetri
using OrdinaryDiffEq
using DataFrames
using Random
using Statistics

export SIRConfig, build_sir_network, incidence_matrix, deterministic_trajectory
export stochastic_trajectory, sample_right_continuous, refined_peak
export trajectory_metrics, compare_at_events

Base.@kwdef struct SIRConfig
    beta::Float64 = 0.3
    gamma::Float64 = 0.1
    susceptible::Int = 990
    infected::Int = 10
    recovered::Int = 0
    horizon::Float64 = 100.0
end

"""Create the labelled Petri net S + I -> 2I, I -> R."""
function build_sir_network()
    LabelledPetriNet(
        [:S, :I, :R],
        :infection => ((:S, :I) => (:I, :I)),
        :recovery => (:I => :R),
    )
end

initial_state(c::SIRConfig) = Float64[c.susceptible, c.infected, c.recovered]
rates(c::SIRConfig) = Float64[c.beta, c.gamma]

function validate(c::SIRConfig)
    c.beta >= 0 && c.gamma >= 0 || throw(ArgumentError("rates must be non-negative"))
    minimum((c.susceptible, c.infected, c.recovered)) >= 0 ||
        throw(ArgumentError("initial marking must be non-negative"))
    c.horizon > 0 || throw(ArgumentError("horizon must be positive"))
    c
end

"""Incidence matrix derived from Petri-net arcs."""
function incidence_matrix(net)
    matrix = zeros(Int, ns(net), nt(net))
    for transition in 1:nt(net)
        for state in inputs(net, transition)
            matrix[state, transition] -= 1
        end
        for state in outputs(net, transition)
            matrix[state, transition] += 1
        end
    end
    matrix
end

"""Mass-action propensities; infection is beta*S*I without N normalization."""
function propensities(marking, c::SIRConfig)
    Float64[c.beta * marking[1] * marking[2], c.gamma * marking[2]]
end

function ode_problem(c::SIRConfig)
    validate(c)
    net = build_sir_network()
    change = incidence_matrix(net)
    function rhs!(du, u, _, _)
        du .= change * propensities(u, c)
        nothing
    end
    ODEProblem(rhs!, initial_state(c), (0.0, c.horizon))
end

function deterministic_trajectory(c::SIRConfig; saveat=0.5)
    solution = solve(ode_problem(c), Tsit5(); saveat, reltol=1e-9, abstol=1e-11)
    successful_retcode(solution) || error("ODE solver failed: $(solution.retcode)")
    DataFrame(time=Float64.(solution.t), S=solution[1, :], I=solution[2, :], R=solution[3, :])
end

function deterministic_at(c::SIRConfig, times)
    solution = solve(ode_problem(c), Tsit5(); reltol=1e-9, abstol=1e-11, dense=true)
    values = reduce(hcat, solution.(Float64.(times)))
    DataFrame(time=Float64.(times), S=values[1, :], I=values[2, :], R=values[3, :])
end

"""Direct Gillespie simulation on its native event-time grid."""
function stochastic_trajectory(c::SIRConfig; seed=123)
    validate(c)
    net = build_sir_network()
    change = incidence_matrix(net)
    rng = MersenneTwister(seed)
    marking = Int[c.susceptible, c.infected, c.recovered]
    t = 0.0
    rows = [(time=t, S=marking[1], I=marking[2], R=marking[3])]
    while t < c.horizon
        hazards = propensities(marking, c)
        total = sum(hazards)
        total <= 0 && break
        event_time = t - log(rand(rng)) / total
        event_time > c.horizon && break
        selected = searchsortedfirst(cumsum(hazards), rand(rng) * total)
        marking .+= change[:, selected]
        minimum(marking) >= 0 || error("negative Petri marking")
        t = event_time
        push!(rows, (time=t, S=marking[1], I=marking[2], R=marking[3]))
    end
    if rows[end].time < c.horizon
        push!(rows, (time=c.horizon, S=marking[1], I=marking[2], R=marking[3]))
    end
    DataFrame(rows)
end

"""Right-continuous interpolation of an SSA path at requested times."""
function sample_right_continuous(events::DataFrame, times)
    indices = clamp.(searchsortedlast.(Ref(events.time), Float64.(times)), 1, nrow(events))
    DataFrame(time=Float64.(times), S=events.S[indices], I=events.I[indices], R=events.R[indices])
end

function refined_peak(c::SIRConfig)
    solution = solve(ode_problem(c), Tsit5(); reltol=1e-11, abstol=1e-12, dense=true)
    threshold = c.gamma / c.beta
    if c.beta == 0 || c.susceptible <= threshold
        return (time=0.0, infected=Float64(c.infected), analytical=Float64(c.infected))
    end
    left, right = 0.0, c.horizon
    for _ in 1:80
        middle = (left + right) / 2
        solution(middle)[1] > threshold ? (left = middle) : (right = middle)
    end
    peak_time = (left + right) / 2
    s0 = Float64(c.susceptible)
    i0 = Float64(c.infected)
    analytical = i0 + s0 - threshold + threshold * log(threshold / s0)
    (time=peak_time, infected=solution(peak_time)[2], analytical=analytical)
end

function trajectory_metrics(data::DataFrame)
    peak_index = argmax(data.I)
    (peak_I=Float64(data.I[peak_index]), peak_time=Float64(data.time[peak_index]),
     final_R=Float64(data.R[end]), mass_error=maximum(abs.(data.S .+ data.I .+ data.R .- 1000)))
end

function compare_at_events(c::SIRConfig, events::DataFrame)
    ode = deterministic_at(c, events.time)
    delta = Float64.(events.I) .- ode.I
    DataFrame(time=events.time, ODE_I=ode.I, SSA_I=events.I, difference=delta)
end

end
