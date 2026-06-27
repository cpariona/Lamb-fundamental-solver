# mRLFE fitting workflow

This document records the first mRLFE dispersion fitting implementation and the current diagnostic path toward faster atlas/cache-based fitting.

## Scope

The current mRLFE fitting layer supports fitting experimental phase-speed data against the maintained mRLFE real-k workflow.

Implemented helpers:

```matlab
mrlfeBuildFitProblem
mrlfeEvaluateFitModel
mrlfeFitDispersionData
```

The first tested use case is:

```text
branch: A0Like
free parameter: mu
fixed parameters: thickness, rho, nu, fluid parameters
etaS: 0 Pa*s
```

`etaS = 0` is used for the first synthetic recovery test because it provides a stable baseline before validating viscous fitting.

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

`mrlfeEvaluateFitModel` evaluates mRLFE through the maintained Rayleigh-Lamb/mRLFE forward workflow. Since the base Rayleigh-Lamb solver validates that `numFrequencyPoints >= 10`, the fitting evaluator uses an internal solve grid with at least 10 points:

```matlab
params.fmin = min(frequency_Hz);
params.fmax = max(frequency_Hz);
params.numFrequencyPoints = max(10, numel(frequency_Hz));
params.frequencySpacing = "linspace";
```

The mRLFE branch is then interpolated back to the experimental fitting frequencies.

This allows sparse experimental fitting data, including fewer than 10 points, while preserving the base solver validation rule.

If only one fitting frequency is supplied, the evaluator creates a narrow internal frequency window around that point before interpolating back to the requested frequency.

The current implementation requires valid fitting frequencies to be sorted ascending.

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

The preset was chosen from `diagnose_fit_option_sensitivity`. For the A0Like elastic real-k baseline, `cpScanPoints = 500`, `trackingMinPoints = 10`, and `pointFactor = 1` gave a large speedup with sub-0.01 m/s RMS Cp difference relative to the 2200-point reference in the standard 1-8 kHz fitting window.

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

## etaS forward cache

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

## Direct viscous atlas evaluator

`mrlfeEvaluateFitModel` also exposes an optional direct viscous atlas path for A0Like real-k `etaS > 0` evaluations:

```matlab
solverOptions.mrlfeUseDirectViscoAtlas = true;
```

This path does not precompute or reuse an elastic mRLFE `etaS = 0` reference. It uses the Rayleigh-Lamb A0 seed only to define the modal family and Cp scan window, evaluates the viscous mRLFE residual directly over Cp, extracts candidate minima, refines the candidates locally, and selects a continuous branch through the DP tracker.

The default direct-atlas behavior inherits maintained viscous tracking names where possible:

```text
mrlfeViscoUseModalLocalTracker
mrlfeViscoA0ModalCpWindow
mrlfeViscoS0ModalCpWindow
mrlfeViscoPreviousCpMaxRelativeJump
mrlfeRealKStopAtFirstMissingModalMinimum
```

The DP candidate refinement is enabled for the direct viscous atlas path:

```text
mrlfeA0DPRefineCandidates = true
mrlfeA0DPRefineTolX = 1e-6
mrlfeA0DPRefineMaxIter = 24
mrlfeA0DPRefineMaxFunEvals = 60
```

Current diagnostic evidence from `diagnose_etaS_direct_atlas_fit` for the standard 1-8 kHz A0Like synthetic `etaS = 0.12 Pa*s` case:

```text
maintained no-cache  time = 26.1459 s | etaS = 0.120001 Pa*s | RMSE = 2.97413e-07 m/s
maintained cached    time = 15.5355 s | etaS = 0.120001 Pa*s | RMSE = 2.97413e-07 m/s
direct atlas         time = 4.51087 s | etaS = 0.120001 Pa*s | RMSE = 3.05837e-07 m/s
speedup atlas vs no-cache = 5.79619 x
speedup atlas vs cached   = 3.44402 x
RMSE atlas vs cached fitted Cp = 6.61039e-08 m/s
```

The direct atlas path is therefore the preferred experimental route for fast A0Like `etaS` fitting, but it should remain opt-in until broader sweeps validate the same behavior across material, thickness, and viscosity ranges.

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

## Current forward path and timing concern

The default fitting evaluator currently calls:

```text
mrlfeEvaluateFitModel
  -> rlComputeFundamentalLambModes
    -> Rayleigh-Lamb seed branch
    -> computeMRLFE
      -> solveMRLFEBranch / solveMRLFEBranchDP
```

For one-parameter fitting, `mrlfeFitDispersionData` repeatedly evaluates this full forward path through `fminbnd`. The fit can therefore be correct but slow if each objective evaluation recomputes Rayleigh-Lamb seeds, mRLFE residual scans, and branch tracking from scratch.

For A0-like elastic real-k mRLFE, `solveMRLFEBranchDP` performs a local Cp-landscape scan at each frequency and then selects a continuous branch through dynamic programming. This is conceptually close to a modal atlas over Cp for one parameter value.

## Timing diagnostic

Run:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_fit_timing
```

The diagnostic lives in:

```text
examples/mrlfe/diagnostics/diagnose_fit_timing.m
```

It reports:

```text
single forward-evaluation time
coarse RMSE landscape time over mu
current fminbnd fit time
optimizer function count
mRLFE solver diagnostic elapsed time
tracking point count
valid fraction across the objective landscape
```

The script assigns its output to the base workspace as:

```matlab
MRLFEFitTimingDiagnostic
```

The option-sensitivity diagnostic is:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_fit_option_sensitivity
```

It assigns:

```matlab
MRLFEFitOptionSensitivityDiagnostic
```

The etaS forward-cache diagnostic is:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_etaS_forward_cache
```

It assigns:

```matlab
MRLFEEtaSForwardCacheDiagnostic
```

The direct viscous atlas diagnostics are:

```matlab
clear functions
rehash toolboxcache
startup
diagnose_mrlfe_visco_direct_atlas
diagnose_etaS_direct_atlas_fit
```

They assign:

```matlab
MRLFEViscoDirectAtlasDiagnostic
MRLFEEtaSDirectAtlasFitDiagnostic
```

Use these diagnostics before promoting the direct atlas route from opt-in to default behavior.

## Optimizer policy

`mrlfeFitDispersionData` uses no Optimization Toolbox dependency.

Current behavior:

```text
one free parameter with finite bounds -> fminbnd
multi-parameter or unbounded case     -> fminsearch with bound penalties
```

## Candidate optimization directions

The next phase should focus on validation breadth and cleanup rather than adding another solver variant.

Candidate directions, in increasing implementation cost:

```text
1. Validate direct atlas etaS fitting across mu, thickness, etaS, and frequency-window sweeps.
2. Consolidate temporary mrlfeViscoAtlas* aliases into maintained viscous tracker naming where possible.
3. Reuse Rayleigh-Lamb seed branches when only mRLFE parameters change, if profiling still shows seed computation matters.
4. Expose the direct atlas route in GUI/registry only after sweep validation.
5. Build a true parameter-Cp atlas only if repeated fits over the same parameter bounds are needed.
```

The AE IOP/HGO atlas architecture is a useful reference for branch selection and reliability reporting, but mRLFE should not copy it mechanically. mRLFE already has a DP-based modal candidate tracker for A0-like branches, and the direct viscous atlas route now provides the first validated fast path for A0Like `etaS` fitting.

## Example

Run:

```matlab
clear functions
rehash toolboxcache
startup

fit_mrlfe_A0Like
```

The example lives in:

```text
examples/mrlfe/fit_mrlfe_A0Like.m
```

## Tests

Focused mRLFE fitting tests:

```matlab
test_mrlfe_fit_synthetic_A0Like
test_fit_validation_mrlfe
test_fit_validation_mrlfe_hidden_params
test_mrlfe_fit_fast_options_quality
test_mrlfe_etaS_fit_forward_cache
test_mrlfe_direct_visco_atlas_evaluator
test_mrlfe_direct_visco_atlas_modal_cut_policy
```

Shared validation suite:

```matlab
run_fit_validation_tests
```

## Current limitations

- Direct atlas etaS fitting is currently validated only for the standard synthetic A0Like 1-8 kHz case.
- Direct atlas integration is opt-in through `mrlfeUseDirectViscoAtlas`; it is not yet the default general mRLFE fitting route.
- The GUI fitting adapter enables direct atlas only for A0Like one-parameter etaS fitting.
- The code still contains temporary prototype aliases such as `mrlfeViscoAtlas*`; these should be consolidated during the mRLFE cleanup/renaming pass.
- Multi-parameter mRLFE fitting remains available through the shared fitting framework but has not yet received direct-atlas-specific validation.
- Experimental-data fitting should include physical QC; a mathematically low RMSE alone does not guarantee parameter identifiability.
