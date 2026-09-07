module RepairReserve

using ConcurrentSim, ResumableFunctions, Distributions, StableRNGs, Random
using DataFrames, LinearAlgebra, Statistics

export run_reserve, reserve_theory, summarize_replications

const TraceRow = NamedTuple{(:time, :transition, :failed, :working,
    :spares, :busy_repairers, :repair_queue),
    Tuple{Float64, String, Int, Int, Int, Int, Int}}

mutable struct ReserveState
    required::Int
    spares_total::Int
    repairers::Int
    failed::Int
    previous_time::Float64
    busy_area::Float64
    queue_area::Float64
    trace::Vector{TraceRow}
end

function observe!(state::ReserveState, env, transition)
    time = Float64(now(env))
    duration = time-state.previous_time
    busy = min(state.failed, state.repairers)
    queue = max(state.failed-state.repairers, 0)
    state.busy_area += duration*busy
    state.queue_area += duration*queue
    state.previous_time = time
    healthy = state.required+state.spares_total-state.failed
    push!(state.trace, (time=time, transition=transition, failed=state.failed,
        working=min(state.required, healthy), spares=max(healthy-state.required, 0),
        busy_repairers=min(state.failed, state.repairers),
        repair_queue=max(state.failed-state.repairers, 0)))
end

@resumable function reserve_evolution(env::Environment, state::ReserveState,
        failure_mean::Float64, repair_mean::Float64, rng::AbstractRNG)
    observe!(state, env, "initial")
    while state.failed <= state.spares_total
        failure_rate = state.required/failure_mean
        repair_rate = min(state.failed, state.repairers)/repair_mean
        total_rate = failure_rate+repair_rate
        @yield timeout(env, rand(rng, Exponential(inv(total_rate))))
        observe!(state, env, "interval_end")
        if rand(rng) < failure_rate/total_rate
            state.failed += 1
            observe!(state, env, state.failed > state.spares_total ? "system_failure" : "machine_failure")
        else
            state.failed -= 1
            observe!(state, env, "repair_complete")
        end
    end
end

"""Simulate the Ross cold-reserve model through its equivalent CTMC state process."""
function run_reserve(; required=10, spares=3, repairers=1,
        failure_mean=100.0, repair_mean=1.0, seed=150)
    required > 0 && spares >= 0 && repairers > 0 || throw(ArgumentError("invalid counts"))
    failure_mean > 0 && repair_mean > 0 || throw(ArgumentError("positive means required"))
    state = ReserveState(required, spares, repairers, 0, 0.0, 0.0, 0.0, TraceRow[])
    env = Simulation()
    @process reserve_evolution(env, state, Float64(failure_mean), Float64(repair_mean), StableRNG(seed))
    run(env)
    failure_time = state.previous_time
    summary = (; required, spares, repairers, failure_mean=Float64(failure_mean),
        repair_mean=Float64(repair_mean), seed, failure_time,
        utilization=state.busy_area/(repairers*failure_time),
        mean_queue=state.queue_area/failure_time,
        transitions=nrow(DataFrame(state.trace))-1)
    (summary=summary, trace=DataFrame(state.trace))
end

"""Solve transient CTMC equations and reward integrals for the Ross model."""
function reserve_theory(; required=10, spares=3, repairers=1,
        failure_mean=100.0, repair_mean=1.0)
    required > 0 && spares >= 0 && repairers > 0 || throw(ArgumentError("invalid counts"))
    fail_rate = required/failure_mean
    generator = zeros(spares+1, spares+1)
    for failed in 0:spares
        repair_rate = min(failed, repairers)/repair_mean
        generator[failed+1, failed+1] = -(fail_rate+repair_rate)
        failed < spares && (generator[failed+1, failed+2] = fail_rate)
        failed > 0 && (generator[failed+1, failed] = repair_rate)
    end
    time_to_failure = -generator\ones(spares+1)
    initial = zeros(spares+1); initial[1] = 1.0
    occupation = transpose(-generator)\initial
    total = time_to_failure[1]
    busy = min.(collect(0:spares), repairers)
    queue = max.(collect(0:spares).-repairers, 0)
    (; mean_time=total,
        utilization=dot(occupation, busy)/(repairers*total),
        mean_queue=dot(occupation, queue)/total,
        residual=norm(generator*time_to_failure.+1, Inf),
        occupation=DataFrame(failed=0:spares, expected_time=occupation,
            share=occupation/total, busy_repairers=busy, repair_queue=queue))
end

function summarize_replications(rows::DataFrame)
    n = nrow(rows)
    avg = mean(rows.failure_time)
    se = std(rows.failure_time)/sqrt(n)
    (; replications=n, mean_time=avg, standard_error=se,
        ci_low=max(0.0, avg-1.96se), ci_high=avg+1.96se,
        utilization=sum(rows.busy_area)/sum(rows.capacity_time),
        mean_queue=sum(rows.queue_area)/sum(rows.failure_time))
end

end
