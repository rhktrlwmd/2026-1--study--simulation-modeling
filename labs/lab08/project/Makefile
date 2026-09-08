JULIA ?= julia
SCENARIOS = sir_des sir_des__param sir_duration sir_benchmark \
    sir_csv_report sir_demography sir_vaccination \
    sir_seir sir_compare_ode
.PHONY: setup run tangle notebooks docs test all
setup:
	$(JULIA) --project=. scripts/setup_environment.jl
run:
	@for name in $(SCENARIOS); do $(JULIA) --project=. scripts/$$name.jl || exit $$?; done
tangle:
	$(JULIA) --project=. scripts/tangle.jl
notebooks:
	$(JULIA) --project=. scripts/tangle.jl --execute
docs:
	@for name in $(SCENARIOS); do \
	  (cd notebooks/$$name && quarto render $$name.ipynb --to html \
	    --embed-resources --no-execute --output $$name.html) || exit $$?; \
	  mv notebooks/$$name/$$name.html markdown/$$name/; \
	done
test:
	$(JULIA) --project=. test/runtests.jl
all: setup run notebooks docs test
