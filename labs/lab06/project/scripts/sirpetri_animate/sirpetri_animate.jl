ENV["GKSwstype"] = "100"
using DataFrames, Plots
include(joinpath(dirname(Base.active_project()), "src", "SIRPetri.jl"))
include(joinpath(dirname(Base.active_project()), "src", "StudyIO.jl"))
using .SIRPetri, .StudyIO

group = "sirpetri-animation"
trajectory = deterministic_trajectory(SIRConfig(); saveat=0.2)
save_csv(group, "animation_states.csv", trajectory)

animation = @animate for frame in 1:nrow(trajectory)
    animation_plot(trajectory, frame)
end
ensure_outputs(group)
gif(animation, plot_dir(group, "sir-marking.gif"); fps=25)

selected = unique(round.(Int, range(1, nrow(trajectory), length=6)))
frames = [animation_plot(trajectory, i; title="Ключевое состояние $(i)") for i in selected]
save_plot(group, "animation-keyframes.png", plot(frames...; layout=(3, 2), size=(1200, 1350)))
save_csv(group, "animation_manifest.csv", DataFrame(
    frames=[nrow(trajectory)], step=[0.2], duration_seconds=[nrow(trajectory) / 25]))
println("Сформировано кадров: $(nrow(trajectory)); шаг времени: 0.2")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
