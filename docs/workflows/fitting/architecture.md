# Dispersion fitting architecture

This document defines the active architecture for fitting experimental dispersion data against the maintained Lamb-wave model families in this repository.

The fitting layer has been implemented and is used by scripts, tests, and `FitTool_GUI`. This document is no longer a phase-planning note.

## Scope

The fitting layer estimates model parameters from experimental phase-speed data:

```text
frequency -> measured phase speed -> model parameters
```

The supported experimental observable is the phase-speed curve:

```matlab
frequency_Hz
Cp_mps
```

Current model families with maintained fitting support:

```text
Rayleigh-Lamb
mRLFE
Acoustoelastic IOP/HGO
```

The fitting layer is reusable from scripts, tests, and the GUI. It must not be embedded directly inside GUI callbacks or long example scripts.

## Design principles

1. The GUI must not implement fitting algorithms.
2. Example scripts must not be backend dependencies.
3. Fitting must call maintained model APIs or model-specific fitting adapters.
4. Shared fitting utilities should remain model-independent.
5. Model-specific fitting logic should live with the corresponding model helper layer.
6. Solver improvements should benefit fitting automatically when the solver input/output contract is preserved.
7. Diagnostic branches must not be promoted to production fitting outputs without explicit validation.
8. GUI plotted fitted curves must distinguish fit-consistent objective values from optional dense diagnostic re-evaluations.

The GUI-facing architecture follows the same separation used by the sweep tool:

```text
GUI panel
    -> request struct
    -> app/fitting dispatcher
    -> model-specific adapter
    -> maintained model API
    -> normalized fit result
    -> plotting/export
```

## Active GUI workflow

The active GUI fitting surface is:

```matlab
FitTool_GUI
```

The GUI-side fitting layer is:

```text
app/fitting/guiGetFitRegistry.m
app/fitting/guiBuildFitRequest.m
app/fitting/guiRunFit.m
app/fitting/guiNormalizeFitResult.m
app/fitting/guiEvaluateFitFullCurve.m
app/fitting/guiPlotFitResult.m
```

Model-specific GUI adapters are:

```text
app/adapters/guiFitRLSolver.m
app/adapters/guiFitMRLFESolver.m
app/adapters/guiFitAcoustoelasticIOPHGOSolver.m
```

The GUI workflow is:

```text
1. Load, paste, or generate experimental data.
2. Select model family.
3. Select branch.
4. Select the free parameter.
5. Set fixed parameters, initial guesses, and bounds.
6. Run fitting.
7. Plot experimental data, fit-consistent fitted values, optional fitted curve, and residuals.
8. Inspect route/policy/status metadata.
9. Export or inspect `FitToolLastOutput` for diagnostics.
```

## Experimental data contract

The normalized experimental data structure uses explicit SI units:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Required fields:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
```

Optional fields:

```matlab
experimental.standardError_Cp_mps
experimental.validMask
```

The internal fitting contract is:

```text
frequency in Hz
phase speed in m/s
standard error in m/s
```

`validMask` is an optional logical vector indicating which experimental points participate in fitting. If missing, the backend builds a default valid mask from finite `frequency_Hz` and finite `Cp_mps` values.

Experimental standard error may be supplied as:

```matlab
experimental.standardError_Cp_mps
```

The default fitting path uses unweighted residuals unless fitting options explicitly enable standard-error weighting.

## FitRequest contract

A fitting request is represented as a structure with this conceptual schema:

```matlab
fitRequest = struct();

fitRequest.modelFamily = "rayleigh_lamb";
fitRequest.branchName = "A0";

fitRequest.experimental.frequency_Hz = frequency_Hz;
fitRequest.experimental.Cp_mps = Cp_mps;
fitRequest.experimental.standardError_Cp_mps = [];
fitRequest.experimental.validMask = [];

fitRequest.fixedParams = struct();
fitRequest.freeParams = ["mu"];

fitRequest.initialGuess = struct();
fitRequest.bounds = struct();

fitRequest.options = struct();
fitRequest.options.useStandardErrorWeights = false;
```

The exact fields may evolve, but the separation between experimental data, fixed parameters, free parameters, bounds, and options should remain stable.

## Execution profile controls

The canonical numerical profile field for GUI and adapter requests is:

```matlab
controls.executionProfile
```

The historical field remains accepted as a compatibility alias:

```matlab
controls.robustness
```

New code should set `executionProfile`. Builders canonicalize either field to
`Fast`, `Balanced`, or `Robust`, reject contradictory values, and preserve the
legacy alias for older consumers. The selected execution profile is separate
from:

- route policies such as mRLFE `adaptivePhysicalTail` or `delayedCut`;
- AE `atlasA0` branch policy;
- optimizer options such as `MaxIter`, `MaxFunEvals`, and `TolX`.

FitTool defaults to `Fast` for all maintained model families. Rayleigh-Lamb and
AE IOP/HGO apply all three profiles directly. mRLFE maps maintained FitTool
fitting to the public mRLFE `fast` preset and reports requested/effective
profile metadata. The historical internal name `fast_fit_atlas` may still appear
as diagnostic implementation metadata, but it is not passed as a public mRLFE
request preset.

## FitResult contract

A fitting result exposes the fitted values used by the objective and preserves raw solver metadata for diagnostics:

```matlab
fitResult.modelFamily
fitResult.branchName
fitResult.bestParams
fitResult.fixedParams
fitResult.frequency_Hz
fitResult.Cp_exp_mps
fitResult.Cp_fit_mps
fitResult.residuals_mps
fitResult.validMask
fitResult.metrics
fitResult.identifiability
fitResult.optimizer
fitResult.rawSolverResult
```

The normalized GUI result may add plotting and route metadata, including:

```matlab
normalized.fullCurve
normalized.requestedCurve
normalized.routePolicy
normalized.fitQuality
```

FitTool presents fit results as two separate summaries:

```matlab
normalized.parameterSummaryTable
normalized.fitQualitySummaryTable
```

`parameterSummaryTable` contains per-parameter fields such as role, value, unit,
initial guess, and bounds. `fitQualitySummaryTable` contains global fit quality
metrics such as RMSE, MAE, R2, baseline comparison, physical-quality warning,
and identifiability. `normalized.summaryTable` is retained as a compatibility
alias for the parameter summary.

The GUI derives compact display tables from those normalized outputs:

```matlab
guiBuildFitParameterDisplayTable
guiBuildFitQualityDisplayTable
```

The visible parameter summary shows only the fitted parameter. Fixed parameters
remain available in the normalized table and request metadata but are not
repeated below the plot. The visible fit-quality summary is displayed vertically
as `Metric | Value`; unavailable metrics such as AIC/BIC are hidden when their
values are not finite.

The optional `normalized.requestedCurve` is created only when the user explicitly
presses **Evaluate fitted curve**. It is a fresh forward solver evaluation using
the fitted parameter, fixed parameters, branch, execution profile, and route
policy from the completed fit. It does not call the optimizer and is distinct
from `normalized.fullCurve`, whose primary in-band curve remains fit-consistent
with the objective values.

## Model-specific fitting routes

### Rayleigh-Lamb

Rayleigh-Lamb fitting uses:

```matlab
rlBuildFitProblem
rlEvaluateFitModel
rlFitDispersionData
```

Active workflow reference:

```text
docs/models/rayleigh_lamb/fitting_workflow.md
```

### mRLFE

mRLFE fitting uses:

```matlab
mrlfeBuildFitProblem
mrlfeBuildFitSolveRequest
mrlfeEvaluateFitModel
mrlfeSolve
mrlfeFitDispersionData
```

The maintained FitTool route is public-API-first:

```text
mrlfeFitDispersionData
  -> mrlfeBuildFitProblem
  -> mrlfeEvaluateFitModel
  -> mrlfeBuildFitSolveRequest
  -> mrlfeSolve
  -> mrlfeBuildResult
```

For A0Like FitTool fitting, the current default policy is:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

The public request uses `selection.strategy = "adaptive"`,
`fallback.policy = "none"`, and branch-specific termination: A0Like uses
`physicalTail`, while S0Like uses `none`. Objective evaluations, automatic
full-curve diagnostics, and explicit requested fitted-curve evaluations all call
`mrlfeEvaluateFitModel`, so they share the same public solver route and final
fitted parameters.

`mrlfeEvaluateAtlasFitModel` is no longer the maintained production evaluator.
It is retained temporarily as a diagnostic/reference oracle for
characterization and migration tests. Main GUI and SweepTool mRLFE routes are
not migrated by this fitting change.

Dense mRLFE solver re-evaluation is diagnostic metadata, not the primary fit curve. Active workflow references:

```text
docs/models/mrlfe/fitting_workflow.md
docs/models/mrlfe/fittool_grid_path_sensitivity.md
```

### Acoustoelastic IOP/HGO

AE IOP/HGO fitting uses:

```matlab
aeBuildFitProblem
aeEvaluateFitModel
aeFitDispersionData
```

It uses the official atlas output for fitting and does not accept diagnostic branch families as fitted outputs.

Active workflow reference:

```text
docs/models/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Physical quality and identifiability

Shared fitting helpers include:

```matlab
computeDispersionFitResiduals
computeDispersionFitMetrics
computeConstantSpeedBaseline
assessFitPhysicalQuality
estimateLocalSensitivity
assessFitIdentifiability
```

These helpers provide basic numerical and physical sanity checks. They are not a replacement for experimental validation.

## FitTool visual state

FitTool keeps axis limits in GUI-local state:

```matlab
axisViewState
```

This state controls only plotting and is intentionally excluded from fitting
requests and solver options. In automatic mode, FitTool leaves the visible axis
limit fields blank rather than using `0` as a sentinel value.

## Validation

Smoke tests check that maintained APIs and GUI adapters run. Focused fitting validation checks synthetic parameter recovery.

Use:

```matlab
clear; clc; close all;
startup
run_all_smoke_tests
run_fit_validation_tests
```

For mRLFE FitTool-specific route behavior, also use:

```matlab
run_mrlfe_fit_public_solver_tests
run_mrlfe_fit_atlas_tests
```

Detailed validation reference:

```text
docs/workflows/fitting/validation_suite.md
```
