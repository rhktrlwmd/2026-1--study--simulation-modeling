using DrWatson
@quickactivate "ContactEpidemics"
using ContactEpidemics.ContactProcesses
using ContactEpidemics.StudyTools
using DataFrames, CSV, Plots, Statistics


m = simulate()
@assert check_balance(m)
save_run(m)
display(DataFrame([run_metrics(m)]))

figure = draw_states(m,"baseline";title="SIR: beta=0.05, c=10, gamma=0.25")
display(plot(figure; size=(780,420)))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
