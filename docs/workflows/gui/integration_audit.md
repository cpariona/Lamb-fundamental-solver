# GUI integration audit

This document records the maintained GUI integration status after the SweepTool and FitTool cleanup passes.

## Active GUI surfaces

```text
LambFundamental_GUI   Interactive single-case forward modeling
SweepTool_GUI         Registry-driven one-parameter sweeps
FitTool_GUI           Experimental dispersion fitting
```

GUI code should call maintained model APIs through adapters. It should not call scripts under `examples/` directly.

## Active app structure

```text
app/
├─ LambFundamental_GUI.m
├─ SweepTool_GUI.m
├─ FitTool_GUI.m
├─ sweep/
│  ├─ guiGetSweepRegistry.m
│  ├─ guiGetSweepFamilyConfig.m
│  ├─ guiGetSweepParameterConfig.m
│  ├─ guiFormatSweepValues.m
│  ├─ guiBuildSweepRequest.m
│  ├─ guiRunSweep.m
│  └─ guiPlotSweepResult.m
├─ fitting/
│  ├─ guiGetFitRegistry.m
│  ├─ guiBuildFitRequest.m
│  ├─ guiRunFit.m
│  ├─ guiNormalizeFitResult.m
│  ├─ guiBuildFitDisplayCurve.m
│  ├─ guiEvaluateRequestedFitCurve.m
│  └─ guiPlotFitResult.m
└─ adapters/
   ├─ guiRunRayleighLambModel.m
   ├─ guiRunMRLFEModel.m
   ├─ guiRunAcoustoelasticIOPHGOModel.m
   ├─ guiRunMRLFESweep.m
   ├─ guiNormalizeMRLFESweep.m
   ├─ guiRunRLSweep.m
   ├─ guiNormalizeRLSweep.m
   ├─ guiRunAcoustoelasticIOPHGOSweep.m
   ├─ guiNormalizeAcoustoelasticIOPHGOSweep.m
   ├─ guiFitRLSolver.m
   ├─ guiFitMRLFESolver.m
   └─ guiFitAcoustoelasticIOPHGOSolver.m
```

## Main GUI status

`LambFundamental_GUI` owns the main interactive single-case workflow. It keeps both raw and normalized outputs:

```matlab
lastResults
lastGuiResult
```

The raw output is preserved for diagnostics and compatibility. The normalized output is preferred for plotting and export. The **Export results** action writes one `LambExport` MAT variable containing only GUI-visible frequency/phase-velocity curves, validity masks, and the physical parameters captured from the interface.

Current model-family coverage:

```text
Rayleigh-Lamb
mRLFE real-k
AE IOP/HGO
```

## SweepTool status

`SweepTool_GUI` is registry-driven and supports visible one-parameter sweeps for:

```text
mRLFE
Rayleigh-Lamb
AE IOP/HGO
```

Current visible sweep parameters are defined by:

```text
app/sweep/guiGetSweepRegistry.m
```

Current visible sweep parameters:

```text
mRLFE: etaS, mu, thickness
Rayleigh-Lamb: thickness, mu
AE IOP/HGO: IOP, mu
```

Current backend paths:

```text
mRLFE sweep:
SweepTool_GUI -> guiRunSweep -> guiRunMRLFESweep -> runParametricSweep

Rayleigh-Lamb sweep:
SweepTool_GUI -> guiRunSweep -> guiRunRLSweep -> runParametricSweep

AE IOP/HGO sweep:
SweepTool_GUI -> guiRunSweep -> guiRunAcoustoelasticIOPHGOSweep -> aeRunSweep -> aeSummarizeSweep
```

## FitTool status

`FitTool_GUI` uses the shared fitting backend:

```text
FitTool_GUI
  -> guiBuildFitRequest
  -> guiRunFit
  -> model-specific fitting adapter
  -> normalized fit result
  -> guiBuildFitDisplayCurve
  -> guiPlotFitResult
```

The fit action does not reevaluate the solver for a dense curve. The explicit
**Evaluate fitted curve** action calls `guiEvaluateRequestedFitCurve`.

Current model-family fitting adapters:

```text
guiFitRLSolver
guiFitMRLFESolver
guiFitAcoustoelasticIOPHGOSolver
```

Model-specific fitting workflows are documented in:

```text
docs/models/rayleigh_lamb/fitting_workflow.md
docs/models/mrlfe/fitting_workflow.md
docs/models/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Dependency policy

App code should call maintained model APIs or analysis helpers through adapters.

Allowed dependency direction:

```text
GUI -> app/sweep or app/fitting -> app/adapters -> analysis/models
```

Disallowed dependency direction:

```text
GUI -> examples/
GUI -> archived docs/scripts
GUI -> diagnostic-only branch families as production outputs
```

## Remaining cleanup candidates

- Main GUI plotting still contains some legacy fallback paths.
- Main GUI mRLFE policy still has some logic in callbacks.
- Some plot styling issues remain in `SweepTool_GUI`; these are UI polish, not structural blockers.
- `app/createAdvancedTab.m` still has stale text mentioning `defaultOptions.m`; this should be corrected in a later UI-copy cleanup.
- `docs/workflows/gui/main_pending_cleanup.md` should be reviewed after AE GUI cleanup is rechecked; it may be better treated as a roadmap or moved to archive if all actionable items are resolved elsewhere.

## Validation

Recommended validation after GUI documentation or adapter-surface changes:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
run_fit_validation_tests
run_mrlfe_fit_public_solver_tests
```

Manual GUI checks:

```text
LambFundamental_GUI
SweepTool_GUI
FitTool_GUI
```

SweepTool and FitTool usage are documented in:

```text
docs/workflows/sweeps/sweep_tool_usage.md
docs/workflows/fitting/architecture.md
```
