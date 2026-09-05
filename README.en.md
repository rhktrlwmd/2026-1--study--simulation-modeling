# Simulation Modeling

Course repository for “Simulation Modeling”.

**Author:** Zarina Ismayilbekovna Isaeva  
**Student ID:** 1132232882

The repository layout was generated from the
[`yamadharma/course-directory-student-template`](https://github.com/yamadharma/course-directory-student-template)
with `make prepare`. It contains eight laboratory directories; laboratory 01 is
completed and the remaining directories retain the course scaffold.

## Reproduce laboratory 01

```bash
git clone --recursive git@github.com:rhktrlwmd/2026-1--study--simulation-modeling.git
cd 2026-1--study--simulation-modeling/labs/lab01/project
julia --project=. -e 'using Pkg; Pkg.instantiate()'
make all
```

The report is stored in `labs/lab01/report`, the presentation in
`labs/lab01/presentation`, and the computational project in
`labs/lab01/project`.
