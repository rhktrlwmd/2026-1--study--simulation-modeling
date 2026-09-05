OUTPUT := _output
SOURCE := simulation-modeling-lab01-report.qmd
SOFFICE ?= soffice
FINAL_DOCX := simulation-modeling-lab01-report.docx
FINAL_PDF := simulation-modeling-lab01-report.pdf

.PHONY: all includes docx pdf verify clean

all: docx pdf verify

includes:
	@mkdir -p _includes
	@sed 's/^```{julia}/```julia/' \
		../project/markdown/01_exponential_growth/01_exponential_growth.qmd \
		> _includes/01_exponential_growth.qmd
	@sed 's/^```{julia}/```julia/' \
		../project/markdown/02_exponential_growth/02_exponential_growth.qmd \
		> _includes/02_exponential_growth.qmd

docx: includes
	quarto render $(SOURCE) --to docx
	cp $(OUTPUT)/$(FINAL_DOCX) $(FINAL_DOCX)

pdf: docx
	$(SOFFICE) --headless --convert-to pdf --outdir $(OUTPUT) \
		$(OUTPUT)/$(FINAL_DOCX)
	cp $(OUTPUT)/$(FINAL_PDF) $(FINAL_PDF)

verify:
	@test -s $(FINAL_DOCX)
	@test -s $(FINAL_PDF)

clean:
	rm -rf $(OUTPUT) .quarto _includes
