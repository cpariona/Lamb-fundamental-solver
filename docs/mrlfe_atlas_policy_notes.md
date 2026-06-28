# mRLFE atlas policy notes

This note records the current findings for the real-k mRLFE atlas solver and its branch-selection policies. The main purpose is to document what was learned during the A0/S0 policy development, which options are currently supported, and which diagnostics should be used before changing defaults.

## Scope

The notes apply to the unified real-k atlas route:

```matlab
options.mrlfeUseUnifiedAtlasRoute = true;
```

with viscous mRLFE cases, i.e.

```matlab
mrlfeParams.etaS > 0;
mrlfeParams.solveComplexK = false;
```

The current implementation uses Rayleigh-Lamb or physically synthesized dry-like seed modes as the guide for branch tracking. The solver does not use the etaS = 0 mRLFE solution as the viscous seed.

## Problem observed in viscous real-k A0 tracking

The A0 branch is difficult to track in soft, viscous, fluid-loaded cases. In these cases, the residual valley can become broad, weak, or ambiguous. Direct residual minimization can either stop too early or fall into a slow leaky/math root at high frequency.

The main observed failure modes were:

- The direct viscous A0 atlas route can terminate almost immediately for soft cases.
- A low-residual branch can continue into a nonphysical slow tail.
- A pointwise corridor against the dry RL guide is too aggressive because fluid loading can legitimately reduce A0 speed below the dry reference.
- A lightweight unit-test grid is not reliable for quantitative physical coverage assertions; dense diagnostics are required.

The important distinction is that the fluid-loaded viscous A0 speed may be below the dry RL guide for physically valid reasons. Therefore, a simple lower-bound filter such as Cp_mRLFE / Cp_RL > 0.70 is not a sufficient policy by itself.

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

This is the conservative/default A0 policy. It uses the direct viscous atlas route and then applies a delayed modal cut when the branch loses continuity or residual quality after an established valid run.

The resulting policy label is:

```text
viscousA0DelayedCut
```

This route is useful as a conservative baseline and should remain the default until broader validation supports changing it.

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

Typical options used in diagnostics:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
options.mrlfeAdaptiveCpScanPoints = 900;
options.mrlfeAdaptiveWindows = [0.20 0.35 0.50 0.80 1.20];
options.mrlfeAdaptiveMaxJumpRelative = 0.12;
options.mrlfeAdaptiveMaxPredictionError = 0.12;
options.mrlfeAdaptivePredictionWeight = 45.0;
options.mrlfeAdaptiveResidualWeight = 0.45;
options.mrlfeAdaptiveAllowValleyFallback = true;
options.mrlfeAdaptiveValleyFallbackRelativeWindow = 0.10;
options.mrlfeAdaptiveValleyFallbackPredictionWeight = 65.0;
options.mrlfeAdaptiveValleyFallbackResidualWeight = 0.30;
options.mrlfeA0PhysicalMinRatioToGuide = 0.70;
options.mrlfeA0PhysicalMinFrequencyHz = 1000;
options.mrlfeA0PhysicalMinValidRunBeforeCut = 8;
options.mrlfeA0PhysicalMaxLocalDropRelative = 0.05;
options.mrlfeA0PhysicalMaxTwoStepDropRelative = 0.10;
```

## S0 policy

The S0 branch currently uses an adaptive atlas continuation policy by default in the unified viscous route:

```text
viscousS0AdaptiveContinuation
```

The S0 adaptive policy uses narrower windows than the A0 adaptive physical-tail policy:

```matlab
options.mrlfeUseAdaptiveS0AtlasTracker = true;
options.mrlfeAdaptiveWindows = [0.12 0.20 0.35 0.50];
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

for the same set of material parameters. A representative result for etaS = 0.05 and h = 0.5 mm was:

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

Total cases:

```text
84
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

The difficult cases were primarily low mu, high etaS, and/or larger thickness. For example, h = 1.0 mm, etaS = 0.10, mu = 30 kPa remained difficult, but adaptivePhysicalTail still extended the branch from an almost immediate delayedCut failure to several kHz.

## Generated diagnostic figures

The parametric sweep generates PNG and FIG files in:

```text
outputs/mrlfe/figures
```

Generated figures include:

```text
valid_point_gain.png
adaptive_last_valid_hz.png
adaptive_valley_fallback_count.png
adaptive_cut_frequency_hz.png
valid_point_gain_scatter.png
adaptive_last_valid_hz_scatter.png
```

These figures are intended for quick identification of regions where the adaptive policy is useful, where it cuts, and where it relies on valley fallback.

## Interpretation of valleyFallback

The `valleyFallback` candidate type is not a failure by itself. It indicates that the strict local minimum was not a sufficiently stable branch candidate and that the tracker used a nearby residual valley together with continuity/prediction constraints.

However, a high `valleyFallbackCount` means the branch is being maintained by a heuristic continuity mechanism rather than by a clean isolated residual minimum. Such cases should be treated as physically plausible but lower confidence.

Recommended interpretation:

- low or zero fallback: high-confidence adaptive tracking.
- moderate fallback with smooth Cp and no tail collapse: acceptable but should be reported.
- high fallback in soft/high-loss/thick cases: inspect residual landscapes or compare against complex-k solutions if available.

## Current recommendation

Keep the default conservative:

```matlab
options.mrlfeA0Policy = "delayedCut";
```

Use the adaptive policy explicitly for difficult A0 viscous cases:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

This is currently the recommended policy for soft, viscous, fluid-loaded A0 branches when the direct delayedCut policy fails early or returns insufficient coverage.

Do not make adaptivePhysicalTail the global default yet because a substantial fraction of parametric cases used valleyFallback. The current evidence supports it as an opt-in policy with diagnostics, not yet as an unconditional default.

## Tests and contracts

The atlas test runner includes a high-level policy selector contract:

```matlab
tests/run_mrlfe_atlas_tests
```

The policy selector test verifies that:

```matlab
options.mrlfeA0Policy = "delayedCut";
```

routes to:

```text
viscousA0DelayedCut
```

and that:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

routes to:

```text
viscousA0AdaptivePhysicalTailCut
```

The lightweight tests intentionally do not assert dense physical coverage of A0. Physical coverage must be checked with dense diagnostics, because the A0 branch is sensitive to frequency grid density and material regime.

## Suggested next checks

Before changing defaults, run additional validation in at least one of the following directions:

1. Compare adaptivePhysicalTail against complex-k mRLFE where available.
2. Inspect residual landscapes for cases with high valleyFallbackCount.
3. Test additional fluid properties if the solver will be used outside water loading.
4. Compare predicted A0 branches with FEM or experimental OCE curves in soft material phantoms.
5. Add confidence labels based on fallback count, guide ratio, residual percentile, and tail-cut status.

## Practical usage example

Conservative baseline:

```matlab
options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeA0Policy = "delayedCut";
```

Recommended difficult-case A0 route:

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
branch.residual
```

These fields are necessary to distinguish a clean physical branch from a branch that required fallback or tail cutting.
