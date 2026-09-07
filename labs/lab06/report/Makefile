OUTPUT := _output
SOURCE := simulation-modeling-lab06-report.qmd
SOFFICE ?= soffice
FINAL_DOCX := simulation-modeling-lab06-report.docx
FINAL_PDF := simulation-modeling-lab06-report.pdf
SCENARIOS := sirpetri_run sirpetri_scan_parameters sirpetri_animate sirpetri_report sirpetri_run__param sirpetri_scan_parameters__param sirpetri_animate__param sirpetri_report__param

.PHONY: all includes docx pdf verify clean
all: docx pdf verify

includes:
	@mkdir -p _includes
	@for name in $(SCENARIOS); do cp ../project/markdown/$$name/$$name-report.qmd _includes/$$name.qmd; done
	@{ echo '```julia'; cat ../project/src/SIRPetri.jl; echo '```'; } > _includes/SIRPetri.jl.md
	@{ echo '```julia'; cat ../project/src/StudyIO.jl; echo '```'; } > _includes/StudyIO.jl.md
	@{ echo '```julia'; cat ../project/scripts/setup_environment.jl; echo '```'; } > _includes/setup-environment.jl.md
	@{ echo '```julia'; cat ../project/scripts/tangle.jl; echo '```'; } > _includes/tangle.jl.md
	@{ echo '```julia'; cat ../project/test/runtests.jl; echo '```'; } > _includes/runtests.jl.md
	@{ echo '```toml'; cat ../project/Project.toml; echo '```'; } > _includes/Project.toml.md
	@{ echo '```makefile'; cat ../project/Makefile; echo '```'; } > _includes/Makefile.md

docx: includes
	quarto render $(SOURCE) --to docx
	cp $(OUTPUT)/$(FINAL_DOCX) $(FINAL_DOCX)

pdf: docx
	$(SOFFICE) --headless --convert-to pdf --outdir $(OUTPUT) $(OUTPUT)/$(FINAL_DOCX)
	cp $(OUTPUT)/$(FINAL_PDF) $(FINAL_PDF)

verify:
	@test -s $(FINAL_DOCX)
	@test -s $(FINAL_PDF)

clean:
	rm -rf $(OUTPUT) .quarto _includes
