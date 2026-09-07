OUTPUT := _output
SOURCE := simulation-modeling-lab06-presentation.qmd
FINAL := simulation-modeling-lab06-presentation.html
FINAL_PDF := simulation-modeling-lab06-presentation.pdf
CHROME ?= /Applications/Google Chrome.app/Contents/MacOS/Google Chrome

.PHONY: all html pdf verify clean
all: html pdf verify
html:
	quarto render $(SOURCE) --to revealjs
	cp $(OUTPUT)/$(FINAL) $(FINAL)
pdf: html
	"$(CHROME)" --headless=new --disable-gpu --no-pdf-header-footer \
		--run-all-compositor-stages-before-draw --virtual-time-budget=6000 \
		--print-to-pdf="$(CURDIR)/$(FINAL_PDF)" "file://$(CURDIR)/$(FINAL)?print-pdf"
verify:
	@test -s $(FINAL)
	@test -s $(FINAL_PDF)
clean:
	rm -rf $(OUTPUT) .quarto
