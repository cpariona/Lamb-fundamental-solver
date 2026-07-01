# Fitting Phase 5 status

This document records the first mRLFE model-specific fitting implementation.

## Scope

Phase 5 adds mRLFE fitting helpers, app-level dispatch, an example, and synthetic recovery tests.

It adds:

```text
analysis/mrlfe/mrlfeBuildFitProblem.m
analysis/mrlfe/mrlfeEvaluateFitModel.m
analysis/mrlfe/mrlfeFitDispersionData.m
app/adapters/guiFitMRLFESolver.m
examples/mrlfe/fitting/fit_mrlfe_A0Like.m
tests/mrlfe/test_mrlfe_fit_synthetic_A0Like.m
docs/models/mrlfe/fitting_workflow.md
```

It updates:

```text
app/fitting/guiGetFitRegistry.m
app/fitting/guiRunFit.m
app/fitting/guiNormalizeFitResult.m
tests/run_core_smoke_tests.m
tests/run_gui_smoke_tests.m
tests/gui/test_gui_fit_registry_contract.m
docs/repository/maintained_entrypoints.md
```

It does not add:

```text
Acoustoelastic IOP/HGO fitting
visible mRLFE controls inside FitTool_GUI
viscous etaS fitting validation
multi-parameter mRLFE fitting validation
file moves or structural refactors
```

## First validated mRLFE fitting case

The first validated mRLFE case is:

```text
model family: mRLFE real-k
branch: A0Like
free parameter: mu
fixed parameters: thickness, rho, nu, fluid density, fluid sound speed
etaS: 0 Pa*s
```

`etaS = 0` is used as the first stable synthetic recovery case.

## App-level integration

The fitting registry now exposes both:

```text
rayleigh_lamb
mrlfe
```

The fitting dispatcher now routes:

```matlab
request.modelFamily = "mrlfe"
```

to:

```matlab
guiFitMRLFESolver
```

## Tests

Focused test:

```matlab
test_mrlfe_fit_synthetic_A0Like
```

GUI/backend contract test now includes mRLFE:

```matlab
test_gui_fit_registry_contract
```

Core smoke now checks the mRLFE fitting helper path and runs the synthetic mRLFE fitting test:

```matlab
run_core_smoke_tests
```

GUI smoke now checks the mRLFE fitting adapter path:

```matlab
run_gui_smoke_tests
```

## Example

Run:

```matlab
clear functions
rehash toolboxcache
startup
fit_mrlfe_A0Like
```

The result is assigned to the base workspace as:

```matlab
MRLFEA0LikeFitResult
```

## Next phase

Phase 6 should add Acoustoelastic IOP/HGO fitting using the official `atlasA0` output only.

The initial AE/HGO fitting target should remain conservative:

```text
branch: atlasA0
free parameter: mu, IOP, or thickness, one at a time initially
fixed parameters: R, rho, rhoF, fluidBulkModulus, k1, k2
```
