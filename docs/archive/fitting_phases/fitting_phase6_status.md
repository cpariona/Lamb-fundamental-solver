# Fitting Phase 6 status

This document records the first Acoustoelastic IOP/HGO model-specific fitting implementation.

## Scope

Phase 6 adds AE IOP/HGO fitting helpers, app-level dispatch, an example, and a synthetic atlasA0 recovery test.

It adds:

```text
analysis/acoustoelastic_iop_hgo/aeBuildFitProblem.m
analysis/acoustoelastic_iop_hgo/aeEvaluateFitModel.m
analysis/acoustoelastic_iop_hgo/aeFitDispersionData.m
app/adapters/guiFitAcoustoelasticIOPHGOSolver.m
examples/acoustoelastic_iop_hgo/fitting/fit_ae_atlasA0.m
tests/acoustoelastic_iop_hgo/test_ae_fit_synthetic_atlasA0.m
docs/models/acoustoelastic_iop_hgo/fitting_workflow.md
```

It updates:

```text
app/fitting/guiGetFitRegistry.m
app/fitting/guiRunFit.m
app/fitting/guiNormalizeFitResult.m
tests/run_acoustoelastic_smoke_tests.m
tests/run_gui_smoke_tests.m
tests/gui/test_gui_fit_registry_contract.m
docs/repository/maintained_entrypoints.md
```

It does not add:

```text
visible AE controls inside FitTool_GUI
multi-parameter AE fitting validation
IOP or thickness fitting validation
fitting against diagnostic branches
file moves or structural refactors
```

## First validated AE fitting case

The first validated case is:

```text
model family: AE IOP/HGO
branch: atlasA0
free parameter: mu
fixed parameters: IOP, thickness, R, k1, k2, rho, rhoF, fluidBulkModulus
```

## Branch-policy guard

The fitting implementation explicitly uses only official atlas output:

```matlab
result.Cp
result.validCp
```

from:

```matlab
solveAcoustoelasticIOPHGOAtlasBranch
```

It does not fit diagnostic branches.

## App-level integration

The fitting registry now exposes:

```text
rayleigh_lamb
mrlfe
acoustoelastic_iop_hgo
```

The fitting dispatcher routes:

```matlab
request.modelFamily = "acoustoelastic_iop_hgo"
```

to:

```matlab
guiFitAcoustoelasticIOPHGOSolver
```

## Tests

Focused test:

```matlab
test_ae_fit_synthetic_atlasA0
```

Registry contract now verifies that the AE IOP/HGO family and `atlasA0` branch are exposed:

```matlab
test_gui_fit_registry_contract
```

Acoustoelastic smoke now checks the AE fitting helper path and runs the synthetic fitting test:

```matlab
run_acoustoelastic_smoke_tests
```

GUI smoke checks the AE fitting adapter path:

```matlab
run_gui_smoke_tests
```

## Example

Run:

```matlab
clear functions
rehash toolboxcache
startup
fit_ae_atlasA0
```

The result is assigned to the base workspace as:

```matlab
AEAtlasA0FitResult
```

## Next phase

A future phase may expose AE IOP/HGO in `FitTool_GUI`, but this should follow manual validation of the backend and synthetic example.

Subsequent fitting validation should evaluate one parameter at a time:

```text
mu
IOP
thickness
```

before enabling multi-parameter AE fitting.
