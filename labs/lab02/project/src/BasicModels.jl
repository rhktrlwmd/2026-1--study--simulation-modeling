module BasicModels

using DifferentialEquations
using DataFrames
using Statistics

export sir_rhs!, lotka_volterra_rhs!, solve_sir, solve_lv,
       sir_dataframe, lv_dataframe, first_local_peak, invariant_lv

function sir_rhs!(du, u, p, _t)
    S, I, R = u
    beta, contacts, gamma = p
    N = S + I + R
    infection = beta * contacts * I * S / N
    @inbounds begin
        du[1] = -infection
        du[2] = infection - gamma * I
        du[3] = gamma * I
    end
    return nothing
end

function solve_sir(; u0=[990.0, 10.0, 0.0], p=[0.05, 10.0, 0.25],
                   tspan=(0.0, 40.0), saveat=0.1)
    problem = ODEProblem(sir_rhs!, Float64.(u0), tspan, Float64.(p))
    return solve(problem, Tsit5(); saveat, reltol=1e-9, abstol=1e-11)
end

function sir_dataframe(solution)
    values = reduce(hcat, solution.u)'
    frame = DataFrame(t=solution.t, S=values[:, 1], I=values[:, 2], R=values[:, 3])
    frame.N = frame.S + frame.I + frame.R
    return frame
end

function lotka_volterra_rhs!(du, u, p, _t)
    prey, predator = u
    alpha, beta, delta, gamma = p
    @inbounds begin
        du[1] = alpha * prey - beta * prey * predator
        du[2] = delta * prey * predator - gamma * predator
    end
    return nothing
end

function solve_lv(; u0=[40.0, 9.0], p=[0.1, 0.02, 0.01, 0.3],
                  tspan=(0.0, 200.0), saveat=0.1)
    problem = ODEProblem(lotka_volterra_rhs!, Float64.(u0), tspan, Float64.(p))
    return solve(problem, Tsit5(); saveat, reltol=1e-8, abstol=1e-10)
end

function lv_dataframe(solution, p)
    values = reduce(hcat, solution.u)'
    alpha, beta, delta, gamma = p
    frame = DataFrame(t=solution.t, prey=values[:, 1], predator=values[:, 2])
    frame.dprey_dt = alpha .* frame.prey .- beta .* frame.prey .* frame.predator
    frame.dpredator_dt = delta .* frame.prey .* frame.predator .- gamma .* frame.predator
    frame.prey_pct_change = 100 .* frame.dprey_dt ./ frame.prey
    frame.predator_pct_change = 100 .* frame.dpredator_dt ./ frame.predator
    return frame
end

function first_local_peak(signal, time; start_index=2)
    for index in max(start_index, 2):(length(signal) - 1)
        if signal[index] > signal[index - 1] && signal[index] > signal[index + 1]
            return (time=time[index], value=signal[index], index=index)
        end
    end
    return (time=NaN, value=NaN, index=0)
end

function invariant_lv(prey, predator, p)
    alpha, beta, delta, gamma = p
    return delta .* prey .- gamma .* log.(prey) .+ beta .* predator .- alpha .* log.(predator)
end

end
