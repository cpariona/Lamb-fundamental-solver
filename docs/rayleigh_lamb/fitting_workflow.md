# Rayleigh-Lamb fitting workflow

This document records the Rayleigh-Lamb model-specific dispersion fitting implementation.

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

## Branch-coherent fitting evaluation

`rlEvaluateFitModel` now evaluates Rayleigh-Lamb fitting data using a branch-coherent internal tracking grid.

The evaluator:

```text
1. receives the requested experimental frequencies;
2. builds an internal frequency grid that starts from a low initialization frequency;
3. explicitly includes every requested fitting frequency in that grid;
4. evaluates the requested RL branch by continuation;
5. disables prediction fallback so predictor-only points are not used as fitting data;
6. samples the coherent branch only at the requested experimental frequencies;
7. returns diagnostics, reliability, and internal tracking arrays in `rawResult`.
```

This replaces the previous independent per-frequency search. The previous strategy avoided predictor fallback but could select valid roots from different modal branches at adjacent frequencies. That made `RMSE(mu)` irregular and could create narrow local minima unrelated to a single continuous A0 branch.

The maintained fitting output remains:

```matlab
[Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
```

Important `rawResult` fields:

```matlab
rawResult.trackingMode
rawResult.internalFrequency_Hz
rawResult.internalCp_mps
rawResult.internalResidual
rawResult.internalValidMask
rawResult.reliability
rawResult.diagnostics
```

The official fitting result uses `Cp_mps` sampled at `frequency_Hz`. Internal tracking arrays are diagnostic support, not separate fitting targets.

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

Fase 11A did not change the optimizer. The priority was to stabilize the forward model used by the optimizer. If the `RMSE(mu)` landscape remains irregular after branch-coherent evaluation, the next step should be a shared coarse-global plus local-refine optimizer policy in `analysis/fitting`, not model-specific optimizer logic inside GUI code.

## Example

Run:

```matlab
clear functions
rehash toolboxcache
startup
fit_default_A0
```

The example generates synthetic A0 data with a known shear modulus and fits `mu` while keeping thickness, density, and Poisson ratio fixed.

## Tests

Run:

```matlab
clear functions
rehash toolboxcache
startup
test_rl_fit_synthetic_A0
test_rl_fit_evaluator_branch_consistency
```

`test_rl_fit_synthetic_A0` checks that the synthetic A0 fit recovers `mu` within tolerance.

`test_rl_fit_evaluator_branch_consistency` compares `rlEvaluateFitModel` against the maintained A0 branch from `rlComputeFundamentalLambModes` and checks that the fitting evaluator reports the branch-coherent tracking mode without prediction fallback.

`run_core_smoke_tests` also checks the Rayleigh-Lamb fitting helper path and runs the maintained fitting tests.

## Current limitations

This phase does not implement:

```text
new optimizer policy
mRLFE branch-coherent fitting changes
fitting against multiple Rayleigh-Lamb branches simultaneously
advanced uncertainty estimates for fitted parameters
```

Multi-parameter fitting is structurally supported by the helper contracts, but the first maintained validation target remains the one-parameter synthetic A0 case.
