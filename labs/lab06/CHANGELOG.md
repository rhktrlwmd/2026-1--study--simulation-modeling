# Changelog

## [6.0.0] — 2026-09-07

### Added
- SIR model as a true `AlgebraicPetri.LabelledPetriNet`.
- Deterministic ODE and direct Gillespie simulations for the required parameters.
- Fifteen-point beta scan, 501-state animation, and CSV-only report stage.
- Four independent parameter studies, executed notebooks, Quarto documents, tests.
- Russian report and presentation in PDF-ready source formats.

### Fixed
- Replaced the duplicated scan from the animation example with a real GIF workflow.
- Compared SSA and ODE at native SSA event times.
- Evaluated the early peak on a refined grid and checked it analytically.
- Used the correct threshold for the non-normalized mass-action law.

### Verified
- Eight invariant and numerical checks pass in Julia 1.11.9.
- All eight notebooks contain executed code cells and stored output.
- The report has 21 A4 pages; the presentation has 37 slides.
- No clean script is byte-identical to the current public reference project.
