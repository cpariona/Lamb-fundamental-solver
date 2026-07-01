# mRLFE fitting workflow

This document records the maintained mRLFE dispersion fitting workflow after the FitTool route-consistency and visualization updates.

## Scope

The mRLFE fitting layer supports one-parameter fits against real-k mRLFE A0-like and S0-like atlas branches through these helpers:

```matlab
mrlfeBuildFitProblem
mrlfeEvaluateFitModel
mrlfeEvaluateAtlasFitModel
mrlfeFitDispersionData
```

Supported one-parameter fitting cases include:

```text
branch: A0Like or S0Like
free parameter: mu, thickness, or etaS
fixed parameters: remaining elastic/geometric parameters, rho, nu, fluid parameters
```

For `mu` and `thickness` fits, `etaS` may be fixed. In `FitTool_GUI`, this value is exposed as `Fixed etaS [Pa*s]` when `etaS` is not the free parameter.

## Data contract

The fitting workflow uses the shared experimental data contract:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Only `frequency_Hz` and `Cp_mps` are required.

## Atlas-first route policy

The maintained mRLFE fitting route is atlas-first, analogous to AE IOP/HGO fitting:

```text
mrlfeFitDispersionData
  -> mrlfeBuildFitProblem
  -> mrlfeEvaluateFitModel
  -> mrlfeEvaluateAtlasFitModel
  -> official mRLFE atlas branch output
```

The fitting evaluator no longer treats the old reference/DP workflow as the default fitting surface. The old workflow remains available only for explicit diagnostic calls with:

```matlab
solverOptions.mrlfeUseAtlasFitRoute = false;
```

The default fitting route reports:

```matlab
rawResult.evaluationPath.routeFamily == "atlas"
rawResult.evaluationPath.expectedPath == "mrlfe_atlas"
rawResult.evaluationPath.usedAtlasFitRoute == true
```

The actual path depends on viscosity:

```text
etaS = 0  -> zero_viscosity_adaptive_atlas
etaS > 0  -> viscous_unified_atlas
```

## Relation to AE fitting

The AE IOP/HGO fitting workflow uses `aeEvaluateFitModel`, which evaluates the official `atlasA0` output and excludes diagnostic branches from fitting. mRLFE fitting follows the same architectural idea, but supports both maintained mRLFE branches:

```text
AE:    atlasA0 only
mRLFE: A0Like and S0Like
```

The Rayleigh-Lamb solution is still used as an atlas seed where needed, but it is not the reported fitting route.

## Frequency-grid policy

`mrlfeEvaluateAtlasFitModel` evaluates mRLFE on an internal solve grid and interpolates back to the requested fitting frequencies. Since the base Rayleigh-Lamb seed solver validates that `numFrequencyPoints >= 10`, the fitting evaluator uses at least 10 internal points:

```matlab
params.fmin = min(frequency_Hz);
params.fmax = max(frequency_Hz);
params.numFrequencyPoints = max(10, numel(frequency_Hz));
params.frequencySpacing = "linspace";
```

This allows sparse experimental fitting data, including fewer than 10 points, while preserving the base solver validation rule. The current implementation requires fitting frequencies to be sorted ascending.

## Zero-viscosity atlas fitting route

For `etaS = 0`, fitting uses the zero-viscosity adaptive atlas route:

```text
Rayleigh-Lamb seed
  -> mrlfeMakePhysicalSeedMode
  -> solveMRLFEBranchAdaptiveAtlas
  -> optional A0 physical-tail corridor cut
  -> official A0Like/S0Like fit branch
```

For A0Like FitTool fitting, the current default A0 policy is:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

The route reports:

```matlab
rawResult.evaluationPath.path == "zero_viscosity_adaptive_atlas"
```

## Viscous atlas fitting route

For `etaS > 0`, fitting uses the unified viscous atlas route:

```text
Rayleigh-Lamb seed
  -> solveMRLFEAtlasUnified
  -> official A0Like/S0Like fit branch
```

The route reports:

```matlab
rawResult.evaluationPath.path == "viscous_unified_atlas"
```

## FitTool adapter contract

`guiFitMRLFESolver` defaults to atlas fitting:

```matlab
controls.mrlfeUseUnifiedAtlasRoute = true;
controls.mrlfeUseAtlasFitRoute = true;
controls.mrlfeA0Policy = "adaptivePhysicalTail";
solverOptions.mrlfeFitAtlasPreset = "fast_fit_atlas";
```

The GUI fit output exposes:

```matlab
fitOutput.routePolicy.routeFamily
fitOutput.routePolicy.expectedPath
fitOutput.routePolicy.actualPath
fitOutput.routePolicy.mrlfeA0Policy
fitOutput.routePolicy.fitAtlasPreset
fitOutput.routePolicy.etaS
```

Expected FitTool route metadata:

```matlab
fitOutput.routePolicy.routeFamily == "atlas"
fitOutput.routePolicy.expectedPath == "mrlfe_atlas"
```

Actual path examples:

```matlab
fitOutput.routePolicy.actualPath == "zero_viscosity_adaptive_atlas"
fitOutput.routePolicy.actualPath == "viscous_unified_atlas"
```

## FitTool fitted-curve policy

The primary FitTool curve is fit-consistent. It interpolates the solver values used by the objective function at the experimental frequencies. This avoids silently plotting a second branch-continuation path as if it were the fitted curve.

Dense solver re-evaluation is still computed and stored as diagnostic metadata:

```matlab
normalized.fullCurve.denseSolver
normalized.fullCurve.denseSolver.maxAbsDenseMinusFit_mps
normalized.fullCurve.denseSolver.hasGridMismatch
normalized.fullCurve.denseSolver.warningMessage
```

If dense re-evaluation differs from the fit-consistent values beyond the configured threshold, the FitTool status reports a dense/grid mismatch. See:

```text
docs/models/mrlfe/fittool_grid_path_sensitivity.md
```

## Fit atlas preset

The fitting route applies a reduced atlas preset for iterative optimization:

```matlab
solverOptions.mrlfeFitAtlasPreset = "fast_fit_atlas";
solverOptions.mrlfeA0DPCpScanPoints = 260;
solverOptions.mrlfeViscoAtlasCpScanPoints = 260;
solverOptions.mrlfeAdaptiveCpScanPoints = 260;
solverOptions.mrlfeA0DPCandidates = 5;
solverOptions.mrlfeA0DPRefineCandidates = false;
solverOptions.mrlfeAdaptiveRefineCandidates = false;
solverOptions.mrlfeAdaptiveWindows = [0.20 0.40 0.80];
```

Dense diagnostics and validation sweeps may override these values explicitly.

## Legacy diagnostic route

The previous reference/direct-viscous fitting workflow is retained only for explicit diagnostics:

```matlab
solverOptions.mrlfeUseAtlasFitRoute = false;
```

When disabled, `mrlfeEvaluateFitModel` falls back to the legacy evaluator and reports:

```text
direct_viscous_atlas
maintained_rl_mrlfe_workflow
unified_atlas
```

This is no longer the maintained FitTool default.

## Validation

Relevant GUI fitting contracts:

```matlab
test_gui_mrlfe_fit_route_policy_contract
test_gui_mrlfe_fixed_etaS_fit_contract
test_gui_mrlfe_fit_zero_eta_atlas_contract
test_gui_mrlfe_unified_atlas_policy_contract
test_gui_mrlfe_fit_full_curve_fast_contract
```

Recommended local validation:

```matlab
clear; clc; close all;
startup
run_mrlfe_fit_atlas_tests
run_gui_smoke_tests
run_mrlfe_atlas_tests
```

These tests are route and synthetic-contract checks. They do not claim FEM or experimental validation.
