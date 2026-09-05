.PHONY: setup tangle run notebooks docs test all clean-results

SOURCES = scripts/sir_ode.jl scripts/sir_ode__param.jl scripts/lv_ode.jl scripts/lv_ode__param.jl

setup:
	julia --project=. scripts/setup_environment.jl

tangle:
	julia --project=. scripts/tangle.jl $(SOURCES)

run:
	julia --project=. scripts/sir_ode.jl
	julia --project=. scripts/sir_ode__param.jl
	julia --project=. scripts/lv_ode.jl
	julia --project=. scripts/lv_ode__param.jl

notebooks:
	for notebook in notebooks/*/*.ipynb; do \
		jupyter nbconvert --to notebook --execute --inplace \
			--ExecutePreprocessor.kernel_name=julia-lab02-1.11 \
			--ExecutePreprocessor.timeout=900 "$$notebook"; \
	done

docs:
	for document in markdown/*/*.qmd; do \
		quarto render "$$document" --to html --embed-resources; \
	done

test:
	julia --project=. test/runtests.jl

all: tangle run notebooks docs test

clean-results:
	rm -rf data/sir_ode data/sir_ode__param data/lv_ode data/lv_ode__param
	rm -rf plots/sir_ode plots/sir_ode__param plots/lv_ode plots/lv_ode__param
	rm -rf notebooks/sir_ode notebooks/sir_ode__param notebooks/lv_ode notebooks/lv_ode__param
	rm -rf markdown/sir_ode markdown/sir_ode__param markdown/lv_ode markdown/lv_ode__param
