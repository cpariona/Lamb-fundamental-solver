# GUI adapter architecture

This document records the maintained GUI adapter structure. It is the detailed architecture reference for GUI/backend boundaries; `docs/workflows/gui/integration_audit.md` is the status overview.

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

## Main GUI flow

```text
LambFundamental_GUI
    -> GUI request struct
    -> app/adapters/guiRun*Model
    -> raw solver result
    -> app/adapters/guiNormalizeRawResult
    -> normalized branches
    -> plotting/export
```

The main GUI keeps both raw and normalized result states:

```matlab
lastResults
lastGuiResult
```

`lastResults` is kept for compatibility and diagnostics. `lastGuiResult` is the preferred GUI-facing structure for plotting and export.

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

### Normalized sweep curve schema

`guiPlotSweepResult` expects:

```matlab
normalized.curves(i).label
normalized.curves(i).frequency_Hz
normalized.curves(i).Cp_mps
normalized.curves(i).validMask
normalized.curves(i).lastValidFrequency_Hz
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
    -> guiEvaluateFitFullCurve
    -> guiPlotFitResult
```

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

## mRLFE atlas policy integration

The mRLFE GUI path exposes the unified real-k atlas route and A0 policy selector through adapters rather than by calling solver internals directly.

The integration contract is documented in:

```text
docs/workflows/gui/mrlfe_atlas_policy_integration.md
```

The maintained GUI-facing mRLFE policy fields are:

```matlab
mrlfeUseUnifiedAtlasRoute
mrlfeA0Policy
```

FitTool also uses:

```matlab
mrlfeUseAtlasFitRoute
```

The supported A0 policies are:

```matlab
"delayedCut"
"adaptivePhysicalTail"
```

For A0Like FitTool fitting, the current default is:

```matlab
"adaptivePhysicalTail"
```

## Validation

After GUI adapter changes, run:

```matlab
clear; clc; close all;
startup
run_gui_smoke_tests
run_fit_validation_tests
run_mrlfe_fit_atlas_tests
```

For a complete repository check, run:

```matlab
run_all_smoke_tests
```
