# mRLFE fitting workflow

This document records the first mRLFE dispersion fitting implementation.

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

`mrlfeEvaluateFitModel` evaluates mRLFE on the supplied fitting frequency range by setting:

```matlab
params.fmin = min(frequency_Hz);
params.fmax = max(frequency_Hz);
params.numFrequencyPoints = numel(frequency_Hz);
params.frequencySpacing = "linspace";
```

The first implementation requires valid fitting frequencies to be sorted ascending.

## Optimizer policy

`mrlfeFitDispersionData` uses no Optimization Toolbox dependency.

Current behavior:

```text
one free parameter with finite bounds -> fminbnd
multi-parameter or unbounded case     -> fminsearch with bound penalties
```

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
```

The test checks that the synthetic A0-like fit recovers `mu` within tolerance.

`run_core_smoke_tests` also checks the mRLFE fitting helper path and runs this fitting test.

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
viscous etaS fitting validation
multi-parameter mRLFE fitting validation
S0Like fitting validation
uncertainty estimates for fitted parameters
```

Multi-parameter fitting is structurally supported by the helper contracts, but the first maintained validation target is the one-parameter synthetic A0-like case.
