# Dispersion fitting architecture

This document defines the maintained architecture for fitting experimental dispersion data against the supported Lamb-wave model families.

## Scope

The fitting layer estimates model parameters from experimental phase-speed data:

```text
frequency -> measured phase speed -> fitted model parameters
```

Maintained model families:

```text
Rayleigh-Lamb
mRLFE
Acoustoelastic IOP/HGO
```

The fitting layer is reusable from scripts, tests, and `FitTool_GUI`. GUI callbacks do not own optimization or model physics.

## Design principles

1. GUI code builds requests and renders normalized results.
2. `lamb.fitting.solveDispersionFitProblem` owns optimizer orchestration and result assembly.
3. Model-specific builders own fitting configuration and optimizer defaults;
   evaluators call canonical model owners without duplicating physics.
4. Example and diagnostic scripts are not production dependencies.
5. Objective values and optional full-curve evaluations remain distinguishable.
6. A complete fitted curve is evaluated only after an explicit user action.
7. Execution profile, route policy, and optimizer options remain separate concepts.

## Active GUI workflow

```text
FitTool_GUI
  -> guiBuildFitRequest
  -> guiRunFit
  -> model-specific fitting adapter
  -> model fitting backend
  -> maintained model API
  -> guiNormalizeFitResult
  -> guiPlotFitResult
```

Model-specific adapters:

```text
app/fitting/guiFitRLSolver.m
app/fitting/guiFitMRLFESolver.m
app/fitting/guiFitAcoustoelasticIOPHGOSolver.m
```

Fitted-curve helpers:

```text
app/fitting/guiBuildFitDisplayCurve.m
app/fitting/guiEvaluateRequestedFitCurve.m
```

`guiBuildFitDisplayCurve` uses values already evaluated by the objective and never calls a forward solver. `guiEvaluateRequestedFitCurve` performs a new forward evaluation only after the user presses **Evaluate fitted curve**.

## Experimental data contract

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

The internal contract uses Hz and m/s. Standard-error weighting is disabled by default unless explicitly requested.

## Fit request contract

```matlab
fitRequest.modelFamily
fitRequest.branchName
fitRequest.experimental
fitRequest.fixedParams
fitRequest.freeParams
fitRequest.initialGuess
fitRequest.bounds
fitRequest.controls
fitRequest.options
```

The canonical GUI numerical profile field is:

```matlab
controls.executionProfile
```

`controls.robustness` remains a compatibility alias. Builders canonicalize Fast, Balanced, or Robust and reject contradictory values.

## Fit result contract

The backend result exposes objective-consistent values and raw solver metadata:

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
fitResult.modelEvaluation
```

The normalized GUI result may add:

```matlab
normalized.fullCurve
normalized.requestedCurve
normalized.routePolicy
normalized.fitQuality
normalized.parameterSummaryTable
normalized.fitQualitySummaryTable
```

`normalized.fullCurve` is the fit-consistent display interpolation. It is not a solver-generated dense curve. `normalized.requestedCurve` is absent until explicitly requested.

The visible parameter summary shows only the fitted parameter. Fixed parameters remain available in normalized metadata.

## Model-specific routes

### Rayleigh-Lamb

```text
lamb.fitting.rayleigh_lamb.rlFitDispersionData
  -> lamb.fitting.rayleigh_lamb.rlBuildFitProblem
  -> lamb.fitting.solveDispersionFitProblem
  -> lamb.fitting.rayleigh_lamb.rlEvaluateFitModel
  -> lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch
```

The RL evaluator shares the canonical model-layer continuation owner with
`lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes`. It preserves exact experimental frequencies
in its own tracking grid and disables prediction fallback. It therefore does
not call the public batch-grid API; there is no second physics or optimizer
implementation. This distinction is deliberate and numerically protected.

### mRLFE

```text
lamb.fitting.mrlfe.mrlfeFitDispersionData
  -> lamb.fitting.mrlfe.mrlfeBuildFitProblem
  -> lamb.fitting.solveDispersionFitProblem
  -> lamb.fitting.mrlfe.mrlfeEvaluateFitModel
  -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
  -> lamb.models.mrlfe.mrlfeSolve
```

mRLFE objective evaluations use:

```matlab
forwardModel.gridPolicy = "fitOptimized";
minimumPointCount = 12;
maximumPointCount = 40;
maximumStep_Hz = 250;
```

This grid preserves experimental frequencies and adds bounded continuation points.

The explicit requested full curve uses:

```matlab
forwardModel.gridPolicy = "numericalPreset";
```

and resolves Fast, Balanced, or Robust into the corresponding public numerical preset. A0Like uses `physicalTail`; S0Like uses `none`; fallback is disabled.

### Acoustoelastic IOP/HGO

```text
lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData
  -> lamb.fitting.acoustoelastic_iop_hgo.aeBuildFitProblem
  -> lamb.fitting.solveDispersionFitProblem
  -> lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel
  -> lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch
```

Atlas construction and branch selection belong to the AE model, not the optimizer.

The fitting package does not call sweep defaults or sweep orchestration. AE and
mRLFE fitting defaults are constructed by their family fitting owners from
canonical model configuration, while sweep-specific defaults remain under the
separate sweep workflows.

## Physical quality and identifiability

Shared fitting helpers include optimizer orchestration, residual calculation, fit metrics, constant-speed baseline comparison, physical-quality assessment, local sensitivity, and identifiability assessment. `lamb.fitting.solveDispersionFitProblem` selects `fminbnd` or `fminsearch`, performs the final evaluation, and assembles the canonical fit result. Model builders still own their model-specific optimizer options, bounds, and evaluators. These checks are numerical diagnostics, not external experimental validation.

## Validation

Broad fitting validation:

```matlab
run_extended_integration_tests
```

mRLFE-focused validation:

```matlab
run_extended_integration_tests
run_quick_smoke_tests
```

The focused mRLFE suite checks public-solver routing, parameter regression, fit-grid behavior, absence of automatic solver reevaluation, and explicit full-curve evaluation.

Detailed references:

```text
docs/models/mrlfe/fitting_workflow.md
docs/validation/mrlfe_grid_presets.md
docs/workflows/fitting/validation_suite.md
```
