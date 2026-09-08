SOURCE = simulation-modeling-lab08-presentation.qmd
.PHONY: html
html:
	quarto render $(SOURCE) --to revealjs
	cp _output/simulation-modeling-lab08-presentation.html .

CHROME ?= chromium
pdf:
	@$(CHROME) --headless --no-sandbox --no-pdf-header-footer \
	  --virtual-time-budget=3000 \
	  --print-to-pdf=simulation-modeling-lab08-presentation.pdf \
	  'file://$(CURDIR)/simulation-modeling-lab08-presentation.html?print-pdf' \
	  >/dev/null 2>&1
	@test -s simulation-modeling-lab08-presentation.pdf
