# Acoustoelastic IOP/HGO atlas A0 branch policy

## Purpose

This document defines the current maintained atlas-based policy used by the acoustoelastic IOP/HGO solver for selecting and reporting the A0-like branch.

The policy is intentionally conservative. Its goal is to avoid fabricating high-frequency continuity when the selected branch is no longer explicitly traceable in the numerical objective landscape.

Recent IOP and shear-modulus sweeps showed that this atlas-based A0 policy is the most robust working strategy currently available in the repository. It gives smoother and more physically plausible A0-like curves than the earlier corrected + A0 + backward globalScan diagnostic workflow.

## Current canonical policy: `atlasA0`

The maintained solver option is:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

The previous name:

```matlab
options.atlasBranchPolicy = "strictA0";
```

is retained as a legacy alias for backward compatibility with existing scripts, workspaces, and diagnostic outputs. New maintained examples and sweeps should use `"atlasA0"`.

Under this policy, the solver:

1. Builds a frequency-phase-speed atlas using the objective landscape.
2. Detects local minima at each frequency.
3. Links minima into candidate branches using continuity in dimensionless phase speed.
4. Keeps only A0-like candidate branches that start at low dimensionless phase speed and low rank.
5. Splits branches when a large relative phase-speed jump is detected.
6. Does not interpolate or reconnect missing high-frequency portions by default.
7. Reports missing or untraceable portions as `NaN` in `result.Cp` and `false` in `result.validCp`.

## A0-like start filter

A branch is considered A0-like only if it passes the hard start filter:

```matlab
options.atlasRequireLowStartY = true;
options.atlasMaxStartY = 0.50;
options.atlasRequireStartRank = true;
options.atlasMaxStartRank = 3;
```

where

```matlab
y = Cp / sqrt(alpha / rho)
```

is the dimensionless phase speed used by the atlas.

This filter prevents the solver from selecting high-speed, nearly horizontal branches that can have good numerical coverage but are not A0-like at low frequency.

## Branch splitting

The selected branch candidates are split when consecutive points have a relative phase-speed jump larger than the configured threshold:

```matlab
options.atlasSplitOnLargeCpJump = true;
options.atlasMaxRelativeCpJump = 0.05;
```

This prevents a single tracked branch from silently merging two different modal families.

## Missing high-frequency portions

The default policy does not reconnect or interpolate missing portions:

```matlab
options.atlasAllowInterpolationAcrossGaps = false;
```

Therefore, if the A0-like branch is not explicitly traceable at high frequency, the output should be interpreted as:

```matlab
result.Cp(k) = NaN;
result.validCp(k) = false;
result.pointStatus(k) = "missingSelectedBranch";
```

This is a reliability statement, not necessarily a physical claim that the mode disappears. It means that, under the current matrix formulation and objective-landscape tracking criteria, the branch is not numerically identifiable with enough evidence to report a continuous phase speed.

## Reliability outputs

The solver exposes a reliability summary:

```matlab
result.reliability.PolicyName
result.reliability.ValidFraction
result.reliability.ValidPoints
result.reliability.MissingPoints
result.reliability.FirstValidFrequency_kHz
result.reliability.LastValidFrequency_kHz
result.reliability.FirstMissingFrequency_kHz
result.reliability.A0StartFilterPassed
result.reliability.SelectionFallbackUsed
result.reliability.YStart
result.reliability.StartRank
result.reliability.CpStart_mps
result.reliability.MaxBranchRelativeCpDrop
result.reliability.ValidityNote
```

For high-IOP cases, the recommended interpretation is to use `LastValidFrequency_kHz` as the upper frequency limit of the reported atlas-A0 curve.

## Diagnostic alternatives

The script

```matlab
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_branch_policy.m
```

compares atlas policy behavior against diagnostic alternatives such as:

- `strict`
- `smallGapInterpolation`
- `softJumpStrict`
- `monotoneReconnectDiagnostic`

The script

```matlab
examples/acoustoelastic_iop_hgo/diagnostics/compare_acoustoelastic_iop_hgo_branch_policies.m
```

compares the maintained `atlasA0` path against the earlier `legacy_backward_global_scan` diagnostic strategy.

These alternatives are intended for evidence gathering only. They should not be treated as final output policies unless they are validated against physical continuity, monotonicity with IOP, and branch-consistency metrics.

## Current recommendation

Use `atlasA0` as the default maintained policy for current parametric sweeps and final working results.

Use reconnection or interpolation only as diagnostics. If a high-frequency branch segment cannot be explicitly traced, report the atlas-A0 curve as truncated and state the last valid frequency.
