# Active project context

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Working branch: `structural-symmetry/final-alignment`
Integration base: `planning/full-repository-restructure` at
`75c562bc8674974febb3c5e4e6959854575798b5`.
`main` remains untouched and requires explicit user authorization for any
integration.

## Architecture

Issue #134 is the active final structural-alignment campaign. Models own
physics, tracking, model request/configuration semantics, quality, and
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

Repository hygiene, quick contract, quick smoke, and numerical regression have
passed during this campaign on earlier structural heads. Additional final
structural edits were subsequently made (request ownership, documentation, and
test-architecture cleanup), so all six canonical runners must be re-run on the
current head before the structural PR is opened/merged.

## Immediate next step

Run the complete six-tier gate on `structural-symmetry/final-alignment`. If all
six pass, review the final diff against planning and open the structural PR into
`planning/full-repository-restructure`. Do not modify `main` without explicit
user authorization.
