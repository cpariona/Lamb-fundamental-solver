# Li 2024 atlas-branch tracking policy

## Purpose

This document defines the current default policy used by the Li 2024 acoustoelastic atlas-branch solver for selecting and reporting the A0-like branch.

The policy is intentionally conservative. Its goal is to avoid fabricating high-frequency continuity when the selected branch is no longer explicitly traceable in the numerical objective landscape.

## Current default policy: `strictA0`

The default solver option is:

```matlab
options.atlasBranchPolicy = "strictA0";
```

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

For high-IOP cases, the recommended interpretation is to use `LastValidFrequency_kHz` as the upper frequency limit of the reported strict-A0 curve.

## Diagnostic alternatives

The script

```matlab
examples/li2024/diagnostics/diagnose_li2024_atlas_branch_policy.m
```

compares the default `strictA0` behavior against diagnostic alternatives:

- `strict`
- `smallGapInterpolation`
- `softJumpStrict`
- `monotoneReconnectDiagnostic`

These alternatives are intended for evidence gathering only. They should not be treated as final output policies unless they are validated against physical continuity, monotonicity with IOP, and branch-consistency metrics.

## Current recommendation

Use `strictA0` as the default policy for final results.

Use reconnection or interpolation only as diagnostics. If a high-frequency branch segment cannot be explicitly traced, report the strict-A0 curve as truncated and state the last valid frequency.
