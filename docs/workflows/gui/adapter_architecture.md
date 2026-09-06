# GUI adapter architecture

This document records the maintained GUI adapter structure and is the active reference for GUI/backend boundaries.

## Dependency direction

Allowed dependency direction:

```text
GUI surface
    -> app-layer request/dispatcher
    -> surface-local model translation
    -> analysis/models
    -> normalized GUI result
    -> plotting/export
```

GUI files should not call scripts under `examples/` directly, and they should not treat diagnostic-only branch families as production outputs.

## App folder ownership

```text
app/
|-- fitting/   FitTool request, translation, state, and display workflow
|-- main/      Main GUI controls, translation, presentation, and export
|-- shared/    cross-surface profiles and struct operations
|-- sweep/     SweepTool request, translation, and interactive visualization
`-- root       the three GUI entrypoints
```

Model-specific execution-profile resolvers and mRLFE surface metadata helpers
live in `app/shared/`. Cross-surface profile normalization and diagnostics
formatting live there as well. `createFittingTab` belongs to `app/fitting/`.
The interactive AE grid-sweep plot belongs to `app/sweep/`; its numerical data
construction remains in `analysis/plotting/sweeps/acoustoelastic_iop_hgo/`.

## Main GUI flow

```text
LambFundamental_GUI
    -> GUI request struct
    -> app/main/guiRun*Model
    -> canonical model result
    -> app/main/guiBuildModelResultView
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

The mRLFE dimensionless plotting coordinate is computed in the view from the
stored canonical wavenumber and effective full thickness. It is not another
scientific solve and does not read newly edited GUI controls.

The maintained Main GUI mRLFE adapter is model-API based:

```text
guiRunMRLFEModel
    -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
    -> lamb.models.mrlfe.mrlfeSolve
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
    -> guiGetSweepModelConfiguration
    -> guiBuildSweepRequest
    -> guiRunSweep
    -> model-specific sweep adapter
    -> model-specific sweep normalizer
    -> guiPlotSweepResult
```

`SweepTool_GUI` should not call scripts under `examples/` directly.

### Sweep model configuration

The declarative configuration entrypoint is:

```text
app/sweep/guiGetSweepModelConfiguration.m
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

The configuration owns GUI-facing labels, default values, display units, and display-to-solver scales.

### Sweep adapters

Current sweep adapters:

```text
app/sweep/guiRunMRLFESweep.m
app/sweep/guiNormalizeMRLFESweep.m
app/sweep/guiRunRLSweep.m
app/sweep/guiNormalizeRLSweep.m
app/sweep/guiRunAcoustoelasticIOPHGOSweep.m
app/sweep/guiNormalizeAcoustoelasticIOPHGOSweep.m
```

All new sweep-capable families should follow the same pair pattern:

```text
guiRun<ModelFamily>Sweep
guiNormalize<ModelFamily>Sweep
```

The maintained mRLFE SweepTool adapter is model-API based:

```text
guiRunMRLFESweep
    -> runParametricSweep
    -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
    -> lamb.models.mrlfe.mrlfeSolve, once per sweep point
    -> guiNormalizeMRLFESweep
```

It does not call `guiRunMRLFEModel`, choose adaptive versus modal trackers,
inspect atlas candidates, or apply Main GUI fallback. The per-point public
`modelResult` remains available under `sweepResult.points{i}.modelResult`, while
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

`SweepToolNormalized` is preferred for app-level plotting and downstream workflows. `SweepToolResults` contains the computed point results for inspection; it is not another solve.

## FitTool flow

```text
FitTool_GUI
    -> guiGetFitModelConfiguration
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

### Fitting model configuration

The declarative configuration entrypoint is:

```text
app/fitting/guiGetFitModelConfiguration.m
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

Configuration entries may expose additional fixed parameters such as density, Poisson ratio, fluid density, fluid sound speed, curvature radius, and HGO parameters.

### Fitting adapters

Current fitting adapters:

```text
app/fitting/guiFitRLSolver.m
app/fitting/guiFitMRLFESolver.m
app/fitting/guiFitAcoustoelasticIOPHGOSolver.m
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
run_quick_smoke_tests
run_extended_integration_tests
run_quick_contract_tests
```

Complete repository validation requires all six tiers listed in
`tests/README.md`; the extended tier alone is not a complete check.

## Concrete call traces

These are implementation traces, not an expansion of the public API.

| Surface/model | Computation path |
| --- | --- |
| Main / RL | LambFundamental_GUI -> guiRunRayleighLambModel -> lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes -> lamb.models.rayleigh_lamb.results.rlBuildResult -> guiBuildModelResultView |
| Main / mRLFE | LambFundamental_GUI -> guiRunMRLFEModel -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest -> lamb.models.mrlfe.mrlfeSolve -> lamb.models.mrlfe.results.mrlfeBuildResult -> guiBuildModelResultView |
| Main / AE | LambFundamental_GUI -> guiRunAcoustoelasticIOPHGOModel -> lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch -> lamb.models.acoustoelastic_iop_hgo.results.aeBuildResult -> adapter view |
| Fit / RL | FitTool_GUI -> guiRunFit -> guiFitRLSolver -> lamb.fitting.rayleigh_lamb.rlFitDispersionData -> lamb.fitting.solveDispersionFitProblem -> lamb.fitting.rayleigh_lamb.rlEvaluateFitModel -> lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch |
| Fit / mRLFE | FitTool_GUI -> guiRunFit -> guiFitMRLFESolver -> lamb.fitting.mrlfe.mrlfeFitDispersionData -> lamb.fitting.solveDispersionFitProblem -> lamb.fitting.mrlfe.mrlfeEvaluateFitModel -> lamb.models.mrlfe.mrlfeSolve |
| Fit / AE | FitTool_GUI -> guiRunFit -> guiFitAcoustoelasticIOPHGOSolver -> lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData -> lamb.fitting.solveDispersionFitProblem -> lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel -> lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch |
| Sweep / RL | SweepTool_GUI -> guiRunSweep -> guiRunRLSweep -> runParametricSweep -> lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes |
| Sweep / mRLFE | SweepTool_GUI -> guiRunSweep -> guiRunMRLFESweep -> runParametricSweep -> lamb.models.mrlfe.mrlfeSolve |
| Sweep / AE | SweepTool_GUI -> guiRunSweep -> guiRunAcoustoelasticIOPHGOSweep -> aeRunSweep -> runParametricSweep -> lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch |

The GUI entrypoints are in `app/`; model adapters are under `app/main/`,
`app/fitting/`, and `app/sweep/`. Model-specific fit/sweep workflows are
under `src/+lamb/+fitting/` and `analysis/sweeps/`.
RL fitting intentionally uses the shared model-layer continuator rather than
the batch-grid API: see `docs/workflows/fitting/architecture.md`.

Completed fit output goes through guiNormalizeFitResult and guiBuildFitDisplayCurve
to guiPlotFitResult; completed sweep output goes through its model normalizer
to guiPlotSweepResult. Main export uses guiBuildMainResultExport then
guiSaveMainResultExport. None of those render/export stages solves again.

AE 2D is a programmatic/example workflow, not a SweepTool control:
`examples/acoustoelastic_iop_hgo/sweeps/ae_sweep_mu_iop_A0Like.m`
calls aeRunGridSweep, whose two-axis iterator calls the same public AE solver.
Its Cp cube is built in analysis; optional interactive rendering is in app/sweep.
