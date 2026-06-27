# Fitting Phase 2 status

This document records the first model-specific fitting implementation.

## Scope

Phase 2 adds Rayleigh-Lamb fitting helpers and a synthetic A0 recovery test.

It does not add:

```text
GUI fitting integration
mRLFE fitting
Acoustoelastic IOP/HGO fitting
multi-model fitting comparison
file moves or structural refactors
```

## Implemented Rayleigh-Lamb fitting helpers

The Rayleigh-Lamb fitting layer lives under:

```text
analysis/rayleigh_lamb/
```

Maintained helpers:

```matlab
rlBuildFitProblem
rlEvaluateFitModel
rlFitDispersionData
```

## Direct frequency-grid evaluation

`rlEvaluateFitModel` evaluates the Rayleigh-Lamb A0/S0 branches directly on the supplied experimental frequency vector.

This is different from the standard forward workflow, which builds a frequency vector from `fmin`, `fmax`, and spacing options. Direct fitting-grid evaluation is needed because experimental fitting may use:

```text
one frequency-speed pair
sparse frequency points
nonuniform frequencies
masked experimental points
```

The helper sorts the supplied frequencies for continuation and then restores the original order in the returned result.

## First validated fitting case

The first maintained fitting case is:

```text
model family: Rayleigh-Lamb
branch: A0
free parameter: mu
fixed parameters: thickness, rho, nu
```

The fitting test generates synthetic A0 data from a known `mu` and checks that the fitting helper recovers that value within tolerance.

## Optimizer policy

`rlFitDispersionData` uses no Optimization Toolbox dependency.

Current behavior:

```text
one free parameter with finite bounds -> fminbnd
multi-parameter or unbounded case     -> fminsearch with bound penalties
```

This keeps the first fitting backend lightweight while leaving room for later optimizer selection through the same request/result contract.

## Example

Run:

```matlab
clear functions
rehash toolboxcache
startup
fit_default_A0
```

The example exports the result to the base workspace as:

```matlab
RayleighLambA0FitResult
```

## Test

Run:

```matlab
clear functions
rehash toolboxcache
startup
test_rl_fit_synthetic_A0
```

`run_core_smoke_tests` now also checks the Rayleigh-Lamb fitting helpers and calls this synthetic A0 fitting test.

## Next phase

Phase 3 should add the app-level fitting backend without changing the model-specific Rayleigh-Lamb fitting contract:

```text
app/fitting/guiGetFitRegistry.m
app/fitting/guiBuildFitRequest.m
app/fitting/guiRunFit.m
app/fitting/guiNormalizeFitResult.m
app/fitting/guiPlotFitResult.m
```

The app layer should call `rlFitDispersionData` through a model-specific adapter rather than reimplementing fitting logic.
