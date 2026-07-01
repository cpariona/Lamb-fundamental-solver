# Fitting Phase 9 status

This document records promotion of validated hidden parameters to visible `FitTool_GUI` controls.

## Scope

Phase 9 promotes parameters that passed the focused validation suite in Phase 8.

Updated files:

```text
app/FitTool_GUI.m
app/createFittingTab.m
tests/gui/test_fit_tool_model_registry_contract.m
docs/repository/maintained_entrypoints.md
```

Added file:

```text
docs/fitting_phase9_status.md
```

## Visible one-parameter fitting controls

`FitTool_GUI` now exposes:

```text
Rayleigh-Lamb: mu, thickness
mRLFE: mu, thickness, etaS
AE IOP/HGO: mu, thickness, IOP
```

Each fitting run still allows one free parameter at a time.

## mRLFE GUI behavior

Visible mRLFE parameters:

```text
mu
thickness
etaS
```

The GUI uses:

```text
branch: A0Like
etaS fixed to 0 Pa*s when fitting mu or thickness
mu and thickness fixed when fitting etaS
```

Synthetic mRLFE data generation is parameter-aware:

```text
mu synthetic data varies mu
thickness synthetic data varies thickness
etaS synthetic data varies etaS
```

## AE IOP/HGO GUI behavior

Visible AE IOP/HGO parameters:

```text
mu
thickness
IOP
```

The GUI uses only:

```text
atlasA0
```

with the validated atlas configuration:

```matlab
atlasNumYPoints = 300
atlasTopNMinima = 12
atlasInitializationNumFrequencyPoints = 50
```

Diagnostic branches remain hidden and are not used.

## Still hidden

The following remain hidden:

```text
multi-parameter fitting
mRLFE S0Like hidden-parameter validation
AE multiparameter fitting
HGO k1/k2 fitting
fluid parameter fitting
weighted fitting controls
```

## Test update

`test_fit_tool_model_registry_contract` now checks that the fitting registry exposes promoted parameters as fit-capable:

```text
Rayleigh-Lamb: mu, thickness
mRLFE: mu, thickness, etaS
AE IOP/HGO: mu, thickness, IOP
```

`run_gui_smoke_tests` already runs this test.

## Manual validation

Run:

```matlab
clear functions
rehash toolboxcache
startup
FitTool_GUI
```

For each promoted parameter:

```text
1. Select model.
2. Select free parameter.
3. Click Generate synthetic from setup.
4. Click Run fit.
5. Check overlay and FitToolLastOutput.
```

Recommended minimum manual sweep:

```text
Rayleigh-Lamb: mu, thickness
mRLFE: mu, thickness, etaS
AE IOP/HGO: mu, thickness, IOP
```

## Recommended next phase

Phase 10 should add file import/export and result export instead of adding more model complexity.

Recommended scope:

```text
Import CSV: frequency_Hz, Cp_mps, Use, optional standardError_Cp_mps
Export fitted curve CSV
Export summary table CSV
Export current figure
```
