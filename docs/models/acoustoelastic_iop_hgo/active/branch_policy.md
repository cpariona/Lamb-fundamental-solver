# Acoustoelastic IOP/HGO atlas A0 branch policy

## Purpose

This document defines the current maintained atlas-based policy used by the acoustoelastic IOP/HGO solver for selecting and reporting the A0-like branch.

The policy is intentionally conservative. Its goal is to avoid fabricating high-frequency continuity when the selected branch is no longer explicitly traceable in the numerical objective landscape.

IOP and shear-modulus sweeps showed that this atlas-based A0 policy is the most robust working strategy currently available in the repository. It gives smoother and more physically plausible A0-like curves than earlier exploratory corrected + A0 + backward global-scan workflows, which have now been archived.

## Nomenclature

There is only one maintained production atlas policy:

```text
atlasA0
```

For user-facing interpretation, `atlasA0` should be read as the official atlas-selected A0-like branch. It is not competing with another production atlas branch.

The name is kept explicit because the solver may later expose other modal branches or diagnostic atlas families. In text, it is acceptable to call it the official atlas-A0 branch. In code, keep using:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

Diagnostic objects have different roles:

```text
identityA0Diagnostic = separate diagnostic extension candidate
raw_branch1 = independent modal-atlas reference used for validation
branch_families = ambiguity diagnostic for difficult regimes
```

They should not be described as alternative official atlas policies.

## Current canonical policy: `atlasA0`

The maintained solver option is:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

New maintained examples and sweeps should use `"atlasA0"`.

Under this policy, the solver:

1. Builds a frequency-phase-speed atlas using the objective landscape.
2. Detects local minima at each frequency.
3. Links minima into candidate branches using continuity in dimensionless phase speed.
4. Keeps only A0-like candidate branches that start at low dimensionless phase speed and low rank.
5. Splits branches when a large relative phase-speed jump is detected.
6. Does not interpolate or reconnect missing high-frequency portions by default.
7. Reports missing or untraceable portions as `NaN` in `result.Cp` and `false` in `result.validCp`.

## Internal tracking grid versus output grid

The IOP/HGO wrapper separates branch identity selection from the requested output grid:

```matlab
options.useInternalAtlasTrackingGrid = true;
options.atlasInitializationMinFrequency_Hz = 300;
options.atlasInitializationNumFrequencyPoints = 50;
```

This means:

```text
internal tracking grid = used to identify and link the atlas-A0 branch
requested output grid  = frequencies returned to GUI/users in result.Cp and result.validCp
```

The internal grid prevents the first requested output frequency from becoming the identity anchor of the branch. This is necessary because very low requested frequencies can be dominated by near-degenerate minima, while high requested starting frequencies can start after the A0-like identity region has already been skipped.

The output is still reported only on the requested frequencies. Frequencies below the internal initialization range are marked as not reported rather than being used to anchor the branch identity.

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

## Fallback invalidation

If no branch satisfies the A0-like start filters and the atlas solver falls back to an unfiltered selection, the IOP/HGO wrapper invalidates that fallback as official output:

```matlab
result.Cp(:) = NaN;
result.validCp(:) = false;
result.pointStatus(:) = "fallbackRejectedA0StartFilter";
```

The fallback candidate is retained only for diagnostics:

```matlab
result.fallbackCandidateCp
result.fallbackCandidateValidCp
```

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
docs/acoustoelastic_iop_hgo/active/solver_optimization_status.md
docs/acoustoelastic_iop_hgo/archive/phase_closure_atlasA0.md
docs/acoustoelastic_iop_hgo/diagnostics/atlas_vs_raw_branch1_diagnostic.md
docs/acoustoelastic_iop_hgo/diagnostics/branch_families_diagnostic.md
docs/acoustoelastic_iop_hgo/diagnostics/identityA0_diagnostic_policy.md
docs/acoustoelastic_iop_hgo/archive/a0_backward_tracking_archive.md
```

Archived branch-policy and A0-backward exploratory scripts should not be restored as workflows. Their retained conclusions are preserved in:

```text
docs/acoustoelastic_iop_hgo/audits/code_retention_review_plan.md
docs/acoustoelastic_iop_hgo/archive/a0_backward_tracking_archive.md
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
