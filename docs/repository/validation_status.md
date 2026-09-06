# Validation status

Last reviewed: 2026-09-05.

## Current working state

Working branch: `structural-symmetry/final-alignment`.
Base integration branch: `planning/full-repository-restructure` at
`75c562bc8674974febb3c5e4e6959854575798b5`.
`main` remains untouched at `026994f86a2d1dfe5a740034d7a5fd81d4f08235`.

Issue #134 is the final structural-symmetry campaign before the planning-versus-main audit. It aligns model-family ownership, public/result/configuration contracts, one-dimensional sweep shape, GUI normalization, maintained-test architecture, and documentation without changing model physics, numerical strategy, scientific goldens, or tolerances.

## Maintained validation surface

| Tier | Direct tests | Final campaign status |
| --- | ---: | --- |
| `run_repository_hygiene_tests` | 8 | PASS |
| `run_quick_contract_tests` | 17 | PASS |
| `run_quick_smoke_tests` | 29 | PASS |
| `run_numerical_regression_tests` | 17 | PASS |
| `run_extended_integration_tests` | 40 | PASS |
| `run_performance_and_benchmark_tests` | 4 | PASS |

There are 115 maintained tests and six flat runners. Every maintained test is owned directly by exactly one runner. Repository hygiene scans every tracked `test_*.m` file and enforces the maintained function-test contract, with native `functiontests(localfunctions)` suites retained only where the MATLAB unit-test API is the actual surface.

The final validation sequence exposed structural-only test debt and stale test assumptions. Those were corrected without modifying production physics or numerical policy. After the final sweep-characterization test correction, `run_extended_integration_tests` and `run_performance_and_benchmark_tests` were rerun and passed. No production source changed after the earlier hygiene/quick/numerical passes.

## Structural alignment completed

- RL, mRLFE, and AE use the common responsibility spine `api/configuration/core/solvers/tracking/quality/results` where applicable.
- The public RL and AE entry points are under `api/`.
- Generic frequency construction is model-neutral under `models/shared/configuration/buildFrequencyVector.m`.
- The only intentional cross-family scientific dependency remains `mrlfeBuildSeed -> rlComputeFundamentalLambModes`.
- mRLFE request translation is model-owned by `models/mrlfe/configuration/mrlfeBuildSolveRequest.m`; the old `analysis/requests/mrlfe/` owner is removed.
- Official model curves use column-oriented `frequency_Hz`, `phaseVelocity_mps`, `wavenumber_radpm`, and `validMask`.
- Quality uses the common lower-camel core fields.
- Public configuration uses `requested/effective`, each split into `parameters/options`.
- AE one-dimensional sweep output is aligned with `runParametricSweep`; AE 2-D grid sweeps remain intentionally specialized.
- Main GUI model normalization uses one shared result-view spine.
- Maintained direct tests are no-output functions without local path bootstrap, `clear`, `clc`, or base-workspace scientific exports.
- The mRLFE production characterization test no longer doubles as a historical reference-capture tool.

## Numerical alignment retained

Issue #130 remains complete. mRLFE Fast uses a 100-point coarse Cp scan, a 260-point rescue scan only when candidate discovery requires it, and bounded continuous refinement of the selected candidate. The correction removes scan-grid quantization without plotting-side smoothing.

AE retains the protected lifecycle:

```text
SVD atlas -> discrete minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement of the selected branch on the true SVD objective
```

The rejected AE coarse/rescue density experiment did not enter production. The earlier mRLFE edge-guard regression is recorded as resolved historical evidence in `../validation/mrlfe_restructure_baseline.md`.

## Integration status

The structural branch is ready for review against `planning/full-repository-restructure`. The next repository step is a PR from `structural-symmetry/final-alignment` into planning. `main` must remain unchanged until a separate planning-versus-main audit is complete and the user explicitly authorizes integration into `main`.
