# Integration handoff

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Working branch: `structural-symmetry/final-alignment`
Integration base: `planning/full-repository-restructure`
Planning HEAD: `75c562bc8674974febb3c5e4e6959854575798b5`
Main HEAD: `026994f86a2d1dfe5a740034d7a5fd81d4f08235`

`main` has not been modified during Issue #134. Do not modify or merge into `main` without explicit user authorization.

## Current campaign

Issue #134 — Final structural symmetry and contract alignment before main.

The numerical-science campaign (#130) is complete. #134 is structural only and does not change equations, numerical strategy, branch-selection policy, scientific goldens, or accepted tolerances.

### Completed structural alignment

- Common model responsibility spine across RL, mRLFE, and AE: `api/configuration/core/solvers/tracking/quality/results` where applicable.
- RL public compute/default owners moved to `api/`; solver/configuration/quality responsibilities separated from core/result construction.
- AE public solver moved to `api/`; generic option ownership moved to `configuration/`.
- Generic frequency-vector construction moved to `models/shared/configuration/buildFrequencyVector.m`.
- mRLFE workflow defaults and request translation are model-owned; the old `analysis/requests/mrlfe/` request owner is removed.
- Official result curves are column-oriented and use the common `frequency_Hz/phaseVelocity_mps/wavenumber_radpm/validMask` contract.
- Quality core fields use lower camel case.
- Public configuration uses `requested/effective`, each with `parameters/options`.
- Main GUI normalization routes all three model families through the shared result-view spine.
- AE 1-D sweep output retains the canonical `runParametricSweep` structure; AE 2-D grid sweep remains specialized.
- Maintained direct tests are no-output functions without local path bootstrap, `clear`, `clc`, or base-workspace scientific exports.
- Repository hygiene scans every tracked `test_*.m`; native `functiontests(localfunctions)` suites remain supported where appropriate.
- mRLFE production characterization no longer returns/captures historical reference collections.
- Documentation is aligned for RL/AE ownership, mRLFE request and Fast preset behavior, naming, baseline status, repository structure, and validation architecture.

### Numerical behavior retained

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

The rejected AE adaptive coarse/rescue density route is not production code. The intentional cross-family dependency remains only `mrlfeBuildSeed -> rlComputeFundamentalLambModes`.

## Validation state

There are 115 maintained tests across six canonical runners:

1. `run_repository_hygiene_tests` — 8 — PASS
2. `run_quick_contract_tests` — 17 — PASS
3. `run_quick_smoke_tests` — 29 — PASS
4. `run_numerical_regression_tests` — 17 — PASS
5. `run_extended_integration_tests` — 40 — PASS
6. `run_performance_and_benchmark_tests` — 4 — PASS

The final validation exposed only stale test architecture/contract assumptions. They were corrected without changing production physics, numerical policy, scientific goldens, or tolerances. After the final SweepTool characterization test correction, extended integration and performance/benchmark were rerun and passed; no production source changed after the earlier hygiene/quick/numerical passes.

## Next action

The structural branch is ready for PR review into `planning/full-repository-restructure`.

After that PR is reviewed and merged into planning:

1. perform a separate planning-versus-main audit;
2. confirm the final integrated repository state;
3. do not merge planning into `main` without explicit user authorization.
