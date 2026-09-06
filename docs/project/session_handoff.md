# Integration handoff

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Canonical branch: `main`
Main HEAD after final integration: `8ec03bedc1b6af541b9938f9ff37a85921c7b77b`
Historical planning branch: `planning/full-repository-restructure`

## Campaign status

The repository restructuring campaign is complete.

- Issue #130 — numerical performance/alignment campaign: complete.
- Issue #134 — final structural symmetry and contract alignment: complete.
- PR #135 — structural-symmetry implementation into planning: merged.
- PR #136 — planning/main audit documentation closeout: merged.
- PR #137 — final `planning/full-repository-restructure` -> `main`: merged.

PR #137 introduced no new implementation beyond the already validated planning
tree; it was the final integration boundary into `main`.

## Integrated structural alignment

- Common model responsibility spine across RL, mRLFE, and AE:
  `api/configuration/core/solvers/tracking/quality/results` where applicable.
- Generic frequency construction is model-neutral under
  `models/shared/configuration/buildFrequencyVector.m`.
- The only intentional cross-family scientific dependency remains
  `mrlfeBuildSeed -> rlComputeFundamentalLambModes`.
- Official result curves use column-oriented
  `frequency_Hz/phaseVelocity_mps/wavenumber_radpm/validMask`.
- Quality core fields use lower camel case.
- Public configuration uses `requested/effective`, each with
  `parameters/options`.
- Main GUI normalization routes all model families through the shared result
  view spine.
- Maintained one-dimensional sweeps use the canonical `runParametricSweep`
  structure; AE 2-D grid sweep remains specialized.
- Maintained direct tests use the normalized no-output function style and
  runners own path setup.

## Numerical behavior retained

mRLFE Fast remains:

```text
100-point coarse Cp scan
260-point rescue only when needed
selected-candidate bounded continuous refinement
```

AE retains:

```text
full discrete atlas -> minima -> linking -> atlasA0 selection
-> bounded continuous refinement on the true SVD objective
```

No restructuring step changed the protected physics, numerical selection policy,
scientific goldens, or accepted tolerances.

## Final validation

The full six-runner MATLAB gate was executed after PR #137 merged into `main`:

1. `run_repository_hygiene_tests` — 8 — PASS
2. `run_quick_contract_tests` — 17 — PASS
3. `run_quick_smoke_tests` — 29 — PASS
4. `run_numerical_regression_tests` — 17 — PASS
5. `run_extended_integration_tests` — 40 — PASS
6. `run_performance_and_benchmark_tests` — 4 — PASS

Total: 115 maintained tests, all PASS on `main`.

The local MATLAB gate is the authoritative execution evidence because the
repository does not currently have MATLAB CI/status checks.

## Handoff

`main` is now the canonical source for future development. The planning and
campaign branches are historical and may be deleted after any desired retention
period. New development should branch from `main` and preserve the contracts in
`docs/repository/`.
