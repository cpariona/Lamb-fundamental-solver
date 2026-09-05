# Integration handoff

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Working branch: `structural-symmetry/final-alignment`
Integration base: `planning/full-repository-restructure`
Planning HEAD: `75c562bc8674974febb3c5e4e6959854575798b5`
Main HEAD: `026994f86a2d1dfe5a740034d7a5fd81d4f08235`

`main` has not been modified during Issue #134. Do not modify or merge into
`main` without explicit user authorization.

## Current campaign

Issue #134 — Final structural symmetry and contract alignment before main.

The numerical-science campaign (#130) is complete. #134 is structural only and
must not change equations, numerical strategy, branch-selection policy,
scientific goldens, or accepted tolerances.

### Completed structural alignment

- Common model responsibility spine established across RL, mRLFE, and AE:
  `api/configuration/core/solvers/tracking/quality/results` where applicable.
- RL public compute/default owners moved to `api/`; RL solver/configuration and
  quality responsibilities are separated from core/result construction.
- AE public solver moved to `api/`; generic option ownership moved to
  `configuration/`.
- Generic frequency-vector construction moved to
  `models/shared/configuration/buildFrequencyVector.m`.
- mRLFE workflow defaults are mRLFE-owned; unrelated RL default coupling is
  removed.
- `mrlfeBuildSolveRequest` is now owned by
  `models/mrlfe/configuration/`; the old `analysis/requests/mrlfe/` owner is
  removed.
- Official result curves are column-oriented and use the common
  `frequency_Hz/phaseVelocity_mps/wavenumber_radpm/validMask` contract.
- Quality core fields use lower camel case.
- Public configuration uses `requested/effective`, each with
  `parameters/options`.
- Main GUI normalization routes all three model families through the shared
  result-view spine.
- AE 1-D sweep output now retains the canonical `runParametricSweep` structure;
  AE 2-D grid sweep remains specialized.
- Maintained direct tests are no-output functions without local path bootstrap,
  `clear`, `clc`, or base-workspace scientific exports.
- The hygiene gate now scans every tracked `test_*.m`; native
  `functiontests(localfunctions)` suites remain supported where appropriate.
- mRLFE production characterization no longer returns/captures historical
  reference collections.
- Documentation has been aligned for RL/AE model ownership, mRLFE request and
  Fast preset behavior, naming, baseline status, repository structure, and
  validation architecture.

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

The rejected AE adaptive coarse/rescue density route is not production code.
The intentional cross-family dependency remains only
`mrlfeBuildSeed -> rlComputeFundamentalLambModes`.

## Validation state

There are 115 maintained tests across six canonical runners:

1. `run_repository_hygiene_tests` — 8
2. `run_quick_contract_tests` — 17
3. `run_quick_smoke_tests` — 29
4. `run_numerical_regression_tests` — 17
5. `run_extended_integration_tests` — 40
6. `run_performance_and_benchmark_tests` — 4

Repository hygiene, quick contract, quick smoke, and numerical regression have
passed on earlier heads during the campaign. Final request-ownership,
documentation, and test-architecture edits were made afterward, so a complete
six-runner revalidation is required on the current branch before opening or
merging the structural PR.

## Next action

From an up-to-date local checkout of `structural-symmetry/final-alignment`, run:

```matlab
startup
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

If all six pass:

1. review the final branch diff against `planning/full-repository-restructure`;
2. open the PR from `structural-symmetry/final-alignment` to planning;
3. merge into planning only after the validated diff is confirmed;
4. perform a separate planning-versus-main audit;
5. do not merge planning into `main` without explicit user authorization.
