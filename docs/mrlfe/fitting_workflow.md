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

For one-parameter `etaS` fitting, `mrlfeBuildFitProblem` now precomputes the elastic `etaS = 0` real-k reference once and attaches it to:

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

## Current forward path and timing concern

The fitting evaluator currently calls:

```text
mrlfeEvaluateFitModel
  -> rlComputeFundamentalLambModes
    -> Rayleigh-Lamb seed branch
    -> computeMRLFE
      -> solveMRLFEBranch / solveMRLFEBranchDP
```

For one-parameter fitting, `mrlfeFitDispersionData` repeatedly evaluates this full forward path through `fminbnd`. The fit can therefore be correct but slow if each objective evaluation recomputes Rayleigh-Lamb seeds, mRLFE residual scans, and branch tracking from scratch.

For A0-like elastic real-k mRLFE, `solveMRLFEBranchDP` already performs a local Cp-landscape scan at each frequency and then selects a continuous branch through dynamic programming. This is conceptually close to a modal atlas over Cp for one parameter value. The next optimization phase should measure whether fitting time is dominated by:

```text
1. repeated Rayleigh-Lamb seed computation;
2. repeated mRLFE residual matrix evaluations over Cp;
3. dynamic-programming candidate extraction;
4. optimizer function-count rather than solver internals.
```

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

Use these diagnostics before implementing a deeper atlas/cache strategy. They should answer whether a lightweight fitting preset/cache is enough or whether a deeper mRLFE atlas evaluator is justified.

## Optimizer policy

`mrlfeFitDispersionData` uses no Optimization Toolbox dependency.

Current behavior:

```text
one free parameter with finite bounds -> fminbnd
multi-parameter or unbounded case     -> fminsearch with bound penalties
```

## Candidate optimization directions

The next phase should not change the already-working fit result until timing evidence is available.

Candidate directions, in increasing implementation cost:

```text
1. Cache parameter-independent solver setup inside a fitting problem.
2. Reuse Rayleigh-Lamb seed branches when only mRLFE parameters change.
3. Add a coarse-global mu scan plus local refinement to reduce expensive fminbnd calls.
4. Build an mRLFE Cp atlas per parameter candidate and expose diagnostic outputs similar to AE atlas reliability fields.
5. Build a true parameter-Cp atlas only if repeated fits over the same parameter bounds are needed.
```

The AE IOP/HGO atlas architecture is a useful reference for branch selection and reliability reporting, but mRLFE should not copy it mechanically. mRLFE already has a DP-based modal candidate tracker for A0-like branches, so the first likely win is a faster fitting preset and then targeted caching around the existing real-k workflow.

## Example

Run:

```matlab
clear functions
rehash toolboxcache
startup
fit_mrlfe_A0Like
```

The example generates synthetic A0-like data with a known shear modulus and fits `mu` while keeping thickness, density, Poisson ratio, and fluid parameters fixed.

## Test

Run:

```matlab
clear functions
rehash toolboxcache
startup
test_mrlfe_fit_synthetic_A0Like
test_mrlfe_fit_fast_options_quality
test_mrlfe_etaS_fit_forward_cache
```

The first test checks that the synthetic A0-like fit recovers `mu` within tolerance. The second compares the fast fitting preset against the high-cost reference and checks that the Cp difference remains small. The third verifies that `etaS` fitting attaches and uses a cached elastic reference.

`run_core_smoke_tests` also checks the mRLFE fitting helper path and runs the synthetic fitting test.

## App-level integration

The app-level fitting dispatcher now supports:

```matlab
guiRunFit(request)
```

with:

```matlab
request.modelFamily = "mrlfe";
request.branchName = "A0Like";
```

The mRLFE adapter is:

```matlab
guiFitMRLFESolver
```

## Current limitations

This phase does not implement:

```text
visible mRLFE controls inside FitTool_GUI
multi-parameter mRLFE fitting validation
S0Like fitting validation
uncertainty estimates for fitted parameters
mRLFE atlas/cache fitting evaluator
```

Multi-parameter fitting is structurally supported by the helper contracts, but the first maintained validation target is the one-parameter synthetic A0-like case.
