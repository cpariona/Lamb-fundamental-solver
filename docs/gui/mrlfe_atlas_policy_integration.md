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

The goal is not to claim external physical validation. The goal is to ensure that GUI requests can reach the maintained viscous mRLFE atlas route and preserve the selected A0 policy in metadata.

## Supported A0 policies

The GUI exposes the same high-level A0 policy selector used by the solver:

```matlab
options.mrlfeA0Policy = "delayedCut";
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

Current interpretation:

| Policy | Use |
| --- | --- |
| `adaptivePhysicalTail` | Recommended interactive policy for difficult soft, viscous, fluid-loaded A0-like branches. |
| `delayedCut` | Conservative/diagnostic A0 policy. It can truncate early or select a short tail in GUI-fast settings. |

The solver default remains conservative in backend contexts. The GUI default is allowed to prioritize interactive branch coverage by selecting `adaptivePhysicalTail`.

## Main GUI contract

The main GUI reads the mRLFE tab controls and sets:

```matlab
options.mrlfeUseUnifiedAtlasRoute = options.mrlfeParams.etaS > 0;
options.mrlfeA0Policy = string(modelControls.mrlfe.a0Policy.Value);
```

The main GUI adapter uses this route split:

```text
Rayleigh-Lamb seed branch
    -> computeMRLFE for etaS = 0
    -> solveMRLFEAtlasUnified for etaS > 0
    -> mRLFERealK only
    -> normalized GUI branch
```

`etaS = 0` is treated as an elastic reference route in the main GUI. The elastic modal-atlas route is not currently the GUI default because it can return invalid/fragmented normalized Cp in the lightweight smoke-test grid and needs a separate stabilization pass.

The GUI-visible model should be:

```text
mRLFERealK
```

The raw/internal result may preserve Rayleigh-Lamb seed branches, but routine GUI computation should not expose redundant `mRLFEElasticRealK` and `mRLFEViscoRealK` branches on the plotting surface.

## GUI fast viscous atlas preset

The main GUI uses a fast atlas preset for viscous mRLFE interaction:

```matlab
options.mrlfeUseGuiFastAtlasPreset = true;
options.mrlfeGuiAtlasPreset = "fast_viscous";
```

The preset reduces atlas scan density and candidate refinement for interactive use:

```matlab
mrlfeViscoAtlasCpScanPoints = 260
mrlfeA0DPCpScanPoints = 260
mrlfeA0DPCandidates = 5
mrlfeA0DPRefineCandidates = false
mrlfeAdaptiveCpScanPoints = 260
mrlfeAdaptiveRefineCandidates = false
mrlfeAdaptiveWindows = [0.20 0.40 0.80]
```

This preset is GUI-specific. Dense diagnostics and policy-validation scripts should keep their own explicit dense options. Disable the preset only for debugging:

```matlab
options.mrlfeUseGuiFastAtlasPreset = false;
```

For `etaS = 0`, the adapter reports:

```matlab
result.metadata.mrlfeGuiAtlasPreset = "elastic_reference";
```

## Metadata contract

The model adapter preserves route, policy, and preset metadata:

```matlab
result.metadata.mrlfeUseUnifiedAtlasRoute
result.metadata.mrlfeA0Policy
result.metadata.mrlfeGuiAtlasPreset
result.diagnostics.mrlfeUseUnifiedAtlasRoute
result.diagnostics.mrlfeA0Policy
result.diagnostics.mrlfeGuiAtlasPreset
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
etaS: 0.1
A0 atlas policy: adaptivePhysicalTail
Compute selected modes
```

Expected behavior:

```text
- no compute error
- mRLFE real-k A0-like curve appears
- status/diagnostics remain available
- Rayleigh-Lamb seed branches are not exposed as mRLFE plot branches
- elapsed time is suitable for interaction at the default 631-point grid
- raw/internal models contain mRLFERealK for the visible mRLFE result
```

### SweepTool

```text
Open: SweepTool_GUI
Model family: mRLFE
Sweep parameter: etaS
Values: 0, 0.05
Branch: A0Like
A0 atlas policy: adaptivePhysicalTail
Run sweep
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
A0 atlas policy: adaptivePhysicalTail
Generate synthetic from setup
Run fit
```

Expected behavior:

```text
- fitting completes or returns a controlled fitting-quality result
- FitToolLastOutput.routePolicy.actualPath is "unified_atlas"
- FitToolLastOutput.routePolicy.mrlfeA0Policy matches the selected policy
```

## Current limitation

This integration does not validate the atlas policy against complex-k solutions, FEM, or experimental data. It only ensures that the GUI can request and report the same maintained viscous solver policy used by the backend.

The elastic modal-atlas GUI route remains a separate future task.
