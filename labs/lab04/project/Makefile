SOURCES = scripts/sir_run_basic.jl scripts/sir_run_basic__param.jl scripts/sir_scan_beta.jl scripts/sir_city_heterogeneity.jl scripts/sir_migration_effect.jl scripts/sir_quarantine.jl scripts/sir_optimize_parameters.jl scripts/sir_visualize_dynamics.jl

.PHONY: setup tangle run notebooks docs test verify all clean-results

setup:
	julia --project=. scripts/setup_environment.jl

tangle:
	julia --project=. scripts/tangle.jl $(SOURCES)

run:
	@for source in $(SOURCES); do julia --project=. $$source || exit $$?; done

notebooks:
	julia --project=. scripts/tangle.jl --execute $(SOURCES)

docs:
	@for source in $(SOURCES); do \
		name=$$(basename $$source .jl); \
		(cd notebooks/$$name && quarto render $$name.ipynb --to html --embed-resources --no-execute --output $$name.html) || exit $$?; \
		mv notebooks/$$name/$$name.html markdown/$$name/$$name.html; \
	done

test:
	julia --project=. test/runtests.jl

verify:
	@clean_scripts=$$(find scripts -mindepth 2 -maxdepth 2 -name '*.jl' | wc -l | tr -d ' '); \
	notebooks=$$(find notebooks -mindepth 2 -maxdepth 2 -name '*.ipynb' | wc -l | tr -d ' '); \
	qmd=$$(find markdown -mindepth 2 -maxdepth 2 -name '*.qmd' | wc -l | tr -d ' '); \
	html=$$(find markdown -mindepth 2 -maxdepth 2 -name '*.html' | wc -l | tr -d ' '); \
	figures=$$(find plots -type f -name '*.png' | wc -l | tr -d ' '); \
	printf 'clean Julia scripts: %s\nexecuted notebooks: %s\nQuarto documents: %s\nHTML documents: %s\nresult figures: %s\n' \
	  "$$clean_scripts" "$$notebooks" "$$qmd" "$$html" "$$figures"; \
	test "$$clean_scripts" = 8; test "$$notebooks" = 8; test "$$qmd" = 16; test "$$html" = 8; test "$$figures" -ge 10

all: run notebooks docs test verify

clean-results:
	rm -rf data plots notebooks markdown
