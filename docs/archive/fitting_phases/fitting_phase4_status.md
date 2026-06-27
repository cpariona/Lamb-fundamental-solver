# Fitting Phase 4 status

This document records the first visual fitting interface.

## Scope

Phase 4 adds a minimal GUI for experimental dispersion fitting:

```matlab
FitTool_GUI
```

and a reusable visual tab builder:

```matlab
createFittingTab
```

The interface uses the Phase 3 app-level backend:

```text
FitTool_GUI
    -> createFittingTab
    -> guiBuildFitRequest
    -> guiRunFit
    -> guiFitRLSolver
    -> rlFitDispersionData
    -> guiNormalizeFitResult
    -> guiPlotFitResult
```

## Why a dedicated fitting GUI first

The fitting UI was introduced as a small dedicated GUI rather than directly modifying `LambFundamental_GUI`.

This keeps the stable forward-model GUI unchanged while the fitting workflow is validated visually. The same `createFittingTab` and app-level backend can later be embedded into `LambFundamental_GUI` as an additional tab if desired.

## Supported workflow

The first visual fitting workflow supports:

```text
model family: Rayleigh-Lamb
branches: A0, S0
free parameter: mu or thickness
fixed parameters: rho, nu, and the non-free parameter
input data: frequency_Hz, Cp_mps, Use(1/0)
```

The GUI allows the user to:

```text
enter experimental data manually in a table
generate synthetic data from the current fitting controls
select A0 or S0
select mu or thickness as the free parameter
set initial guess and finite bounds
run fitting
plot experimental data and fitted curve
view fit summary table
export the latest fit to the MATLAB base workspace as FitToolLastOutput
```

## Validation

Phase 4 updates `run_gui_smoke_tests` so it checks that these entrypoints are on the MATLAB path:

```matlab
FitTool_GUI
createFittingTab
```

The existing backend contract test remains the numerical validation target:

```matlab
test_gui_fit_registry_contract
```

## Manual visual validation

Run:

```matlab
clear functions
rehash toolboxcache
startup
FitTool_GUI
```

Then press:

```text
Generate synthetic from setup
Run fit
```

Expected behavior:

```text
The fitted model overlays the generated synthetic data.
The result table reports the fitted free parameter.
The fit status reports a small RMSE and locally_identifiable classification.
FitToolLastOutput appears in the MATLAB base workspace.
```

## Current limitations

This phase does not yet add:

```text
an embedded fitting tab inside LambFundamental_GUI
file import/export from CSV
standard-error weighted fitting in the visible GUI
mRLFE fitting
Acoustoelastic IOP/HGO fitting
multi-model comparison
parameter covariance/uncertainty estimates
```

## Next step

After visual validation of `FitTool_GUI`, the same `createFittingTab` controls can be embedded into the main `LambFundamental_GUI` if a single-window workflow remains preferred.
