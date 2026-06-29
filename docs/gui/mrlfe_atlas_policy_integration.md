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

The goal is not to claim external physical validation. The goal is to ensure that GUI requests can reach the maintained mRLFE atlas routes and preserve route/policy metadata.

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

The main GUI adapter now uses this route split by default:

```text
Rayleigh-Lamb seed branch
    -> guarded elastic modal atlas for etaS = 0
    -> viscous unified atlas for etaS > 0
    -> mRLFERealK only
    -> normalized GUI branch
```

For `etaS = 0`, the guarded elastic route tries the modal atlas first and falls back to the elastic reference route if the atlas candidate does not meet the GUI quality guard.

## Guarded elastic atlas route

The default `etaS = 0` GUI route is guarded elastic atlas:

```matlab
options.mrlfeUseElasticAtlasGuiRoute = true;
```

It can be disabled programmatically for debugging:

```matlab
options.mrlfeUseElasticAtlasGuiRoute = false;
```

When this option is true and `etaS = 0`, the adapter tries:

```text
solveMRLFEAtlasUnified -> elastic modal atlas
```

The atlas candidate must satisfy the GUI coverage guard:

```matlab
options.mrlfeElasticAtlasGuiMinValidFraction = 0.85;
```

If the atlas candidate does not meet this threshold, the adapter falls back to:

```text
computeMRLFE -> elastic reference
```

The fallback is explicit and recorded:

```matlab
result.metadata.mrlfeUseElasticAtlasGuiRoute
result.metadata.mrlfeElasticAtlasFallback
result.metadata.mrlfeElasticAtlasQuality
result.metadata.mrlfeGuiActualRoute
result.diagnostics.mrlfeUseElasticAtlasGuiRoute
result.diagnostics.mrlfeElasticAtlasFallback
result.diagnostics.mrlfeElasticAtlasQuality
result.diagnostics.mrlfeGuiActualRoute
```

Possible actual routes are:

```text
elastic_modal_atlas
elastic_reference_fallback
elastic_reference
viscous_unified_atlas
```

The GUI-visible model should be:

```text
mRLFERealK
```

The raw/internal result may preserve Rayleigh-Lamb seed branches, but routine GUI computation should not expose redundant `mRLFEElasticRealK` and `mRLFEViscoRealK` branches on the plotting surface.

## GUI atlas presets

The main GUI uses fast atlas presets for interaction:

```matlab
options.mrlfeUseGuiFastAtlasPreset = true;
```

For the viscous atlas route, the preset is:

```matlab
result.metadata.mrlfeGuiAtlasPreset = "fast_viscous";
```

and uses reduced atlas scan density and candidate refinement:

```matlab
mrlfeViscoAtlasCpScanPoints = 260
mrlfeA0DPCpScanPoints = 260
mrlfeA0DPCandidates = 5
mrlfeA0DPRefineCandidates = false
mrlfeAdaptiveCpScanPoints = 260
mrlfeAdaptiveRefineCandidates = false
mrlfeAdaptiveWindows = [0.20 0.40 0.80]
```

For the guarded elastic atlas route, the preset is:

```matlab
result.metadata.mrlfeGuiAtlasPreset = "fast_elastic_atlas_guarded";
```

and uses:

```matlab
mrlfeModalAtlasApplyAmbiguityCut = false
mrlfeModalAtlasCpScanPoints = 420
mrlfeModalAtlasTopNMinima = 12
mrlfeModalAtlasRefineMinima = false
mrlfeModalAtlasRequireResidualValidity = false
mrlfeElasticAtlasGuiMinValidFraction = 0.85
```

These presets are GUI-specific. Dense diagnostics and policy-validation scripts should keep their own explicit dense options. Disable the preset only for debugging:

```matlab
options.mrlfeUseGuiFastAtlasPreset = false;
```

## Metadata contract

The model adapter preserves route, policy, preset, and fallback metadata:

```matlab
result.metadata.mrlfeUseUnifiedAtlasRoute
result.metadata.mrlfeUseElasticAtlasGuiRoute
result.metadata.mrlfeElasticAtlasFallback
result.metadata.mrlfeElasticAtlasQuality
result.metadata.mrlfeGuiActualRoute
result.metadata.mrlfeA0Policy
result.metadata.mrlfeGuiAtlasPreset
result.diagnostics.mrlfeUseUnifiedAtlasRoute
result.diagnostics.mrlfeUseElasticAtlasGuiRoute
result.diagnostics.mrlfeElasticAtlasFallback
result.diagnostics.mrlfeElasticAtlasQuality
result.diagnostics.mrlfeGuiActualRoute
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
tests/gui/test_gui_mrlfe_elastic_atlas_guard_contract.m
```

and both tests are included in:

```matlab
tests/run_gui_smoke_tests
```

The guarded elastic atlas contract checks that:

```text
- an etaS = 0 atlas request is reported in metadata
- the actual route is either elastic_modal_atlas or elastic_reference_fallback
- the atlas quality metadata includes validFraction
- direct elastic_modal_atlas output meets the valid-fraction quality threshold
- the normalized GUI branch contains finite Cp values
- fallback metadata is consistent with the actual route
```

This is a routing and stabilization test, not a physical validation test.

## Manual GUI checks

After contract tests pass, perform a short manual check before merging large GUI changes.

### Main GUI elastic route

```text
Open: LambFundamental_GUI
Model-specific settings > mRLFE
Enable: mRLFE real-k
Branch: A0-like
etaS: 0
Compute selected modes
```

Expected behavior:

```text
- no compute error
- mRLFE real-k A0-like curve appears
- diagnostics report elastic_modal_atlas or elastic_reference_fallback
- fallback metadata is explicit if the atlas path fails the coverage guard
```

### Main GUI viscous route

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

This integration does not validate the atlas policy against complex-k solutions, FEM, or experimental data. It only ensures that the GUI can request and report maintained atlas routes and fallbacks explicitly.
