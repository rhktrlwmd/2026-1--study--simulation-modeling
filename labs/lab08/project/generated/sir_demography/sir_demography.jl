using DrWatson
@quickactivate "ContactEpidemics"
using ContactEpidemics.ContactProcesses
using ContactEpidemics.StudyTools
using DataFrames, CSV, Plots, Statistics


cfg = Settings(mortality=0.01,births=10.0)
m = simulate(config=cfg,T=400.0)
@assert check_balance(m)
save_run(m;label="demography",T=400.0)
data = table(m)
summary = DataFrame([(;run_metrics(m)...,births=last(data.B),
    deaths=last(data.D),endemic_S=1000*(0.25+0.01)/0.5,
    endemic_I=0.01*(1000-520)/(0.25+0.01))])
save_table("demography",summary)
display(summary)
figure = draw_states(m,"demography";title="Births=10, mortality=0.01")
display(plot(figure; size=(780,420)))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
