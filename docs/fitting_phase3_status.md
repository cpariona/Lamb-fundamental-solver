# Fitting Phase 3 status

This document records the first app-level fitting backend.

## Scope

Phase 3 adds a GUI/app-facing fitting backend without adding a visual GUI panel.

It adds:

```text
app/fitting/guiGetFitRegistry.m
app/fitting/guiBuildFitRequest.m
app/fitting/guiRunFit.m
app/fitting/guiNormalizeFitResult.m
app/fitting/guiPlotFitResult.m
app/adapters/guiFitRLSolver.m
```

It does not add:

```text
new visual controls in LambFundamental_GUI
mRLFE fitting
Acoustoelastic IOP/HGO fitting
multi-model comparison
file moves or structural refactors
```

## Backend flow

The app-level fitting flow is:

```text
guiBuildFitRequest
    -> guiRunFit
    -> model-specific fitting adapter
    -> model-specific fitting helper
    -> guiNormalizeFitResult
    -> guiPlotFitResult or export
```

For the first implemented model:

```text
guiRunFit
    -> guiFitRLSolver
    -> rlFitDispersionData
```

## Registry

`guiGetFitRegistry` exposes Rayleigh-Lamb fitting metadata:

```text
model family: rayleigh_lamb
branches: A0, S0
fit-capable parameters: mu, thickness
fixed-by-default parameters: rho, nu
```

The registry is intended to be the future source of truth for GUI parameter visibility, default values, display units, and bounds.

## Request contract

`guiBuildFitRequest` creates the app-level request with fields such as:

```matlab
request.modelFamily
request.branchName
request.mode
request.experimental
request.fixedParams
request.freeParams
request.initialGuess
request.bounds
request.controls
request.fitOptions
```

It validates that experimental data include:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
```

and blocks multi-parameter fitting when only one valid experimental point is available.

## Normalized result contract

`guiNormalizeFitResult` returns a GUI-facing normalized structure containing:

```matlab
normalized.modelFamily
normalized.modelName
normalized.branchName
normalized.freeParams
normalized.frequency_Hz
normalized.Cp_exp_mps
normalized.Cp_fit_mps
normalized.residuals_mps
normalized.validMask
normalized.bestParams
normalized.fixedParams
normalized.metrics
normalized.identifiability
normalized.optimizer
normalized.summaryTable
```

This structure is intended for plotting, table display, and export.

## Plot helper

`guiPlotFitResult` plots experimental data and fitted model output from the normalized result. It applies a physically reasonable y-axis margin to avoid visually amplifying numerical roundoff differences in exact synthetic fits.

## Test

A GUI fitting backend contract test was added:

```matlab
test_gui_fit_registry_contract
```

`run_gui_smoke_tests` now checks fitting backend functions on the MATLAB path and runs this test.

## Next phase

Phase 4 should add minimal visual GUI integration for Rayleigh-Lamb fitting using the Phase 3 backend.

The visual GUI should not reimplement model fitting. It should build a request and call:

```matlab
fitOutput = guiRunFit(request);
```
