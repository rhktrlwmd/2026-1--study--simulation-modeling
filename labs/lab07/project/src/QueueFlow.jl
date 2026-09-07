module QueueFlow

using ConcurrentSim, ResumableFunctions, Distributions, StableRNGs, Random
using DataFrames, Statistics

export run_queue, queue_indicators, erlang_c_indicators

const StateRow = NamedTuple{(:time, :kind, :client, :waiting, :busy),
    Tuple{Float64, String, Int, Int, Int}}

mutable struct QueueState
    waiting::Int
    busy::Int
    history::Vector{StateRow}
end

function stamp!(state::QueueState, env, kind::String, client::Int)
    push!(state.history, (time=Float64(now(env)), kind=kind, client=client,
        waiting=state.waiting, busy=state.busy))
end

@resumable function visit(env::Environment, channels::Resource, client::Int,
        arrival::Float64, service_law::Exponential, rng::AbstractRNG,
        state::QueueState, started::Vector{Float64}, finished::Vector{Float64})
    @yield timeout(env, arrival)
    state.waiting += 1
    stamp!(state, env, "arrival", client)
    @yield request(channels)
    state.waiting -= 1
    state.busy += 1
    started[client] = now(env)
    stamp!(state, env, "service", client)
    @yield timeout(env, rand(rng, service_law))
    finished[client] = now(env)
    state.busy -= 1
    stamp!(state, env, "departure", client)
    @yield unlock(channels)
end

"""Simulate a FIFO M/M/c queue for a fixed number of completed clients."""
function run_queue(; clients=10, channels=2, arrival_rate=0.9,
        service_rate=0.5, seed=123)
    clients > 1 || throw(ArgumentError("clients must exceed one"))
    channels > 0 || throw(ArgumentError("channels must be positive"))
    arrival_rate > 0 && service_rate > 0 || throw(ArgumentError("rates must be positive"))
    rng = StableRNG(seed)
    env = Simulation()
    resource = Resource(env, channels)
    state = QueueState(0, 0, StateRow[])
    stamp!(state, env, "initial", 0)
    arrivals = cumsum(rand(rng, Exponential(inv(arrival_rate)), clients))
    started = fill(NaN, clients)
    finished = fill(NaN, clients)
    service_law = Exponential(inv(service_rate))
    for client in eachindex(arrivals)
        @process visit(env, resource, client, arrivals[client], service_law,
            rng, state, started, finished)
    end
    run(env)
    ledger = DataFrame(client=1:clients, arrival=arrivals, service_start=started,
        departure=finished, waiting=started-arrivals,
        service=finished-started, system=finished-arrivals)
    (ledger=ledger, states=DataFrame(state.history), channels=channels,
        arrival_rate=Float64(arrival_rate), service_rate=Float64(service_rate),
        completion=maximum(finished))
end

function state_average(states::DataFrame, column::Symbol, from::Float64, to::Float64)
    to > from || throw(ArgumentError("empty observation interval"))
    area = 0.0
    for row in 1:nrow(states)-1
        left = max(from, states.time[row])
        right = min(to, states.time[row+1])
        right > left && (area += (right-left) * states[row, column])
    end
    area / (to-from)
end

"""Estimate time and state indicators after discarding warm-up clients."""
function queue_indicators(result; warmup=0)
    0 <= warmup < nrow(result.ledger)-1 || throw(ArgumentError("invalid warmup"))
    sample = result.ledger[warmup+1:end, :]
    from = first(sample.arrival)
    to = last(sample.arrival)
    Lq = state_average(result.states, :waiting, from, to)
    busy = state_average(result.states, :busy, from, to)
    Wq = mean(sample.waiting)
    W = mean(sample.system)
    (; clients=nrow(result.ledger), observed=nrow(sample), warmup,
        lambda=result.arrival_rate, mu=result.service_rate, c=result.channels,
        rho=result.arrival_rate/(result.channels*result.service_rate),
        Wq, W, Lq, L=Lq+busy, utilization=busy/result.channels,
        p_wait=mean(sample.waiting .> 1e-12),
        little_queue_error=Lq-result.arrival_rate*Wq)
end

"""Stationary Erlang-C indicators. Values are missing when rho is not below one."""
function erlang_c_indicators(lambda::Real, mu::Real, c::Integer)
    lambda > 0 && mu > 0 && c > 0 || throw(ArgumentError("positive parameters required"))
    rho = lambda/(c*mu)
    rho >= 1 && return (; lambda, mu, c, rho, stable=false, p0=missing,
        p_wait=missing, Lq=missing, Wq=missing, W=missing, L=missing)
    offered = lambda/mu
    finite_sum = sum(offered^n/factorial(n) for n in 0:c-1)
    tail = offered^c/(factorial(c)*(1-rho))
    p0 = inv(finite_sum+tail)
    p_wait = tail*p0
    Lq = rho*p_wait/(1-rho)
    Wq = Lq/lambda
    W = Wq+inv(mu)
    (; lambda, mu, c, rho, stable=true, p0, p_wait, Lq, Wq, W, L=lambda*W)
end

end
