using DrWatson
@quickactivate "AgentSIRLab"
using DataFrames, JLD2
include(srcdir("experiment_tools.jl"))

params = (
    Ns=[1000, 1000, 1000], β_und=[0.5, 0.5, 0.5], β_det=[0.05, 0.05, 0.05],
    infection_period=14, detection_time=7, death_rate=0.02,
    reinfection_probability=0.1, Is=[0, 0, 1], seed=42,
)
model, history_rows = run_sir(; params..., n_steps=100)
trajectory = save_frame(DataFrame(history_rows), "sir-run-basic", "trajectory.csv")
metrics = DataFrame([merge(epidemic_metrics(trajectory, sum(params.Ns)),
    (R0=basic_reproduction_number(params.β_und[1], params.infection_period),))])
save_frame(metrics, "sir-run-basic", "summary.csv")
jldsave(scenario_data("sir-run-basic", "sir_basic_agent.jld2"); trajectory)
jldsave(scenario_data("sir-run-basic", "sir_basic_model.jld2"); metrics)

fig = sir_figure(trajectory; title="Базовый опыт: R₀ = $(metrics.R0[1])")
save_figure(fig, "sir-run-basic", "sir-basic-dynamics.png";
            report_name="sir-baseline-dynamics.png")
display(fig)
metrics
