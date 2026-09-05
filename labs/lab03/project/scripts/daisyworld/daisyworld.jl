using DrWatson
@quickactivate "DaisyworldLab"
include(srcdir("experiment_tools.jl"))

model = create_world(seed=165)
rows = NamedTuple[]
for target in (0, 5, 45)
    advance!(model, target - model.tick)
    push!(rows, observe(model))
    fig = snapshot_figure(model)
    save_figure(
        fig, "daisyworld", "step-$(lpad(target, 3, '0')).png";
        report_name="baseline-step-$(lpad(target, 3, '0')).png",
    )
    display(fig)
end

summary = DataFrame(rows)
CSV.write(scenario_data("daisyworld", "snapshots.csv"), summary)
summary
