SOURCES = scripts/daisyworld.jl scripts/daisyworld-animate.jl scripts/daisyworld-count.jl scripts/daisyworld-luminosity.jl scripts/daisyworld__param.jl scripts/daisyworld-count__param.jl scripts/daisyworld-luminosity__param.jl

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
	figures=$$(find plots -type f \( -name '*.png' -o -name '*.mp4' \) | wc -l | tr -d ' '); \
	printf 'clean Julia scripts: %s\nexecuted notebooks: %s\nQuarto documents: %s\nHTML documents: %s\nresult figures and animation: %s\n' \
	  "$$clean_scripts" "$$notebooks" "$$qmd" "$$html" "$$figures"; \
	test "$$clean_scripts" = 7; test "$$notebooks" = 7; test "$$qmd" = 14; test "$$html" = 7; test "$$figures" = 22

all: run notebooks docs test verify

clean-results:
	rm -rf data plots notebooks markdown
