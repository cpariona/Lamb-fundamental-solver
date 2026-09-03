# Rayleigh-Lamb fitting workflow

This document records the Rayleigh-Lamb model-specific dispersion fitting implementation.

## Scope

The current Rayleigh-Lamb fitting layer supports fitting experimental phase-speed data against the maintained Rayleigh-Lamb residuals.

Implemented helpers:

```matlab
rlBuildFitProblem
rlEvaluateFitModel
rlFitDispersionData
solveDispersionFitProblem
```

The first maintained tested use case is:

```text
branch: A0
free parameter: mu
fixed parameters: thickness, rho, nu
```

Additional synthetic fitting validation cases are covered by `run_fit_validation_tests`.

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

`rlEvaluateFitModel` evaluates Rayleigh-Lamb fitting data using a branch-coherent internal tracking grid.

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

`rlFitDispersionData` builds the model-specific problem and delegates optimizer
orchestration to `solveDispersionFitProblem`. One finite-bounded free parameter
uses `fminbnd`; multi-parameter or unbounded cases use `fminsearch` with bound
penalties. No Optimization Toolbox dependency is required.

Bounds are still declared in the fit configuration:

```matlab
fitConfig.bounds.mu = [20e3, 200e3];
```

The exact RL iteration limits and tolerances remain owned by
`rlBuildFitProblem`; the shared owner does not replace model-specific defaults.

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

Core smoke validation runs:

```matlab
clear functions
rehash toolboxcache
startup
run_core_smoke_tests
```

The core runner checks Rayleigh-Lamb API/helper path coverage and runs:

```matlab
test_rl_fit_synthetic_A0
```

Focused fitting validation runs:

```matlab
run_fit_validation_tests
```

Rayleigh-Lamb cases inside the focused validation suite include:

```text
RL_A0_mu_exact
RL_A0_thickness_exact
RL_A0_mu_perturbed
```

Use the focused suite after fitting-related changes. Use the core smoke suite after path/API or Rayleigh-Lamb baseline changes.

## Current limitations

This phase does not implement:

```text
new optimizer policy
fitting against multiple Rayleigh-Lamb branches simultaneously
advanced uncertainty estimates for fitted parameters
```

Multi-parameter fitting is structurally supported by the helper contracts, but the maintained validation targets remain synthetic single-parameter cases.
