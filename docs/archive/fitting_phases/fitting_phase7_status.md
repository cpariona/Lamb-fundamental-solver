# Fitting Phase 7 status

This document records visible multi-model integration in `FitTool_GUI`.

## Scope

Phase 7 exposes the validated fitting backends in the visual fitting tool.

Updated files:

```text
app/FitTool_GUI.m
app/createFittingTab.m
tests/run_gui_smoke_tests.m
docs/repository/maintained_entrypoints.md
```

Added file:

```text
tests/gui/test_fit_tool_model_registry_contract.m
```

## Visible models

`FitTool_GUI` now exposes:

```text
Rayleigh-Lamb
mRLFE
AE IOP/HGO
```

The GUI still calls only the app-level backend:

```matlab
guiRunFit(request)
```

It does not implement model-specific fitting algorithms inside the GUI.

## Visible fitting parameters

Only parameters validated by the focused fitting validation suite are exposed visually:

```text
Rayleigh-Lamb: mu, thickness
mRLFE: mu
AE IOP/HGO: mu
```

The following remain hidden until additional validation cases are added:

```text
mRLFE etaS
mRLFE thickness
AE IOP
AE thickness
AE multiparameter fitting
```

## Branch policy

Visible AE IOP/HGO fitting uses only:

```text
atlasA0
```

No diagnostic branches are exposed or used by `FitTool_GUI`.

## Synthetic data generation

The `Generate synthetic from setup` button is now model-aware:

```text
Rayleigh-Lamb: uses rlEvaluateFitModel
mRLFE: uses mrlfeEvaluateFitModel with A0Like and etaS = 0 Pa*s
AE IOP/HGO: uses aeEvaluateFitModel with atlasA0 and validated atlas settings
```

## Test

A noninteractive contract test was added:

```matlab
test_fit_tool_model_registry_contract
```

It validates that the FitTool model dropdown exposes all three model families.

`run_gui_smoke_tests` now runs this contract test.

## Manual validation

Run:

```matlab
clear functions
rehash toolboxcache
startup
FitTool_GUI
```

Then validate each model manually:

```text
1. Select model.
2. Click Generate synthetic from setup.
3. Click Run fit.
4. Confirm fitted curve overlays synthetic points.
5. Confirm FitToolLastOutput appears in the MATLAB base workspace.
```

## Next recommended phase

Before exposing more GUI controls, add validation cases for:

```text
AE IOP fitting
AE thickness fitting
mRLFE etaS fitting
mRLFE thickness fitting
```

Only then should these parameters be promoted to visible FitTool controls.
