SOFFICE ?= soffice
SOURCE = simulation-modeling-lab08-report.qmd
.PHONY: all docx pdf
all: docx pdf
docx:
	quarto render $(SOURCE) --to docx
	cp _output/simulation-modeling-lab08-report.docx .
pdf:
	@$(SOFFICE) --headless --convert-to pdf --outdir . \
	  simulation-modeling-lab08-report.docx >/dev/null 2>&1
	@test -s simulation-modeling-lab08-report.pdf
