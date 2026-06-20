# Acoustoelastic IOP/HGO atlas A0 branch policy

## Purpose

This document defines the current maintained atlas-based policy used by the acoustoelastic IOP/HGO solver for selecting and reporting the A0-like branch.

The policy is intentionally conservative. Its goal is to avoid fabricating high-frequency continuity when the selected branch is no longer explicitly traceable in the numerical objective landscape.

IOP and shear-modulus sweeps showed that this atlas-based A0 policy is the most robust working strategy currently available in the repository. It gives smoother and more physically plausible A0-like curves than earlier exploratory corrected + A0 + backward global-scan workflows, which have now been archived.

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

## Diagnostic evidence

The earlier executable branch-policy comparison scripts have been archived. Current evidence is maintained through short diagnostics and documentation.

Maintained diagnostics:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
```

Important supporting documents:

```text
docs/acoustoelastic_iop_hgo/solver_optimization_status.md
docs/acoustoelastic_iop_hgo/phase_closure_atlasA0.md
docs/acoustoelastic_iop_hgo/atlas_vs_raw_branch1_diagnostic.md
docs/acoustoelastic_iop_hgo/branch_families_diagnostic.md
docs/acoustoelastic_iop_hgo/identityA0_diagnostic_policy.md
docs/acoustoelastic_iop_hgo/a0_backward_tracking_archive.md
```

Archived branch-policy and A0-backward exploratory scripts should not be restored as workflows. Their retained conclusions are preserved in:

```text
docs/acoustoelastic_iop_hgo/code_retention_review_plan.md
docs/acoustoelastic_iop_hgo/a0_backward_tracking_archive.md
```

## Diagnostic alternatives

Diagnostic alternatives such as identity-A0 extension, raw-branch comparison, branch-family mapping, and historical A0-backward tracking are evidence-gathering tools only. They should not be treated as final output policies unless they are validated against physical continuity, monotonicity with IOP, and branch-consistency metrics.

The current diagnostic policy is:

```text
identityA0Diagnostic = diagnostic extension only
raw_branch1 = modal-identity diagnostic only
branch_families = ambiguity diagnostic only
```

## Current recommendation

Use `atlasA0` as the default maintained policy for current parametric sweeps and final working results.

Use reconnection or interpolation only as diagnostics. If a high-frequency branch segment cannot be explicitly traced, report the atlas-A0 curve as truncated and state the last valid frequency.
