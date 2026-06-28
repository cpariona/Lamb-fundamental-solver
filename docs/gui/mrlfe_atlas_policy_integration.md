# mRLFE atlas policy GUI integration

This document records the GUI-facing integration of the unified real-k mRLFE atlas route.

## Scope

The integration applies to the mRLFE real-k workflow in:

```text
LambFundamental_GUI
SweepTool_GUI
FitTool_GUI
```

and to the GUI/backend adapters:

```text
app/adapters/guiRunMRLFEModel.m
app/adapters/guiRunMRLFESweep.m
app/adapters/guiFitMRLFESolver.m
analysis/mrlfe/mrlfeEvaluateFitModel.m
```

The goal is not to claim external physical validation. The goal is to ensure that GUI requests can explicitly reach the maintained unified real-k atlas route and preserve the selected A0 policy in metadata.

## Supported A0 policies

The GUI exposes the same high-level A0 policy selector used by the solver:

```matlab
options.mrlfeA0Policy = "delayedCut";
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

Current interpretation:

| Policy | Use |
| --- | --- |
| `delayedCut` | Conservative/default A0 policy. |
| `adaptivePhysicalTail` | Opt-in policy for difficult soft, viscous, fluid-loaded A0-like branches. |

The GUI should not silently make `adaptivePhysicalTail` the global default.

## Main GUI contract

The main GUI reads the mRLFE tab controls and sets:

```matlab
options.mrlfeUseUnifiedAtlasRoute = options.mrlfeParams.etaS > 0;
options.mrlfeA0Policy = string(modelControls.mrlfe.a0Policy.Value);
```

The main GUI adapter uses a lightweight route:

```text
Rayleigh-Lamb seed branch
    -> computeMRLFE
    -> mRLFERealK only
    -> normalized GUI branch
```

It should not compute and register all mRLFE internal variants for routine plotting. The GUI-visible model should be:

```text
mRLFERealK
```

The raw/internal result may preserve Rayleigh-Lamb seed branches, but routine GUI computation should not produce redundant `mRLFEElasticRealK` and `mRLFEViscoRealK` branches when only `mRLFERealK` is requested.

The model adapter preserves the route and policy metadata:

```matlab
result.metadata.mrlfeUseUnifiedAtlasRoute
result.metadata.mrlfeA0Policy
result.diagnostics.mrlfeUseUnifiedAtlasRoute
result.diagnostics.mrlfeA0Policy
```

The plotting surface remains normalized. Rayleigh-Lamb seed branches may exist in `metadata.rawResult`, but they should not appear as mRLFE plot branches.

## Sweep GUI contract

The SweepTool mRLFE adapter receives controls:

```matlab
controls.mrlfeUseUnifiedAtlasRoute
controls.mrlfeA0Policy
```

For GUI mRLFE sweeps, the adapter uses the unified atlas route by default:

```matlab
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeA0Policy = string(controls.mrlfeA0Policy);
```

The sweep output preserves:

```matlab
sweepOutput.atlasPolicy.mrlfeUseUnifiedAtlasRoute
sweepOutput.atlasPolicy.mrlfeA0Policy
```

## Fitting GUI contract

The mRLFE fitting adapter accepts:

```matlab
controls.mrlfeUseUnifiedAtlasRoute
controls.mrlfeA0Policy
```

When `mrlfeUseUnifiedAtlasRoute = true`, fitting evaluation should report:

```matlab
fitOutput.routePolicy.expectedPath = "unified_atlas";
fitOutput.routePolicy.actualPath = "unified_atlas";
fitOutput.routePolicy.mrlfeA0Policy
```

The older direct viscous atlas route is preserved for backward-compatible programmatic calls when the unified atlas route is not requested.

## Validation contract

The GUI atlas integration is covered by:

```matlab
tests/gui/test_gui_mrlfe_unified_atlas_policy_contract.m
```

and the test is included in:

```matlab
tests/run_gui_smoke_tests
```

The contract checks that:

```text
- main GUI adapter preserves mrlfeUseUnifiedAtlasRoute and mrlfeA0Policy
- Sweep GUI adapter preserves atlasPolicy metadata
- mRLFE fitting adapter reports actualPath = "unified_atlas" when requested
```

This is a routing and integration test, not a physical validation test.

## Manual GUI checks

After contract tests pass, perform a short manual check before merging large GUI changes.

### Main GUI

```text
Open: LambFundamental_GUI
Model-specific settings > mRLFE
Enable: mRLFE real-k
Branch: A0-like
etaS: 0.05
A0 atlas policy: delayedCut
Compute selected modes
Then repeat with adaptivePhysicalTail
```

Expected behavior:

```text
- no compute error
- mRLFE real-k A0-like curve appears
- status/diagnostics remain available
- Rayleigh-Lamb seed branches are not exposed as mRLFE plot branches
- diagnostic elapsed time is substantially lower than the redundant all-variant route
- raw/internal models contain mRLFERealK for the visible mRLFE result
```

### SweepTool

```text
Open: SweepTool_GUI
Model family: mRLFE
Sweep parameter: etaS
Values: 0, 0.05
Branch: A0Like
A0 atlas policy: delayedCut
Run sweep
Then repeat with adaptivePhysicalTail
```

Expected behavior:

```text
- sweep completes
- summary table is populated
- exported SweepToolOutput contains atlasPolicy
```

### FitTool

```text
Open: FitTool_GUI
Model: mRLFE
Branch: A0Like
Free parameter: mu or etaS
A0 atlas policy: delayedCut
Generate synthetic from setup
Run fit
Then repeat with adaptivePhysicalTail
```

Expected behavior:

```text
- fitting completes or returns a controlled fitting-quality result
- FitToolLastOutput.routePolicy.actualPath is "unified_atlas"
- FitToolLastOutput.routePolicy.mrlfeA0Policy matches the selected policy
```

## Current limitation

This integration does not validate the atlas policy against complex-k solutions, FEM, or experimental data. It only ensures that the GUI can request and report the same maintained solver policy used by the backend.
