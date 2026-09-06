# Active project context

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Current integration branch: `planning/full-repository-restructure`
Final audit branch: `audit/planning-main-readiness`
Planning HEAD at audit start: `b925cfc2ad6d1c29b75812141c84f16ee705baa2`
Main HEAD: `026994f86a2d1dfe5a740034d7a5fd81d4f08235`

`main` remains untouched and requires explicit user authorization for any
integration.

## Architecture

Issue #134 completed the final structural-alignment campaign and PR #135 merged
that work into planning. Models own physics, tracking, model request/configuration
semantics, quality, and scientific results. Analysis owns fitting, sweeps,
plotting, IO, and diagnostic interpretation. App owns human-surface state,
request/view adaptation, and presentation.

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

`mrlfeBuildSolveRequest` is model-owned under
`models/mrlfe/configuration/`; workflow/app aliases are translated there into
the canonical unit-qualified mRLFE request.

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

RL may expose A0/S0 under `modes`; mRLFE and AE currently expose one selected
public branch per solve. This containment difference is scientific and does not
change the common curve contract.

All maintained one-dimensional sweeps retain the `runParametricSweep` primary
shape. AE 2-D grid sweeps remain intentionally specialized. Main GUI result
normalization uses the shared model-result view spine.

## Numerical alignment status

Issue #130 is complete and remains scientifically unchanged by #134.

mRLFE Fast uses a 100-point coarse Cp scan, 260-point dense rescue only when
needed, and bounded continuous refinement of the selected candidate. No
plotting-side smoothing is used.

AE retains full discrete atlas construction and atlasA0 selection followed by
bounded continuous refinement on the true SVD objective. The rejected adaptive
coarse/rescue density strategy did not enter production.

## Validation architecture

There are 115 maintained tests across exactly six canonical runners. Direct
tests are no-output functions without local path setup, `clear`, `clc`, or
base-workspace scientific exports. Native `functiontests(localfunctions)` suites
remain only where MATLAB unit-test semantics are required.

Repository hygiene checks every tracked `test_*.m` file, not only quick-tier
tests. Historical numerical reference capture is documentation/diagnostic
evidence, not a maintained test responsibility.

## Current validation state

All six canonical runners passed on the final structural tree. The final
SweepTool test correction changed only a stale test assumption; extended
integration and performance/benchmark were rerun afterward and passed. PR #135
then merged the validated tree into planning without additional production
source changes.

GitHub has no CI/status checks attached to the planning merge commit, so the
local MATLAB six-runner gate is the authoritative validation evidence.

## Planning-versus-main audit

The final static comparison shows planning 286 commits ahead and 0 commits
behind `main`; the merge base is exactly the current main HEAD. There is no
history divergence and no open PR remains after #135.

A static review of startup/path ownership, maintained entrypoints, public APIs,
repository root layout, and validation architecture found no functional
blocker. The only post-merge debt was stale project-status documentation, now
corrected on `audit/planning-main-readiness`.

See `../repository/planning_main_audit.md`.

## Immediate next step

Merge the docs-only audit closeout into planning. After that, planning is ready
for a final PR review against `main`, but opening or merging into `main` requires
explicit user authorization.
