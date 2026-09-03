# mRLFE fitting workflow

This document records the maintained mRLFE dispersion fitting workflow after all maintained consumers migrated to the public production API.

## Maintained chain

```text
FitTool_GUI
  -> guiFitMRLFESolver
  -> mrlfeFitDispersionData
  -> mrlfeBuildFitProblem
  -> solveDispersionFitProblem
  -> mrlfeEvaluateFitModel
  -> mrlfeBuildSolveRequest
  -> mrlfeSolve
```

There is one maintained physical evaluation route. `mrlfeEvaluateFitModel` builds a public request and calls `mrlfeSolve`; it does not contain a legacy opt-out route. `mrlfeEvaluateAtlasFitModel` has been removed.

## Supported fitting cases

```text
branch: A0Like or S0Like
free parameter: mu, thickness, or etaS
fixed parameters: remaining elastic/geometric parameters, rho, nu, fluid parameters
```

For `mu` and `thickness` fits, `etaS` may be fixed. In `FitTool_GUI`, this value is exposed as `Fixed etaS [Pa*s]` when `etaS` is not the free parameter.

## Data contract

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Only `frequency_Hz` and `Cp_mps` are required.

## Public request mapping

`mrlfeBuildSolveRequest` maps fitting parameters and model-owned options to the public SI request contract:

```matlab
request.branch
request.frequency_Hz
request.material
request.geometry
request.fluid
request.numerics.preset
request.selection.strategy = "adaptive"
request.termination.policy
request.fallback.policy = "none"
```

The numerical preset is resolved from the selected Fast, Balanced, or Robust execution profile. A0Like uses `physicalTail` termination. S0Like uses `none`. No fallback is applied.

## Fit-optimized objective grid

Optimizer objective evaluations use:

```matlab
options.forwardModel.gridPolicy = "fitOptimized";
```

The maintained defaults are:

```matlab
minimumPointCount = 12;
maximumPointCount = 40;
maximumStep_Hz = 250;
```

The grid preserves all experimental frequencies and adds only the continuation points required by the public solver. This reduces per-objective cost without changing the requested output frequencies.

The lightweight characterization measured approximately 3.0x to 4.3x speedup against the Fast numerical-preset grid, with a worst observed relative phase-speed difference of 0.121% and no valid-mask differences in the tested A0 elastic, A0 viscous, and S0 elastic cases.

## Result normalization and fitted curves

The fitted values used by the objective remain the primary fit result:

```matlab
fitResult.frequency_Hz
fitResult.Cp_fit_mps
fitResult.validMask
```

`guiNormalizeFitResult` does not run the solver again. It builds `normalized.fullCurve` as a fit-consistent interpolation through the objective values:

```text
source = fitObjectiveInterpolation
solverEvaluated = false
```

The complete solver-evaluated curve is generated only when the user explicitly presses **Evaluate fitted curve**. That action calls `guiEvaluateRequestedFitCurve`, uses the final fitted parameters, resolves the selected numerical preset, and sets:

```matlab
options.forwardModel.gridPolicy = "numericalPreset";
```

This explicit curve evaluation does not call the optimizer. It also records consistency metrics between the fit-objective values and the requested full curve.

## Metadata

The canonical fit result retains the final public model evaluation under
`fitResult.modelEvaluation`. It also reports branch identity, requested
frequencies, fitted Cp values, valid mask, numerical preset, fit-grid policy,
and performance diagnostics. Effective engine names are neutral:

```text
etaS = 0  -> elastic_adaptive
etaS > 0  -> viscoelastic_adaptive
```

Historical names such as `fast_fit_atlas` and old atlas route names are not maintained metadata.

## Grid/path sensitivity

Re-evaluating fitted parameters on the same requested grid reproduces the saved
objective values. A solver evaluation on a different continuation grid can
differ slightly near sensitive low-frequency A0Like regions; an earlier review
observed approximately 0.14 m/s at one point near 1.78 kHz. This is a grid-path
diagnostic, not a second fitting route. The primary fitted curve remains
fit-consistent, while explicit requested-curve evaluation uses
`numericalPreset` and records consistency metadata.

## Validation

Run:

```matlab
run_mrlfe_fit_public_solver_tests
run_execution_profile_surface_tests
run_gui_smoke_tests
```

The focused suite checks public-solver routing, parameter regression, fit-grid policy, no automatic solver reevaluation during normalization, and explicit full-curve evaluation behavior.
