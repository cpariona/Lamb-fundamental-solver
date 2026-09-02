# GUI adapter architecture

This document records the maintained GUI adapter structure and is the active reference for GUI/backend boundaries.

## Dependency direction

Allowed dependency direction:

```text
GUI surface
    -> app-layer request/dispatcher
    -> app/adapters
    -> analysis/models
    -> normalized GUI result
    -> plotting/export
```

GUI files should not call scripts under `examples/` directly, and they should not treat diagnostic-only branch families as production outputs.

## App folder ownership

```text
app/
|-- adapters/  model-specific request/result translation and profile resolution
|-- export/    normalized Main GUI export
|-- fitting/   FitTool state, visual controls, and display workflow
|-- sweep/     SweepTool workflow and interactive sweep UI
`-- root       GUI entrypoints and genuinely cross-surface UI infrastructure
```

Model-specific execution-profile resolvers and mRLFE surface metadata helpers
live in `app/adapters/`. Cross-surface profile normalization and diagnostics
formatting remain at the app root. `createFittingTab` belongs to `app/fitting/`.
The interactive AE grid-sweep plot belongs to `app/sweep/`; its numerical data
construction remains in `analysis/acoustoelastic_iop_hgo/sweeps/`.

## Main GUI flow

```text
LambFundamental_GUI
    -> GUI request struct
    -> app/adapters/guiRun*Model
    -> canonical model result
    -> app/adapters/guiBuildModelResultView
    -> normalized branches
    -> plotting/export
```

The main GUI keeps both raw and normalized result states:

```matlab
lastResults
lastGuiResult
```

`lastResults` is the completed canonical model result. `lastGuiResult` is its
shallow presentation view for plotting and export. Neither plotting nor export
invokes a solver or reconstructs scientific branches.

The maintained Main GUI mRLFE adapter is model-API based:

```text
guiRunMRLFEModel
    -> mrlfeBuildGuiSolveRequest
    -> mrlfeSolve
    -> GUI result adapter
```

It does not call legacy mRLFE solver entrypoints, choose low-level trackers,
apply physical-tail cutting directly, or perform zero-viscosity fallback.
Partial-quality branches remain visible and are reported through neutral
quality/status metadata.

### Main GUI export

`LambFundamental_GUI` exports only the normalized GUI-visible curves and the
physical parameters captured from the interface at the time of computation:

```text
lastGuiResult.branches
    -> guiBuildMainResultExport
    -> guiSaveMainResultExport
    -> LambExport
```

Each exported curve contains only `Frequency_Hz`, `PhaseVelocity_mps`, and
`Valid`. Raw solver results, model diagnostics, route metadata, wavenumber, and
`kThickness` are intentionally excluded from this public export.

## SweepTool flow

```text
SweepTool_GUI
    -> guiGetSweepRegistry
    -> guiBuildSweepRequest
    -> guiRunSweep
    -> model-specific sweep adapter
    -> model-specific sweep normalizer
    -> guiPlotSweepResult
```

`SweepTool_GUI` should not call scripts under `examples/` directly.

### Sweep registry

The registry entrypoint is:

```text
app/sweep/guiGetSweepRegistry.m
```

Visible families:

```text
mRLFE
    parameters: etaS, mu, thickness
    branches: A0Like, S0Like

Rayleigh-Lamb
    parameters: thickness, mu
    branches: A0, S0

AE IOP/HGO
    parameters: IOP, mu
    branch: atlasA0
```

The registry owns GUI-facing labels, default values, display units, and display-to-solver scales.

### Sweep adapters

Current sweep adapters:

```text
app/adapters/guiRunMRLFESweep.m
app/adapters/guiNormalizeMRLFESweep.m
app/adapters/guiRunRLSweep.m
app/adapters/guiNormalizeRLSweep.m
app/adapters/guiRunAcoustoelasticIOPHGOSweep.m
app/adapters/guiNormalizeAcoustoelasticIOPHGOSweep.m
```

All new sweep-capable families should follow the same pair pattern:

```text
guiRun<ModelFamily>Sweep
guiNormalize<ModelFamily>Sweep
```

The maintained mRLFE SweepTool adapter is model-API based:

```text
guiRunMRLFESweep
    -> mrlfeBuildSweepSolveRequest
    -> mrlfeSolve, once per sweep point
    -> guiNormalizeMRLFESweep
```

It does not call `guiRunMRLFEModel`, choose adaptive versus modal trackers,
inspect atlas candidates, or apply Main GUI fallback. The per-point public
`modelResult` remains available under `rawResults.points{i}.modelResult`, while
the normalized curve schema remains the plotting contract.

### Normalized sweep curve schema

`guiPlotSweepResult` expects:

```matlab
normalized.curves(i).label
normalized.curves(i).frequency_Hz
normalized.curves(i).Cp_mps
normalized.curves(i).validMask
normalized.curves(i).lastValidFrequency_Hz
normalized.curves(i).modelResult
normalized.curves(i).status
normalized.curves(i).errorIdentifier
normalized.curves(i).errorMessage
normalized.summaryTable
```

### Sweep export contract

SweepTool exports:

```matlab
SweepToolOutput
SweepToolRequest
SweepToolNormalized
SweepToolResults
SweepToolSummary
SweepToolModelName
SweepToolBranchName
```

`SweepToolNormalized` is preferred for app-level plotting and downstream workflows. `SweepToolResults` is preserved for raw diagnostics and compatibility.

## FitTool flow

```text
FitTool_GUI
    -> guiGetFitRegistry
    -> guiBuildFitRequest
    -> guiRunFit
    -> model-specific fitting adapter
    -> guiNormalizeFitResult
    -> guiBuildFitDisplayCurve
    -> guiPlotFitResult
```

The fit action uses only the objective-consistent display interpolation. The
separate **Evaluate fitted curve** action calls
`guiEvaluateRequestedFitCurve` and performs the requested solver evaluation.

### Fitting registry

The registry entrypoint is:

```text
app/fitting/guiGetFitRegistry.m
```

Visible families:

```text
Rayleigh-Lamb
    branches: A0, S0
    fit-capable parameters: mu, thickness

mRLFE
    branches: A0Like, S0Like
    fit-capable parameters: mu, etaS, thickness

AE IOP/HGO
    branch: atlasA0
    fit-capable parameters: mu, IOP, thickness
```

Registry entries may expose additional fixed parameters such as density, Poisson ratio, fluid density, fluid sound speed, curvature radius, and HGO parameters.

### Fitting adapters

Current fitting adapters:

```text
app/adapters/guiFitRLSolver.m
app/adapters/guiFitMRLFESolver.m
app/adapters/guiFitAcoustoelasticIOPHGOSolver.m
```

All new fit-capable families should follow the same pattern:

```text
guiFit<ModelFamily>Solver
```

### Normalized fit schema

`guiPlotFitResult` and `FitTool_GUI` expect normalized fit output with:

```matlab
normalized.fitResult
normalized.experimental
normalized.fullCurve
normalized.metrics
normalized.routePolicy
normalized.fitQuality
```

Model-specific adapters may preserve raw solver output and route metadata for diagnostics, but plotting should use normalized fields.

### FitTool export/diagnostic contract

FitTool stores the latest output in:

```matlab
FitToolLastOutput
```

Model-specific route metadata should remain visible through normalized route/status fields rather than by requiring users to inspect raw solver internals.

## mRLFE public production integration

The mRLFE GUI, SweepTool, and FitTool paths use the public production API.

The integration contract is documented in:

```text
docs/models/mrlfe/public_api.md
docs/models/mrlfe/production_core.md
```

The maintained request policy is:

```matlab
A0Like -> termination.policy = "physicalTail"
S0Like -> termination.policy = "none"
fallback.policy = "none"
```

The maintained effective engines are:

```matlab
elastic_adaptive
viscoelastic_adaptive
```

Historical atlas-route flags are not maintained GUI adapter control flow.

## Validation

After GUI adapter changes, run:

```matlab
clear; clc; close all;
startup
run_gui_smoke_tests
run_fit_validation_tests
run_mrlfe_route_integrity_tests
```

For a complete repository check, run:

```matlab
run_all_smoke_tests
```
