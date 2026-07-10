# mRLFE atlas policy GUI integration

> Historical note: Main GUI, SweepTool, and FitTool maintained mRLFE production
> routes now use the public `mrlfeSolve` API. The atlas-route details in this
> document are retained for diagnostics, migration tests, and cleanup planning.
> They are not the maintained Main GUI production route.

This document records the GUI-facing integration of the real-k mRLFE atlas routes.

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
analysis/mrlfe/mrlfeEvaluateAtlasFitModel.m
```

The goal is not to claim external physical validation. The goal is to ensure that GUI requests can reach the maintained mRLFE atlas-style routes and preserve route/policy metadata.

## Supported A0 policies

The GUI exposes the same high-level A0 policy selector used by the solver:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
options.mrlfeA0Policy = "delayedCut";
```

Current interpretation:

| Policy | Use |
| --- | --- |
| `adaptivePhysicalTail` | Current interactive and FitTool A0Like fitting default. Recommended for difficult A0-like branches, including the zero-eta limit and viscous cases. |
| `delayedCut` | Conservative/diagnostic A0 policy. It can truncate early or select a short tail in GUI-fast settings. |

The solver can still compare both policies in diagnostics. The GUI and FitTool defaults prioritize interactive branch coverage by selecting `adaptivePhysicalTail`.

## Main GUI contract

The main GUI reads the mRLFE tab controls and sets:

```matlab
options.mrlfeUseUnifiedAtlasRoute = options.mrlfeParams.etaS > 0;
options.mrlfeA0Policy = string(modelControls.mrlfe.a0Policy.Value);
```

The main GUI adapter uses this route split:

```text
Rayleigh-Lamb seed branch
    -> zero-eta adaptive route for etaS = 0
    -> viscous unified atlas for etaS > 0
    -> mRLFERealK only
    -> normalized GUI branch
```

The zero-eta route intentionally uses the same adaptive tracker family and A0 policy as the viscous route, rather than the separate elastic modal-atlas route. This checks the elastic limit of the adaptive policy more directly.

## Zero-eta adaptive route

For `etaS = 0`, the default GUI route is:

```matlab
options.mrlfeUseZeroViscosityAdaptiveGuiRoute = true;
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

The adapter calls the adaptive atlas tracker directly with `etaS = 0` and applies the same physical-tail policy used by the viscous A0 GUI route.

The candidate must satisfy both GUI quality guards:

```matlab
options.mrlfeZeroViscosityAdaptiveGuiMinValidFraction = 0.85;
options.mrlfeZeroViscosityAdaptiveGuiMaxJumpRelative = 0.25;
```

If the candidate does not meet these thresholds, the adapter falls back to:

```text
computeMRLFE -> elastic reference
```

The fallback is explicit and recorded:

```matlab
result.metadata.mrlfeUseZeroViscosityAdaptiveGuiRoute
result.metadata.mrlfeZeroViscosityAdaptiveFallback
result.metadata.mrlfeZeroViscosityAdaptiveQuality
result.metadata.mrlfeGuiActualRoute
result.diagnostics.mrlfeUseZeroViscosityAdaptiveGuiRoute
result.diagnostics.mrlfeZeroViscosityAdaptiveFallback
result.diagnostics.mrlfeZeroViscosityAdaptiveQuality
result.diagnostics.mrlfeGuiActualRoute
```

Possible actual routes are:

```text
zero_viscosity_adaptive_atlas
zero_viscosity_adaptive_fallback
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

For the viscous route, the preset is:

```matlab
result.metadata.mrlfeGuiAtlasPreset = "fast_viscous";
```

For the zero-eta adaptive route, the preset is:

```matlab
result.metadata.mrlfeGuiAtlasPreset = "fast_zero_viscosity_adaptive";
```

Both routes use reduced atlas scan density and candidate refinement:

```matlab
mrlfeViscoAtlasCpScanPoints = 260
mrlfeA0DPCpScanPoints = 260
mrlfeA0DPCandidates = 5
mrlfeA0DPRefineCandidates = false
mrlfeAdaptiveCpScanPoints = 260
mrlfeAdaptiveRefineCandidates = false
mrlfeAdaptiveWindows = [0.20 0.40 0.80]
```

These presets are GUI-specific. Dense diagnostics and policy-validation scripts should keep their own explicit dense options. Disable the preset only for debugging:

```matlab
options.mrlfeUseGuiFastAtlasPreset = false;
```

## Metadata contract

The model adapter preserves route, policy, preset, quality, and fallback metadata:

```matlab
result.metadata.mrlfeUseUnifiedAtlasRoute
result.metadata.mrlfeUseZeroViscosityAdaptiveGuiRoute
result.metadata.mrlfeZeroViscosityAdaptiveFallback
result.metadata.mrlfeZeroViscosityAdaptiveQuality
result.metadata.mrlfeGuiActualRoute
result.metadata.mrlfeA0Policy
result.metadata.mrlfeGuiAtlasPreset
result.diagnostics.mrlfeUseUnifiedAtlasRoute
result.diagnostics.mrlfeUseZeroViscosityAdaptiveGuiRoute
result.diagnostics.mrlfeZeroViscosityAdaptiveFallback
result.diagnostics.mrlfeZeroViscosityAdaptiveQuality
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
sweepOutput.atlasPolicy.guiRoutePolicy
```

## Fitting GUI contract

The mRLFE fitting adapter defaults to atlas-first fitting, analogous to AE atlas fitting, but with both mRLFE branches available:

```text
A0Like
S0Like
```

The FitTool adapter accepts:

```matlab
controls.mrlfeUseUnifiedAtlasRoute
controls.mrlfeUseAtlasFitRoute
controls.mrlfeA0Policy
```

Default FitTool values are:

```matlab
controls.mrlfeUseUnifiedAtlasRoute = true;
controls.mrlfeUseAtlasFitRoute = true;
controls.mrlfeA0Policy = "adaptivePhysicalTail";
```

Fitting evaluation should report the atlas family:

```matlab
fitOutput.routePolicy.routeFamily = "atlas";
fitOutput.routePolicy.expectedPath = "mrlfe_atlas";
fitOutput.routePolicy.mrlfeA0Policy
fitOutput.routePolicy.fitAtlasPreset
```

The actual path depends on viscosity:

```matlab
fitOutput.routePolicy.actualPath = "zero_viscosity_adaptive_atlas"; % etaS = 0
fitOutput.routePolicy.actualPath = "viscous_unified_atlas";          % etaS > 0
```

The older reference/direct-viscous fitting workflow is preserved only for explicit diagnostic calls when atlas-fit routing is disabled programmatically:

```matlab
solverOptions.mrlfeUseAtlasFitRoute = false;
```

## FitTool fitted-curve contract

The primary FitTool fitted curve is fit-consistent. It interpolates the model values used by the fitting objective at the experimental frequencies.

Dense solver re-evaluation is preserved as diagnostic metadata:

```matlab
normalized.fullCurve.denseSolver
normalized.fullCurve.denseSolver.maxAbsDenseMinusFit_mps
normalized.fullCurve.denseSolver.hasGridMismatch
normalized.fullCurve.denseSolver.warningMessage
```

If the dense re-evaluation differs from the fit-consistent values beyond the configured threshold, the status line reports a dense/grid mismatch. This is a grid/path sensitivity diagnostic, not a fitting failure by itself.

The mRLFE extension curve remains skipped by default in the fast GUI fitting path.

## Validation contract

The GUI mRLFE atlas integration is covered by two focused runners.

Main GUI and general GUI smoke validation:

```matlab
run_gui_smoke_tests
```

This includes:

```matlab
test_gui_mrlfe_unified_atlas_policy_contract
test_gui_mrlfe_fit_route_policy_contract
test_gui_mrlfe_fixed_etaS_fit_contract
test_gui_mrlfe_elastic_atlas_guard_contract
test_gui_mrlfe_fit_full_curve_fast_contract
```

Focused FitTool atlas validation:

```matlab
run_mrlfe_fit_public_solver_tests
```

This includes:

```matlab
test_gui_mrlfe_fit_zero_eta_atlas_contract
test_gui_mrlfe_fit_route_policy_contract
test_gui_mrlfe_fixed_etaS_fit_contract
test_gui_mrlfe_unified_atlas_policy_contract
test_gui_mrlfe_fit_full_curve_fast_contract
```

Historical zero-eta adaptive main-GUI route checks are superseded by the public-solver GUI tests. They are covered by `run_gui_smoke_tests`, not by the removed FitTool atlas runner.

The zero-eta adaptive contract checks that:

```text
- an etaS = 0 adaptive request is reported in metadata
- the actual route is either zero_viscosity_adaptive_atlas or zero_viscosity_adaptive_fallback
- the quality metadata includes validFraction and maxJumpRelative
- direct zero_viscosity_adaptive_atlas output meets the GUI quality thresholds
- the normalized GUI branch contains finite Cp values
```

The fitting contracts check that:

```text
- FitTool uses routeFamily = atlas
- etaS = 0 uses zero_viscosity_adaptive_atlas
- etaS > 0 uses viscous_unified_atlas
- A0Like and S0Like are both supported
- fixed etaS is preserved in mu/thickness fits
- in-band full-curve plotting remains fit-consistent
- dense solver re-evaluation is diagnostic metadata
- mRLFE extension is skipped by default
```

This is routing and synthetic-contract validation, not physical validation.

## Manual GUI checks

After contract tests pass, perform a short manual check before merging large GUI changes.

### Main GUI zero-eta route

```text
Open: LambFundamental_GUI
Model-specific settings > mRLFE
Enable: mRLFE real-k
Branch: A0-like
etaS: 0
A0 atlas policy: adaptivePhysicalTail
Compute selected modes
```
