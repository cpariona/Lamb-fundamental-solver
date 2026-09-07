# Validation status

> Historical post-PR-#137 snapshot. Current runner ownership and maintained
> test count are defined by `tests/README.md` and the runner files themselves.

Last reviewed: 2026-09-05.

## Current integrated state

Canonical branch: `main`
Main HEAD after PR #137: `8ec03bedc1b6af541b9938f9ff37a85921c7b77b`

The full repository restructuring and numerical-alignment campaigns are
integrated into `main`. Issues #130 and #134 are complete, and PRs #135, #136,
and #137 are merged.

## Maintained validation surface

| Tier | Direct tests | Post-main status |
| --- | ---: | --- |
| `run_repository_hygiene_tests` | 8 | PASS |
| `run_quick_contract_tests` | 17 | PASS |
| `run_quick_smoke_tests` | 29 | PASS |
| `run_numerical_regression_tests` | 17 | PASS |
| `run_extended_integration_tests` | 40 | PASS |
| `run_performance_and_benchmark_tests` | 4 | PASS |

There are 115 maintained tests and six canonical runners. The complete gate was
executed again from `main` after PR #137 merged and all tests passed.

Repository hygiene scans every tracked `test_*.m` file and enforces the
maintained test contract. The local MATLAB six-runner gate is the authoritative
execution evidence because the repository currently has no MATLAB CI/status
checks.

## Structural alignment completed

- RL, mRLFE, and AE use the common responsibility spine
  `api/configuration/core/solvers/tracking/quality/results` where applicable.
- Generic frequency construction is model-neutral under
  `src/+lamb/+grids/buildFrequencyVector.m`.
- The only intentional cross-family scientific dependency remains
  `lamb.models.mrlfe.tracking.mrlfeBuildSeed -> lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes`.
- mRLFE request translation is model-owned by
  `src/+lamb/+models/+mrlfe/+configuration/mrlfeBuildSolveRequest.m`.
- Official model curves use column-oriented `frequency_Hz`,
  `phaseVelocity_mps`, `wavenumber_radpm`, and `validMask`.
- Quality uses the common lower-camel core fields.
- Public configuration uses `requested/effective`, each split into
  `parameters/options`.
- AE one-dimensional sweep output is aligned with `runParametricSweep`; AE 2-D
  grid sweeps remain intentionally specialized.
- Main GUI model normalization uses one shared result-view spine.

## Numerical alignment retained

mRLFE Fast uses a 100-point coarse Cp scan, a 260-point rescue scan only when
candidate discovery requires it, and bounded continuous refinement of the
selected candidate. No plotting-side smoothing is used.

AE retains the protected lifecycle:

```text
SVD atlas -> discrete minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement of the selected branch on the true SVD objective
```

The rejected AE adaptive coarse/rescue density experiment did not enter
production.

## Integration status

PR #137 completed the final integration from
`planning/full-repository-restructure` into `main`. The planning tree and the
resulting `main` tree were identical apart from the merge commit, and the full
post-integration MATLAB gate passed on `main`.

No functional blocker remains from the restructuring campaign. Future work
should branch from `main` and preserve the maintained repository contracts.
