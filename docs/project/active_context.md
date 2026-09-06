# Active project context

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Canonical branch: `main`
Main HEAD after PR #137: `8ec03bedc1b6af541b9938f9ff37a85921c7b77b`
Historical integration branch: `planning/full-repository-restructure`

## Current state

The full repository restructuring is complete and integrated into `main` through
PR #137 (`planning/full-repository-restructure` -> `main`). The post-integration
MATLAB validation was run directly from `main` and all six canonical runners
passed.

Issues #130 and #134 are complete. No functional blocker remains from the
restructuring campaign.

## Architecture

Models own physics, tracking, model request/configuration semantics, quality, and
scientific results. Analysis owns fitting, sweeps, plotting, IO, and diagnostic
interpretation. App owns human-surface state, request/view adaptation, and
presentation.

RL, mRLFE, and AE use the common responsibility spine where applicable:

```text
api / configuration / core / solvers / tracking / quality / results
```

Scientific family-specific directories remain explicit (`equations`,
`approximations`, `constitutive`, model policies/diagnostics where justified).
Generic infrastructure used across families is neutral. The only intentional
cross-family scientific dependency is:

```text
mRLFE seed -> Rayleigh-Lamb solver
```

## Shared contracts

Official dispersion curves use column-oriented:

```text
frequency_Hz
phaseVelocity_mps
wavenumber_radpm
validMask
```

Quality core fields are lower-camel `pointCount`, `validCount`,
`validFraction`, `accepted`, and `reason`. Public configuration is
`requested/effective`, each split into `parameters/options`.

All maintained one-dimensional sweeps retain the `runParametricSweep` primary
shape. AE 2-D grid sweeps remain intentionally specialized. Main GUI result
normalization uses the shared model-result view spine.

## Numerical alignment status

Issue #130 is complete. mRLFE Fast uses a 100-point coarse Cp scan, 260-point
dense rescue only when needed, and bounded continuous refinement of the selected
candidate. No plotting-side smoothing is used.

AE retains full discrete atlas construction and atlasA0 selection followed by
bounded continuous refinement on the true SVD objective. The rejected adaptive
coarse/rescue density strategy did not enter production.

## Validation state

There are 115 maintained tests across exactly six canonical runners:

1. `run_repository_hygiene_tests` — 8 — PASS
2. `run_quick_contract_tests` — 17 — PASS
3. `run_quick_smoke_tests` — 29 — PASS
4. `run_numerical_regression_tests` — 17 — PASS
5. `run_extended_integration_tests` — 40 — PASS
6. `run_performance_and_benchmark_tests` — 4 — PASS

The full six-runner gate was executed again after PR #137 merged and passed on
`main` at `8ec03bedc1b6af541b9938f9ff37a85921c7b77b`.

GitHub does not provide MATLAB CI for this repository; the local six-runner gate
is the authoritative execution evidence.

## Next development

The restructuring campaign is closed. New work should branch from `main` and
follow the maintained repository contracts documented under `docs/repository/`.
