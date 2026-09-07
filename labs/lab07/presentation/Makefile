OUTPUT := _output
SOURCE := simulation-modeling-lab07-presentation.qmd
FINAL_PDF := simulation-modeling-lab07-presentation.pdf

.PHONY: all html pdf verify clean

all: html pdf verify

html:
	quarto render $(SOURCE) --to revealjs
	cp $(OUTPUT)/simulation-modeling-lab07-presentation.html .

pdf:
	quarto render $(SOURCE) --to beamer
	cp $(OUTPUT)/$(FINAL_PDF) $(FINAL_PDF)

verify:
	@test -s simulation-modeling-lab07-presentation.html
	@test -s $(FINAL_PDF)

clean:
	rm -rf $(OUTPUT) .quarto simulation-modeling-lab07-presentation.html simulation-modeling-lab07-presentation.pdf
