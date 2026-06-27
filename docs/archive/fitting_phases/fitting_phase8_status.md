# Fitting Phase 8 status

This document records extended hidden-parameter fitting validation.

## Scope

Phase 8 adds validation cases for parameters that were intentionally not exposed in `FitTool_GUI` during Phase 7.

Updated backend files:

```text
analysis/mrlfe/mrlfeEvaluateFitModel.m
analysis/mrlfe/mrlfeBuildFitProblem.m
```

Added validation files:

```text
tests/fitting/test_fit_validation_mrlfe_hidden_params.m
tests/fitting/test_fit_validation_ae_iop_hgo_hidden_params.m
```

Updated validation runner:

```text
tests/fitting/run_fit_validation_tests.m
```

Updated documentation:

```text
docs/maintained_entrypoints.md
docs/fitting_phase8_status.md
```

## mRLFE changes

The mRLFE viscosity parameter `etaS` is stored internally under:

```matlab
solverOptions.mrlfeParams.etaS
```

For fitting, Phase 8 mirrors `etaS` into `baseParams` so the shared fitting helpers can pack and unpack it as a free parameter.

`mrlfeEvaluateFitModel` now propagates:

```matlab
params.etaS
```

back into:

```matlab
solverOptions.mrlfeParams.etaS
```

before evaluating the forward model.

## New mRLFE validation cases

```text
mRLFE_A0Like_thickness_exact
mRLFE_A0Like_etaS_exact
```

The `etaS` case is intentionally conservative. It validates whether the current real-k mRLFE phase-speed backend has enough sensitivity to recover `etaS` over the maintained frequency band.

## New AE IOP/HGO validation cases

```text
AE_atlasA0_thickness_exact
AE_atlasA0_IOP_exact
```

Both cases use the official production branch:

```text
atlasA0
```

and the same validated atlas configuration used in prior AE fitting tests.

Diagnostic branches are not used.

## Updated focused fitting validation suite

`run_fit_validation_tests` now executes five groups:

```text
Rayleigh-Lamb validation
mRLFE baseline validation
mRLFE hidden-parameter validation
AE IOP/HGO baseline validation
AE IOP/HGO hidden-parameter validation
```

The combined summary is assigned to:

```matlab
FitValidationSummary
```

with additional fields:

```matlab
FitValidationSummary.MRLFEHiddenParams
FitValidationSummary.AEIOPHGOHiddenParams
```

## GUI policy

Phase 8 does not expose any new parameter in `FitTool_GUI`.

Promotion to GUI should happen only after the new validation cases pass locally and the fitted values are physically reasonable.

## Suggested validation commands

```matlab
clear functions
rehash toolboxcache
startup

test_fit_validation_mrlfe_hidden_params
test_fit_validation_ae_iop_hgo_hidden_params
run_fit_validation_tests
```

Then run smoke tests:

```matlab
run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
```
