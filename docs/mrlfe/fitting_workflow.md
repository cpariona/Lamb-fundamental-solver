# mRLFE fitting workflow

This document records the maintained mRLFE dispersion fitting workflow and the currently validated acceleration routes for fitting.

## Scope

The mRLFE fitting layer supports fitting experimental phase-speed data against real-k mRLFE A0-like and S0-like branches through these helpers:

```matlab
mrlfeBuildFitProblem
mrlfeEvaluateFitModel
mrlfeFitDispersionData
```

The fitting implementation supports one-parameter fits such as:

```text
branch: A0Like
free parameter: mu, thickness, or etaS
fixed parameters: remaining elastic/geometric parameters, rho, nu, fluid parameters
```

For `mu` and `thickness` fits, `etaS` may be fixed. In `FitTool_GUI`, the fixed viscosity is exposed as `Fixed etaS [Pa*s]` when `etaS` is not the free parameter.

## Data contract

The fitting workflow uses the shared experimental data contract:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Only `frequency_Hz` and `Cp_mps` are required.

## Frequency-grid policy

`mrlfeEvaluateFitModel` evaluates mRLFE on an internal solve grid and interpolates back to the requested fitting frequencies. Since the base Rayleigh-Lamb solver validates that `numFrequencyPoints >= 10`, the fitting evaluator uses at least 10 internal points:

```matlab
params.fmin = min(frequency_Hz);
params.fmax = max(frequency_Hz);
params.numFrequencyPoints = max(10, numel(frequency_Hz));
params.frequencySpacing = "linspace";
```

This allows sparse experimental fitting data, including fewer than 10 points, while preserving the base solver validation rule. If only one fitting frequency is supplied, the evaluator creates a narrow internal frequency window around that point before interpolating back to the requested frequency.

The current implementation requires valid fitting frequencies to be sorted ascending.

## Route taxonomy

The code currently distinguishes three mRLFE fitting routes.

### 1. Maintained/reference-based workflow

This is the general mRLFE forward workflow:

```text
mrlfeEvaluateFitModel
  -> rlComputeFundamentalLambModes
    -> Rayleigh-Lamb seed branch
    -> computeMRLFE
      -> solveMRLFEBranch / solveMRLFEBranchDP
```

It is the maintained default for general mRLFE evaluations, for `mu`/`thickness` fitting, and for S0Like. It remains the conservative route for cases that have not been specifically validated with the direct atlas.

The raw result reports this route as:

```matlab
rawResult.evaluationPath.path == "maintained_rl_mrlfe_workflow"
```

### 2. etaS elastic-reference forward cache

For one-parameter `etaS` fitting, `mrlfeBuildFitProblem` can precompute the elastic `etaS = 0` real-k reference once and attach it to:

```matlab
solverOptions.mrlfeElasticReferenceResult
```

This cache is useful because the viscous fit changes `etaS` but keeps the elastic material and geometry fixed:

```text
changes during fit: etaS
fixed during fit:   mu, thickness, rho, nu, frequency grid
```

Without the cache, the viscous real-k path can recompute the elastic reference during each objective evaluation. With the cache, every viscous evaluation can reuse the same elastic reference branch.

The cache is enabled only when:

```text
freeParams == "etaS"
solverOptions.mrlfeElasticReferenceResult is not already provided
solverOptions.mrlfeDisableForwardCache is not true
```

The fit result exposes cache diagnostics through:

```matlab
fitResult.problem.forwardCache
```

To disable this cache explicitly:

```matlab
solverOptions.mrlfeDisableForwardCache = true;
```

### 3. Direct viscous atlas evaluator

`mrlfeEvaluateFitModel` also exposes an optional direct viscous atlas path for A0Like real-k `etaS > 0` evaluations:

```matlab
solverOptions.mrlfeUseDirectViscoAtlas = true;
```

This path does not precompute or reuse an elastic mRLFE `etaS = 0` reference. It uses the Rayleigh-Lamb A0 seed only to define the modal family and Cp scan window, evaluates the viscous mRLFE residual directly over Cp, extracts candidate minima, refines the candidates locally, and selects a continuous branch through the DP tracker.

The raw output distinguishes the requested route from the route actually used:

```matlab
rawResult.evaluationPath.requestedDirectViscoAtlas
rawResult.evaluationPath.usedDirectViscoAtlas
rawResult.evaluationPath.path
```

For the validated A0Like etaS case:

```matlab
rawResult.evaluationPath.path == "direct_viscous_atlas"
rawResult.branch.viscoAtlas.usedElasticMRLFEReference == false
```

For S0Like, requesting `mrlfeUseDirectViscoAtlas = true` currently falls back to the maintained workflow and reports:

```matlab
rawResult.evaluationPath.requestedDirectViscoAtlas == true
rawResult.evaluationPath.usedDirectViscoAtlas == false
rawResult.evaluationPath.path == "maintained_rl_mrlfe_workflow"
```

The GUI fitting adapter enables the direct atlas only for the validated case:

```text
branchName == "A0Like"
freeParams == "etaS"
```

## Direct atlas option naming

The maintained/canonical option names for the direct viscous atlas route are the existing DP and viscous tracking names:

```text
mrlfeA0DPCpScanPoints
mrlfeA0DPCandidates
mrlfeA0DPEdgeGuardPoints
mrlfeA0DPCpMinFactor
mrlfeA0DPCpMaxFactor
mrlfeA0DPCpMinFloor
mrlfeA0DPCpMaxCeiling
mrlfeA0DPSeedWeight
mrlfeA0DPResidualWeight
mrlfeA0DPJumpWeight
mrlfeA0DPCurvatureWeight
mrlfeA0DPMaxJumpSoft
mrlfeA0DPMissingPenalty
mrlfeA0DPAllowMissing
mrlfeResidualTolerance
mrlfeA0DPRefineCandidates
mrlfeA0DPRefineTolX
mrlfeA0DPRefineMaxIter
mrlfeA0DPRefineMaxFunEvals
mrlfeViscoUseModalLocalTracker
mrlfeViscoA0ModalCpWindow
mrlfeViscoS0ModalCpWindow
mrlfeViscoPreviousCpMaxRelativeJump
mrlfeRealKStopAtFirstMissingModalMinimum
```

Older `mrlfeViscoAtlas*` fields are compatibility aliases only. New diagnostics and tests should use the canonical names above. If both a canonical field and its legacy alias are present, the canonical field takes priority.

The DP candidate refinement is enabled for the direct viscous atlas path:

```text
mrlfeA0DPRefineCandidates = true
mrlfeA0DPRefineTolX = 1e-6
mrlfeA0DPRefineMaxIter = 24
mrlfeA0DPRefineMaxFunEvals = 60
```

## Fast fitting performance preset

`mrlfeEvaluateFitModel` applies fitting-specific performance defaults by default only for the elastic A0Like real-k case (`etaS = 0`). These defaults affect only the fitting evaluator, not general mRLFE sweeps.

Default elastic A0Like fitting preset:

```text
mrlfeUseFitPerformanceDefaults = true
mrlfeFitPerformancePreset = fast_elastic_A0Like
mrlfeUseInternalTrackingGrid = true
mrlfeInternalTrackingMinPoints = 10
mrlfeInternalTrackingPointFactor = 1
mrlfeInternalTrackingMaxPoints = 80
mrlfeA0DPCpScanPoints = 500
mrlfeA0DPCandidates = 8
```

To disable the fitting preset and use explicit solver options exactly:

```matlab
solverOptions.mrlfeUseFitPerformanceDefaults = false;
```

To keep the preset but override individual fitting defaults:

```matlab
solverOptions.mrlfeFitA0DPCpScanPoints = 800;
solverOptions.mrlfeFitInternalTrackingMinPoints = 20;
solverOptions.mrlfeFitInternalTrackingPointFactor = 1;
solverOptions.mrlfeFitInternalTrackingMaxPoints = 80;
```

The raw output exposes the applied preset through:

```matlab
rawResult.fitPerformanceDefaults
```

## Current diagnostic evidence

Current diagnostic evidence from `diagnose_etaS_direct_atlas_fit` for the standard 1-8 kHz A0Like synthetic `etaS = 0.12 Pa*s` case:

```text
maintained no-cache  time = 26.1459 s | etaS = 0.120001 Pa*s | RMSE = 2.97413e-07 m/s
maintained cached    time = 15.5355 s | etaS = 0.120001 Pa*s | RMSE = 2.97413e-07 m/s
direct atlas         time = 4.51087 s | etaS = 0.120001 Pa*s | RMSE = 3.05837e-07 m/s
speedup atlas vs no-cache = 5.79619 x
speedup atlas vs cached   = 3.44402 x
RMSE atlas vs cached fitted Cp = 6.61039e-08 m/s
```

The direct atlas path is therefore the preferred experimental route for fast A0Like `etaS` fitting, but it should remain scoped to the validated case until broader sweeps validate the same behavior across material, thickness, and viscosity ranges.

## Diagnostics

Timing diagnostic:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_fit_timing
```

Assigned output:

```matlab
MRLFEFitTimingDiagnostic
```

Option-sensitivity diagnostic:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_fit_option_sensitivity
```

Assigned output:

```matlab
MRLFEFitOptionSensitivityDiagnostic
```

etaS forward-cache diagnostic:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_etaS_forward_cache
```

Assigned output:

```matlab
MRLFEEtaSForwardCacheDiagnostic
```

Direct atlas fitting diagnostic:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_etaS_direct_atlas_fit
```

Assigned output:

```matlab
MRLFEEtaSDirectAtlasFitDiagnostic
```

Direct atlas forward diagnostic:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_mrlfe_visco_direct_atlas
```

Assigned output:

```matlab
MRLFEViscoDirectAtlasDiagnostic
```

## Current limitations

```text
- Direct atlas etaS fitting is validated only for A0Like in the standard 1-8 kHz synthetic case.
- S0Like direct atlas is intentionally disabled until separately validated.
- LambFundamental_GUI still uses the maintained forward workflow for general mRLFE branch computation.
- Sweep GUI integration with direct atlas is not part of this cleanup phase.
```
