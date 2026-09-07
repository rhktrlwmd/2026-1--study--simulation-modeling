JULIA ?= julia
SOURCES = scripts/queue_baseline.jl scripts/queue_load_study.jl scripts/reserve_baseline.jl scripts/repair_capacity_study.jl

.PHONY: setup run tangle notebooks docs test verify all clean-results

setup:
	$(JULIA) --project=. scripts/setup_environment.jl

run:
	@for source in $(SOURCES); do $(JULIA) --project=. $$source || exit $$?; done

tangle:
	$(JULIA) --project=. scripts/tangle.jl $(SOURCES)

notebooks:
	$(JULIA) --project=. scripts/tangle.jl --execute $(SOURCES)

docs:
	@for source in $(SOURCES); do name=$$(basename $$source .jl); \
		(cd notebooks/$$name && quarto render $$name.ipynb --to html --embed-resources --no-execute --output $$name.html) || exit $$?; \
		mv notebooks/$$name/$$name.html markdown/$$name/$$name.html; done

test:
	$(JULIA) --project=. test/runtests.jl

verify:
	@test $$(find scripts -mindepth 2 -maxdepth 2 -name '*.jl' | wc -l | tr -d ' ') = 4
	@test $$(find notebooks -mindepth 2 -maxdepth 2 -name '*.ipynb' | wc -l | tr -d ' ') = 4
	@test $$(find markdown -mindepth 2 -maxdepth 2 -name '*.qmd' | wc -l | tr -d ' ') = 8
	@test $$(find plots -type f -name '*.png' | wc -l | tr -d ' ') -ge 4
	@echo "lab07 artifact verification passed"

all: run notebooks docs test verify

clean-results:
	rm -rf data plots notebooks markdown
