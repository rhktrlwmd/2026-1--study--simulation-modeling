SOURCES = scripts/dining_philosophers.jl \
          scripts/dining_philosophers_animation.jl \
          scripts/dining_philosophers_report.jl \
          scripts/dining_philosophers__param.jl

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
		(cd notebooks/$$name && quarto render $$name.ipynb --to html \
		 --embed-resources --no-execute --output $$name.html) || exit $$?; \
		mv notebooks/$$name/$$name.html markdown/$$name/$$name.html; \
	done

test:
	julia --project=. test/runtests.jl

verify:
	@clean=$$(find scripts -mindepth 2 -maxdepth 2 -name '*.jl' | wc -l | tr -d ' '); \
	notebooks=$$(find notebooks -mindepth 2 -maxdepth 2 -name '*.ipynb' | wc -l | tr -d ' '); \
	qmd=$$(find markdown -mindepth 2 -maxdepth 2 -name '*.qmd' | wc -l | tr -d ' '); \
	html=$$(find markdown -mindepth 2 -maxdepth 2 -name '*.html' | wc -l | tr -d ' '); \
	printf 'clean Julia scripts: %s\nexecuted notebooks: %s\nQuarto documents: %s\nHTML documents: %s\n' \
	  "$$clean" "$$notebooks" "$$qmd" "$$html"; \
	test "$$clean" = 4; test "$$notebooks" = 4; test "$$qmd" = 8; test "$$html" = 4; \
	test -s data/dining_classic.csv; test -s data/dining_arbiter.csv; \
	test -s plots/classic_simulation.png; test -s plots/arbiter_simulation.png; \
	test -s plots/philosophers_simulation.gif; test -s plots/final_report.png; \
	test -s plots/parameter_series.png

all: run notebooks docs test verify

clean-results:
	rm -rf data plots notebooks markdown
