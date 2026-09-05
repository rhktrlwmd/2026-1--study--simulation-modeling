using DrWatson
@quickactivate "DaisyworldLab"
include(srcdir("experiment_tools.jl"))

living = create_world(scenario=:ramp, seed=165)
control = create_world(scenario=:ramp, init_white=0.0, init_black=0.0, seed=165)
trajectory = history_frame(living, 1000)
control_trajectory = history_frame(control, 1000)
trajectory.control_temperature = control_trajectory.temperature
trajectory.temperature_advantage = abs.(control_trajectory.temperature .- 22.5) .-
                                   abs.(trajectory.temperature .- 22.5)
save_history(trajectory, "daisyworld-luminosity")

fig = dynamics_figure(trajectory)
save_figure(fig, "daisyworld-luminosity", "coupled-dynamics.png";
            report_name="luminosity-feedback-dynamics.png")
display(fig)

comparison = Figure(size=(1000, 570))
axis = Axis(comparison[1, 1], title="Температура живого мира и безжизненного контроля",
            xlabel="Модельный шаг", ylabel="Температура, °C")
lines!(axis, trajectory.time, trajectory.temperature; color=:darkgreen, label="Daisyworld")
lines!(axis, trajectory.time, trajectory.control_temperature; color=:gray35,
       linestyle=:dash, label="Без маргариток")
axislegend(axis; position=:lt)
save_figure(comparison, "daisyworld-luminosity", "biotic-vs-abiotic.png";
            report_name="biotic-abiotic-temperature.png")
display(comparison)
trajectory[[1, 201, 401, 501, 751, 1001], :]
