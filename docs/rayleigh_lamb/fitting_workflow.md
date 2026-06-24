# Rayleigh-Lamb fitting workflow

This document records the first model-specific dispersion fitting implementation.

## Scope

The current Rayleigh-Lamb fitting layer supports fitting experimental phase-speed data against the maintained Rayleigh-Lamb residuals.

Implemented helpers:

```matlab
rlBuildFitProblem
rlEvaluateFitModel
rlFitDispersionData
```

The first tested use case is:

```text
branch: A0
free parameter: mu
fixed parameters: thickness, rho, nu
```

## Data contract

The fitting workflow uses the shared experimental data contract:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Only `frequency_Hz` and `Cp_mps` are required.

## Direct frequency-grid evaluation

`rlEvaluateFitModel` evaluates the Rayleigh-Lamb residuals directly on the supplied fitting frequency grid.

This is intentional. It avoids using `rlBuildFrequencyVector` for fitting and allows one-point fitting cases where only one frequency-speed pair is available.

The helper sorts the input frequencies for continuation, evaluates the branch, and returns results in the original input order.

## Optimizer policy

`rlFitDispersionData` currently uses:

```matlab
fminsearch
```

with objective penalties for out-of-bound candidates. This avoids requiring Optimization Toolbox during the first implementation.

Bounds are still declared in the fit configuration:

```matlab
fitConfig.bounds.mu = [20e3, 200e3];
```

A future implementation may add `lsqnonlin` or another optimizer through the same fit-result contract.

## Example

Run:

```matlab
clear functions
rehash toolboxcache
startup
fit_default_A0
```

The example generates synthetic A0 data with a known shear modulus and fits `mu` while keeping thickness, density, and Poisson ratio fixed.

## Test

Run:

```matlab
clear functions
rehash toolboxcache
startup
test_rl_fit_synthetic_A0
```

The test checks that the synthetic A0 fit recovers `mu` within tolerance.

`run_core_smoke_tests` also checks the Rayleigh-Lamb fitting helper path and runs this fitting test.

## Current limitations

This phase does not implement:

```text
GUI fitting integration
mRLFE fitting
Acoustoelastic IOP/HGO fitting
multi-model comparison
advanced optimizer selection
uncertainty estimates for fitted parameters
```

Multi-parameter fitting is structurally supported by the helper contracts, but the first maintained validation target is the one-parameter synthetic A0 case.
