using DrWatson
@quickactivate "DaisyworldLab"
include(srcdir("experiment_tools.jl"))

model = create_world(solar_luminosity=1.0, seed=165)
trajectory = save_history(history_frame(model, 1000), "daisyworld-count")

fig = count_figure(trajectory)
save_figure(fig, "daisyworld-count", "population-dynamics.png";
            report_name="baseline-population-dynamics.png")
display(fig)
summary = DataFrame([(
    final_black=last(trajectory.black),
    final_white=last(trajectory.white),
    peak_black=maximum(trajectory.black),
    peak_white=maximum(trajectory.white),
    extinction_step=extinction_time(trajectory),
)])
CSV.write(scenario_data("daisyworld-count", "summary.csv"), summary)
summary
