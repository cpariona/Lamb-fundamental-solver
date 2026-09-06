# Structural symmetry contract

## Purpose

This contract defines the final repository shape required before
`planning/full-repository-restructure` can be considered for integration into
`main`. Symmetry means equivalent responsibilities use equivalent ownership and
schemas. It does not require different physical models to use the same numerical
algorithm.

No change made under this contract may alter model equations, scientific branch
selection, numerical strategy, scientific goldens, or accepted tolerances unless
that change is separately reviewed as scientific work.

## Model-family spine

Where a responsibility exists, model families use the same directory role:

```text
models/<family>/
  api/             maintained model entry points and public defaults
  configuration/   validation and requested/effective configuration resolution
  core/            model-owned problem/state construction and low-level physics
  solvers/         orchestration of one maintained numerical solve
  tracking/        branch/candidate continuation and refinement
  quality/         assessment of already-decided official output
  results/         construction of the public result
```

Scientifically specific directories remain explicit rather than being forced
into generic abstractions:

```text
rayleigh_lamb/equations
rayleigh_lamb/approximations
acoustoelastic_iop_hgo/constitutive
acoustoelastic_iop_hgo/diagnostics
model-specific policies when a real policy stage exists
```

Do not create empty directories or forwarding wrappers only to imitate another
family. The common spine is about responsibility ownership, not visual padding.

## Public scientific curve contract

Every maintained official dispersion curve uses the same field names and vector
orientation:

```matlab
frequency_Hz       % N-by-1
phaseVelocity_mps  % N-by-1
wavenumber_radpm   % N-by-1
validMask          % N-by-1 logical
```

Invalid official phase-velocity points are `NaN` and have `validMask = false`.
Model-specific arrays do not replace or alias these fields.

Rayleigh-Lamb naturally returns more than one fundamental branch under
`modes.A0` / `modes.S0`. mRLFE and AE currently return one selected branch per
public solve. That scientifically justified containment difference may remain,
but every official curve must obey the same array contract.

## Quality contract

`quality` is the only public assessment name. Core quality fields use
lowerCamelCase:

```text
pointCount
validCount
validFraction
accepted
reason
```

Additional model-specific quality fields are allowed when scientifically useful,
but they also use lowerCamelCase and do not duplicate diagnostics. PascalCase AE
quality fields are transitional repository debt and are not part of the final
contract.

Quality evaluates output after the scientific branch/curve has already been
decided. It must not select, reconnect, interpolate, or replace a branch.

## Configuration contract

All model results expose:

```text
configuration.requested
configuration.effective
```

Both levels use the same conceptual split:

```text
parameters   physical/problem inputs
options      numerical and policy controls
```

A model may add clearly named model-specific metadata, but callers should not
need to infer whether a field is physical or numerical from its location.
Public input signatures do not need to be artificially identical when the
scientific operations differ.

## Execution and diagnostic contract

`execution` contains operational facts about the completed solve. The common
minimum is:

```text
engine
elapsedSeconds
```

Execution-profile metadata may be added by human-facing surfaces, but it must
not redefine model physics.

`diagnostics` contains stable, interpretable evidence or summaries useful to a
caller. Large or unstable internal state belongs under one explicit `debug`
boundary. In particular, atlas matrices/tables, raw tracker state, and equivalent
heavy implementation evidence must not accumulate as unrelated public top-level
fields.

Fallback/termination metadata is exposed only where the model actually has that
stage. If a shared consumer needs a neutral representation, the adapter supplies
a neutral view; the model does not invent a fake scientific policy for symmetry.

## Generic utilities and cross-family dependencies

A function used as generic infrastructure by more than one model family must not
remain owned by one model family merely for historical reasons.

The intentional scientific cross-family dependency remains:

```text
mRLFE seed -> Rayleigh-Lamb solver
```

Unrelated dependencies such as frequency-grid construction, UI defaults, or
workflow helpers must use a neutral owner or remain local to the caller.
Rayleigh-Lamb must not become an accidental shared-utility package.

## Fitting contract

The maintained fitting structure is already the reference pattern:

```text
<family>FitDispersionData
  -> <family>BuildFitProblem
  -> lamb.fitting.solveDispersionFitProblem
  -> <family>EvaluateFitModel
  -> canonical model API
```

Model-specific parameterization remains explicit. FitTool consumes one common
normalized fit-output spine and does not own model physics.

## One-dimensional sweep contract

All maintained one-dimensional sensitivity studies use
`lamb.sweeps.runParametricSweep` as the iteration
owner and retain its primary result structure:

```text
spec
parameter
values
displayValues
results
params
options
elapsedSeconds
points
requests
```

A family wrapper may build a summary, plot, or persisted output from this result,
but must not replace it with a parallel condition/result schema. AE two-dimensional
grid sweeps are scientifically distinct and may retain a separate grid contract.

Shared one-dimensional summary and plot-data owners must support all three model
families through canonical curve extraction rather than RL/mRLFE-only branching.

## GUI normalized result contract

Main GUI model adapters use one normalized branch shape:

```text
modelName
rawModelName
branchName
frequency
phaseVelocity
wavenumber
kThickness
metadata
diagnostics
```

The aggregate normalized model view uses one stable spine:

```text
modelName
branchName
frequency
phaseVelocity
wavenumber
kThickness
branches
metadata
diagnostics
```

Model-specific evidence belongs below `metadata` or `diagnostics`; it must not
change the normalized spine. `guiBuildModelResultView` or its maintained
replacement is the single normalization owner.

Sensitivity-study plot adapters use one common curve schema. Extra model-specific
tables/evidence belong in study metadata rather than changing curve fields.

## Test contract

Every maintained direct test is a no-output MATLAB function:

```matlab
function test_name()
%TEST_NAME ...
...
end
```

Maintained tests must not:

```text
be scripts
call clear or clc
configure their own repository/test path
return scientific result collections
act as reference-capture utilities
```

The six runners own path setup and execution scope. Tests may create local
temporary files only with explicit cleanup.

Cross-model contract tests must protect, where applicable:

```text
official curve field names and column orientation
quality core names
requested/effective configuration envelope
Main GUI normalized branch/view shape
1-D sweep primary and normalized shapes
FitTool aggregate shape
execution-profile metadata shape
model-family responsibility spine
```

Family-specific tests protect only genuinely family-specific equations,
selection policies, diagnostics, and scientific behavior.

## Acceptance gate

Before this campaign is complete:

1. equivalent responsibilities have one visible owner and comparable placement;
2. no compatibility aliases were added merely to ease migration;
3. no unintended cross-family utility dependency remains;
4. all maintained tests follow the same execution contract;
5. cross-model tests enforce shared schemas instead of family exceptions;
6. documentation matches production behavior;
7. all six canonical runners pass;
8. the final diff is reviewed against `planning/full-repository-restructure`;
9. `main` remains unchanged until explicit user authorization.
