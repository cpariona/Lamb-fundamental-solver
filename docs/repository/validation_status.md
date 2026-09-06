# Validation status

Last reviewed: 2026-09-05.

## Current integrated state

Integration branch: `planning/full-repository-restructure` at
`b925cfc2ad6d1c29b75812141c84f16ee705baa2` after merge of PR #135.
Final audit branch: `audit/planning-main-readiness`.
`main` remains untouched at `026994f86a2d1dfe5a740034d7a5fd81d4f08235`.

Issue #134 completed the final structural-symmetry campaign. The implementation
is now integrated into planning. The remaining work is repository closeout and
a separate planning-versus-main integration decision; `main` must not be
modified without explicit user authorization.

## Maintained validation surface

| Tier | Direct tests | Final campaign status |
| --- | ---: | --- |
| `run_repository_hygiene_tests` | 8 | PASS |
| `run_quick_contract_tests` | 17 | PASS |
| `run_quick_smoke_tests` | 29 | PASS |
| `run_numerical_regression_tests` | 17 | PASS |
| `run_extended_integration_tests` | 40 | PASS |
| `run_performance_and_benchmark_tests` | 4 | PASS |

There are 115 maintained tests and six flat runners. Every maintained test is
owned directly by exactly one runner. Repository hygiene scans every tracked
`test_*.m` file and enforces the maintained function-test contract, with native
`functiontests(localfunctions)` suites retained only where the MATLAB unit-test
API is the actual surface.

The final validation exposed structural-only test debt and stale test
assumptions. Those were corrected without modifying production physics,
numerical policy, scientific goldens, or tolerances. After the final
SweepTool characterization-test correction, `run_extended_integration_tests`
and `run_performance_and_benchmark_tests` were rerun and passed. No production
source changed after the earlier hygiene/quick/numerical passes. PR #135 then
merged the validated tree into planning without additional source changes.

## Structural alignment completed

- RL, mRLFE, and AE use the common responsibility spine
  `api/configuration/core/solvers/tracking/quality/results` where applicable.
- The public RL and AE entry points are under `api/`.
- Generic frequency construction is model-neutral under
  `models/shared/configuration/buildFrequencyVector.m`.
- The only intentional cross-family scientific dependency remains
  `mrlfeBuildSeed -> rlComputeFundamentalLambModes`.
- mRLFE request translation is model-owned by
  `models/mrlfe/configuration/mrlfeBuildSolveRequest.m`; the old
  `analysis/requests/mrlfe/` owner is removed.
- Official model curves use column-oriented `frequency_Hz`,
  `phaseVelocity_mps`, `wavenumber_radpm`, and `validMask`.
- Quality uses the common lower-camel core fields.
- Public configuration uses `requested/effective`, each split into
  `parameters/options`.
- AE one-dimensional sweep output is aligned with `runParametricSweep`; AE 2-D
  grid sweeps remain intentionally specialized.
- Main GUI model normalization uses one shared result-view spine.
- Maintained direct tests are no-output functions without local path bootstrap,
  `clear`, `clc`, or base-workspace scientific exports.
- The mRLFE production characterization test no longer doubles as a historical
  reference-capture tool.

## Numerical alignment retained

Issue #130 remains complete. mRLFE Fast uses a 100-point coarse Cp scan, a
260-point rescue scan only when candidate discovery requires it, and bounded
continuous refinement of the selected candidate. The correction removes
scan-grid quantization without plotting-side smoothing.

AE retains the protected lifecycle:

```text
SVD atlas -> discrete minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement of the selected branch on the true SVD objective
```

The rejected AE coarse/rescue density experiment did not enter production. The
earlier mRLFE edge-guard regression remains recorded as resolved historical
evidence in `../validation/mrlfe_restructure_baseline.md`.

## Planning-versus-main audit

At the start of the final audit:

- planning HEAD: `b925cfc2ad6d1c29b75812141c84f16ee705baa2`;
- main HEAD: `026994f86a2d1dfe5a740034d7a5fd81d4f08235`;
- planning is 286 commits ahead and 0 commits behind main;
- the merge base is exactly the current main HEAD;
- no open pull requests remain after PR #135;
- GitHub reports no CI/status checks on the planning merge commit, so the
  authoritative validation evidence is the local MATLAB six-runner gate.

The detailed audit record is `planning_main_audit.md`.

## Integration status

No functional blocker was found in the final static review. After the
closeout-documentation PR is merged into planning, the repository is ready for
a final PR review from planning into `main`. Opening or merging into `main`
requires explicit user authorization; this audit does not grant it.
