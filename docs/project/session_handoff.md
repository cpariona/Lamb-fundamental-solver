# Integration handoff

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Current integration branch: `planning/full-repository-restructure`
Final audit branch: `audit/planning-main-readiness`
Planning HEAD at audit start: `b925cfc2ad6d1c29b75812141c84f16ee705baa2`
Main HEAD: `026994f86a2d1dfe5a740034d7a5fd81d4f08235`

`main` has not been modified during Issue #134 or the final audit. Do not modify
or merge into `main` without explicit user authorization.

## Completed campaign

Issue #134 — Final structural symmetry and contract alignment before main.

PR #135 (`structural-symmetry/final-alignment` ->
`planning/full-repository-restructure`) was merged on 2026-09-05. The validated
structural tree is therefore integrated into planning.

The numerical-science campaign (#130) remains complete. #134 was structural
only and did not change equations, numerical strategy, branch-selection policy,
scientific goldens, or accepted tolerances.

### Integrated structural alignment

- Common model responsibility spine across RL, mRLFE, and AE:
  `api/configuration/core/solvers/tracking/quality/results` where applicable.
- RL public compute/default owners are under `api/`; solver/configuration/quality
  responsibilities are separated from core/result construction.
- AE public solver is under `api/`; generic option ownership is under
  `configuration/`.
- Generic frequency-vector construction is under
  `models/shared/configuration/buildFrequencyVector.m`.
- mRLFE workflow defaults and request translation are model-owned; the old
  `analysis/requests/mrlfe/` request owner is removed.
- Official result curves are column-oriented and use the common
  `frequency_Hz/phaseVelocity_mps/wavenumber_radpm/validMask` contract.
- Quality core fields use lower camel case.
- Public configuration uses `requested/effective`, each with
  `parameters/options`.
- Main GUI normalization routes all three model families through the shared
  result-view spine.
- AE 1-D sweep output retains the canonical `runParametricSweep` structure; AE
  2-D grid sweep remains specialized.
- Maintained direct tests are no-output functions without local path bootstrap,
  `clear`, `clc`, or base-workspace scientific exports.
- Repository hygiene scans every tracked `test_*.m`; native
  `functiontests(localfunctions)` suites remain supported where appropriate.
- mRLFE production characterization no longer returns/captures historical
  reference collections.

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

1. `run_repository_hygiene_tests` — 8 — PASS
2. `run_quick_contract_tests` — 17 — PASS
3. `run_quick_smoke_tests` — 29 — PASS
4. `run_numerical_regression_tests` — 17 — PASS
5. `run_extended_integration_tests` — 40 — PASS
6. `run_performance_and_benchmark_tests` — 4 — PASS

The final validation exposed only stale test architecture/contract assumptions.
They were corrected without changing production physics, numerical policy,
scientific goldens, or tolerances. After the final SweepTool characterization
test correction, extended integration and performance/benchmark were rerun and
passed; no production source changed after the earlier hygiene/quick/numerical
passes. PR #135 merged this validated state into planning without additional
source changes.

## Final planning-versus-main audit

At audit start:

```text
planning HEAD = b925cfc2ad6d1c29b75812141c84f16ee705baa2
main HEAD     = 026994f86a2d1dfe5a740034d7a5fd81d4f08235
planning      = 286 commits ahead, 0 behind main
merge base    = current main HEAD
```

No open PRs remain. The static review of repository root, startup/path policy,
maintained entrypoints, public APIs, and validation architecture found no
functional blocker. The only post-merge issue was stale campaign-status text,
which is corrected on `audit/planning-main-readiness`.

GitHub reports no CI/status checks on the planning merge commit; the MATLAB
six-runner gate executed locally remains the authoritative validation evidence.

See `../repository/planning_main_audit.md` for the audit record.

## Next action

1. merge the docs-only closeout PR from `audit/planning-main-readiness` into
   `planning/full-repository-restructure`;
2. optionally rerun `run_repository_hygiene_tests` because the closeout changes
   documentation only;
3. review/open the final planning-to-main PR only with explicit user
   authorization;
4. never merge into `main` without that authorization.
