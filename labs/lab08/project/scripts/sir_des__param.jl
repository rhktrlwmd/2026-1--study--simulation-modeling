# # Чувствительность к параметрам
# Меняется один параметр за раз. По 20 повторов, горизонт 80.
using DrWatson
@quickactivate "ContactEpidemics"
using ContactEpidemics.ContactProcesses
using ContactEpidemics.StudyTools
using DataFrames, CSV, Plots, Statistics


rows = NamedTuple[]
panels = []
for (variable,values) in [(:beta,[0.03,0.05,0.07]),
        (:contact,[6.0,10.0,14.0]),(:recovery,[0.15,0.25,0.35])]
    p = plot(xlabel="Time",ylabel="Mean I",title=string(variable))
    for value in values
        cfg = Settings(;Dict(variable=>value)...)
        result = ensemble(cfg)
        for row in eachrow(result.metrics)
            push!(rows,(;parameter=string(variable),value,
                NamedTuple(row)...))
        end
        save_table("scan_$(variable)_$(value)",result.path)
        plot!(p,result.path.t,result.path.mean_I,label=string(value))
    end
    push!(panels,p)
end
metrics = DataFrame(rows)
save_table("sensitivity_runs",metrics)
summary = combine(groupby(metrics,[:parameter,:value]),
    :peak=>mean=>:mean_peak,:time_peak=>mean=>:mean_time_peak,
    :R_T=>mean=>:mean_R_T,:I_T=>mean=>:mean_I_T)
save_table("sensitivity_summary",summary)
display(summary)
figure = plot(panels...;layout=(3,1),size=(1050,1100))
savefig(figure,imagefile("sensitivity"))
display(plot(figure; size=(780,420)))
