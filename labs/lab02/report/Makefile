OUTPUT := _output
SOURCE := simulation-modeling-lab02-report.qmd
SOFFICE ?= soffice
FINAL_DOCX := simulation-modeling-lab02-report.docx
FINAL_PDF := simulation-modeling-lab02-report.pdf
SCENARIOS := sir_ode sir_ode__param lv_ode lv_ode__param

.PHONY: all includes docx pdf verify clean

all: docx pdf verify

includes:
	@mkdir -p _includes
	@for name in $(SCENARIOS); do \
		sed 's/^```{julia}/```julia/' ../project/markdown/$$name/$$name.qmd | \
		awk 'BEGIN { code = 0 } \
		     /^```/ { code = !code; print; next } \
		     !code && /^#### / { sub(/^#### /, "###### "); print; next } \
		     !code && /^### /  { sub(/^### /,  "##### "); print; next } \
		     !code && /^## /   { sub(/^## /,   "#### "); print; next } \
		     !code && /^# /    { sub(/^# /,    "### "); print; next } \
		     { print }' > _includes/$$name.qmd; \
	done
	@{ echo '```julia'; cat ../project/src/BasicModels.jl; echo '```'; } > _includes/BasicModels.jl.md
	@{ echo '```julia'; cat ../project/scripts/setup_environment.jl; echo '```'; } > _includes/setup_environment.jl.md
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
