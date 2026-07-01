# mRLFE atlas policy notes

This note records the current findings for the real-k mRLFE atlas solver and its branch-selection policies. It is a policy and diagnostic reference, not a claim of external physical validation.

## Scope

The notes apply to real-k mRLFE atlas-style routes, including:

```matlab
options.mrlfeUseUnifiedAtlasRoute = true;
```

and to FitTool fitting through:

```matlab
mrlfeEvaluateFitModel
mrlfeEvaluateAtlasFitModel
```

Important distinction:

- FitTool A0Like fitting currently defaults to `adaptivePhysicalTail`.
- `delayedCut` remains a conservative comparison policy in diagnostics and forward/sweep investigations.
- Dense diagnostics should continue to compare both policies before changing solver-wide defaults.

## Supported A0 policies

The high-level A0 policy selector is:

```matlab
options.mrlfeA0Policy = "delayedCut";
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

### delayedCut

```matlab
options.mrlfeA0Policy = "delayedCut";
```

This is a conservative diagnostic baseline. It uses the direct viscous atlas route and then applies a delayed modal cut when the branch loses continuity or residual quality after an established valid run.

The resulting policy label is:

```text
viscousA0DelayedCut
```

Known limitation: in soft A0 cases it can fail very early, even when a physically useful branch exists.

### adaptivePhysicalTail

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

This policy uses the adaptive atlas tracker for A0 and then applies a conditional physical tail cut.

The resulting policy label is:

```text
viscousA0AdaptivePhysicalTailCut
```

The policy does two things:

1. Adaptive A0 atlas tracking: follows the A0 branch using a physical guide, prediction continuity, residual score, adaptive windows, and fallback into nearby residual valleys when the strict minimum becomes weak or ambiguous.
2. Conditional physical tail cut: cuts only when the branch has already had a sustained valid run and then shows a guide-ratio violation together with a strong downward collapse.

The tail cut is intentionally not a pointwise corridor filter. It only removes the tail after collapse-like behavior is detected.

## Current FitTool policy

For A0Like FitTool fitting, the current maintained default is:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

The fitting route is atlas-first:

```text
mrlfeFitDispersionData
  -> mrlfeBuildFitProblem
  -> mrlfeEvaluateFitModel
  -> mrlfeEvaluateAtlasFitModel
  -> official mRLFE atlas branch output
```

Actual route metadata depends on `etaS`:

```text
etaS = 0  -> zero_viscosity_adaptive_atlas
etaS > 0  -> viscous_unified_atlas
```

The previous reference/direct-viscous fitting workflow is retained only for explicit diagnostics with:

```matlab
solverOptions.mrlfeUseAtlasFitRoute = false;
```

## S0 policy

The S0 branch currently uses an adaptive atlas continuation policy by default in the unified viscous route:

```text
viscousS0AdaptiveContinuation
```

S0 was generally more stable than soft A0, but it can still need adaptive continuation and delayed cut diagnostics in fluid-loaded viscous cases.

## Dense A0 physical-tail diagnostic

Diagnostic script:

```matlab
diagnose_mrlfe_a0_physical_corridor_mu_sweep
```

Representative case:

```matlab
muValues = [50e3 100e3 158e3 250e3 500e3];
etaS = 0.05;
thickness = 0.5e-3;
fluidDensity = 1000;
fluidSoundSpeed = 1500;
fmax = 32e3;
```

Main findings:

| mu | adaptive raw behavior | adaptivePhysicalTail behavior |
|---:|---|---|
| 50 kPa | branch reached about 17.4 kHz but collapsed into a slow tail | kept branch to about 16.99 kHz; cut near 17.07 kHz |
| 100 kPa | branch reached about 29.0 kHz but collapsed into a slow tail | kept branch to about 28.60 kHz; cut near 28.68 kHz |
| >=158 kPa | branch remained valid to 32 kHz | no cut applied |

This is the intended behavior: the policy removes collapse tails in soft cases and does not penalize stiff cases.

## Unified A0 policy comparison

Diagnostic script:

```matlab
diagnose_mrlfe_unified_atlas_mu_sweep
```

This diagnostic compares:

```matlab
options.mrlfeA0Policy = "delayedCut";
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

for the same set of material parameters. A representative result for `etaS = 0.05` and `h = 0.5 mm` was:

| mu | delayedCut valid range | adaptivePhysicalTail valid range | interpretation |
|---:|---|---|---|
| 50 kPa | 22/631 points, to about 29 Hz | 450/631 points, to about 16.99 kHz | critical improvement |
| 100 kPa | 511/631 points, to about 27.19 kHz | 590/631 points, to about 28.60 kHz | clear improvement |
| 158 kPa | 568/631 points, to 32 kHz | 631/631 points, to 32 kHz | full recovery |
| 250 kPa | 567/631 points, to 32 kHz | 631/631 points, to 32 kHz | full recovery |
| 500 kPa | 562/631 points, to 32 kHz | 631/631 points, to 32 kHz | full recovery |

The adaptivePhysicalTail policy was smoother and covered more of the physically useful A0 branch in the tested cases.

## Parametric A0 policy sweep

Diagnostic script:

```matlab
diagnose_mrlfe_a0_policy_parametric_sweep
```

Parameter grid:

```matlab
muValues = [30e3 50e3 75e3 100e3 158e3 250e3 500e3];
etaSValues = [0.01 0.03 0.05 0.10];
thicknessValues = [0.3e-3 0.5e-3 1.0e-3];
```

Aggregate findings:

| metric | value |
|---|---:|
| Total cases | 84 |
| adaptivePhysicalTail had more valid points | 84 |
| adaptivePhysicalTail had equal valid points | 0 |
| adaptivePhysicalTail had fewer valid points | 0 |
| median valid-point gain | 93 points |
| median last-valid-frequency gain | about 1244 Hz |
| cases with physical tail cut | 29 |
| cases with valley fallback | 43 |
| median valley-fallback count | 1 |

Additional stability checks:

- adaptivePhysicalTail did not produce a lower last-valid frequency than delayedCut in the tested grid.
- adaptivePhysicalTail had no cases with max relative jump greater than 0.12 in the tested grid.
- the minimum adaptive valid fraction was about 0.51, while delayedCut could fail nearly at the beginning of the branch.

The difficult cases were primarily low `mu`, high `etaS`, and/or larger thickness. For example, `h = 1.0 mm`, `etaS = 0.10`, `mu = 30 kPa` remained difficult, but adaptivePhysicalTail still extended the branch from an almost immediate delayedCut failure to several kHz.

## Interpretation of valleyFallback

The `valleyFallback` candidate type is not a failure by itself. It indicates that the strict local minimum was not a sufficiently stable branch candidate and that the tracker used a nearby residual valley together with continuity/prediction constraints.

However, a high `valleyFallbackCount` means the branch is being maintained by a heuristic continuity mechanism rather than by a clean isolated residual minimum. Such cases should be treated as physically plausible but lower confidence.

Recommended interpretation:

- low or zero fallback: high-confidence adaptive tracking.
- moderate fallback with smooth Cp and no tail collapse: acceptable but should be reported.
- high fallback in soft/high-loss/thick cases: inspect residual landscapes or compare against complex-k solutions if available.

## FitTool dense-grid diagnostic

FitTool keeps the primary fitted curve fit-consistent with the solver values used by the objective function. Dense solver re-evaluation is stored as diagnostic metadata:

```matlab
normalized.fullCurve.denseSolver
normalized.fullCurve.denseSolver.maxAbsDenseMinusFit_mps
normalized.fullCurve.denseSolver.hasGridMismatch
normalized.fullCurve.denseSolver.warningMessage
```

This avoids silently treating a second grid/path continuation as the fitted curve. See:

```text
docs/models/mrlfe/fittool_grid_path_sensitivity.md
```

## Tests and contracts

The atlas test runner includes the high-level policy selector contract:

```matlab
tests/run_mrlfe_atlas_tests
```

The FitTool atlas route contracts are run with:

```matlab
run_mrlfe_fit_atlas_tests
```

The lightweight tests intentionally do not assert dense physical coverage of A0. Physical coverage must be checked with dense diagnostics, because the A0 branch is sensitive to frequency grid density and material regime.

## Suggested next checks

Before changing solver-wide defaults, run additional validation in at least one of the following directions:

1. Compare adaptivePhysicalTail against complex-k mRLFE where available.
2. Inspect residual landscapes for cases with high valleyFallbackCount.
3. Test additional fluid properties if the solver will be used outside water loading.
4. Compare predicted A0 branches with FEM or experimental OCE curves in soft material phantoms.
5. Add confidence labels based on fallback count, guide ratio, residual percentile, and tail-cut status.

## Practical usage example

Conservative diagnostic baseline:

```matlab
options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeA0Policy = "delayedCut";
```

Current FitTool A0Like fitting default and recommended difficult-case A0 route:

```matlab
options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

For reporting, record at least:

```matlab
branch.atlasUnifiedPolicy
branch.physicalCorridor
branch.candidateType
branch.guideRatio
```
