# AGENTS.md

This repository provides MATLAB forward solvers and inverse dispersion fitting
for Rayleigh-Lamb, mRLFE, and acoustoelastic IOP/HGO models.

## Ownership

- `src/+lamb/+models/`: forward physics, tracking, policies, quality, results.
- `src/+lamb/+fitting/`: fitting APIs, residuals, optimization, metrics.
- `src/+lamb/+elasticity/`, `+grids/`, `+sweeps/`: narrowly neutral utilities.
- `app/solver/`, `app/fitting/`: the `LambFundamental_GUI` and `FitTool_GUI`
  workflows.
- `app/execution_profiles/`: Fast/Balanced/Robust surface translation.
- `studies/`: opt-in sensitivity campaigns and solver investigations.
- `tests/`: ownership-aligned validation, runners, repository guards, tooling.

Read [architecture](docs/architecture.md), [conventions](docs/conventions.md),
and [validation](docs/validation.md) before structural work. Model-specific
contracts live under `docs/models/`.

## Non-negotiable contracts

Preserve equations, constitutive laws, branch identity/selection/tracking,
numerical presets, stopping rules, fitting semantics, result schemas, quality
thresholds, baselines, tolerances, and established performance behavior unless
scientific change is explicitly authorized.

Models do not depend on fitting, app, studies, examples, or tests. Fitting calls
canonical model APIs. Production does not depend on studies or examples. GUIs
coordinate and present; scientific owners calculate. Do not add generic shared
buckets, alternate scientific routes, speculative abstractions, or compatibility
aliases without explicit authorization. Studies and examples remain opt-in.

## Validation and delivery

Run:

```matlab
startup
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

Do not change baselines or tolerances to make structural work pass. Also run
`git diff --check` and inspect generated artifacts. Work on a review branch,
target the branch named by the task, preserve unrelated changes, and do not
merge or modify `main` without explicit authorization.
