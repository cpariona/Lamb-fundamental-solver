# AE IOP/HGO branch-policy numerical review

This document defines the numerical review protocol for comparing:

```text
atlasA0              official reported output
identityA0Diagnostic diagnostic extension candidate
raw_branch1          independent modal-atlas reference
branch_families      ambiguity map for difficult regimes
```

The goal is to make the branch-policy review reproducible without changing the production solver policy prematurely.

## Current production policy

The maintained production policy remains:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

`atlasA0` is conservative by design. Missing high-frequency portions are reported as invalid instead of being interpolated or reconnected.

The following outputs are diagnostic-only:

```text
identityA0Diagnostic
raw_branch1
branch_families
```

They should not be promoted to official output unless the numerical evidence is strong and consistent across the review criteria below.

## Required diagnostic commands

Run from the repository root:

```matlab
clear functions
rehash toolboxcache
startup
```

Then run the evidence chain:

```matlab
diagnose_acoustoelastic_iop_hgo_modal_atlas
track_raw_branch1
compare_atlasA0_vs_raw_branch1
diagnose_branch_families
```

Optional broader checks:

```matlab
validate_atlas_raw_grid
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility_impl
```

## Primary output files

The main comparison diagnostic writes:

```text
Results/ae_iop_hgo/atlas_vs_raw_branch1/atlas_vs_raw_branch1_summary.csv
Results/ae_iop_hgo/atlas_vs_raw_branch1/atlas_vs_raw_branch1_points.csv
```

The branch-family diagnostic writes:

```text
Results/ae_iop_hgo/branch_families/branch_families_summary.csv
Results/ae_iop_hgo/branch_families/branch_families_points.csv
Results/ae_iop_hgo/branch_families/branch_families_aggregate.csv
```

## Quantities to inspect

From `atlas_vs_raw_branch1_summary.csv`:

```text
RawValidFraction
AtlasOverlapFraction
IdentityOverlapFraction
MedianAtlasRawRelError
MaxAtlasRawRelError
MedianIdentityRawRelError
MaxIdentityRawRelError
FirstAtlasMismatch_Hz
FirstIdentityMismatch_Hz
Classification
```

From `branch_families_summary.csv`:

```text
FamilyRank
FrequencyCoverageFraction
MedianRank
MedianY
MedianCp_mps
Roughness
MedianObjective
MedianSpacingToNearestLogY
FamilyScore
ConfigLabel
```

From `branch_families_aggregate.csv`:

```text
Configurations
FamiliesReported
BestFamilyMedianCoverage
BestFamilyMinCoverage
BestFamilyMaxCoverage
BestFamilyMedianRank
ReportedFamiliesWithCoverageAbove080
ReportedFamiliesWithMedianRankBelowOrEqual4
ReportedFamiliesWithCoverageAbove080AndRankBelowOrEqual4
```

## Decision criteria

### Keep `atlasA0` unchanged

Keep the current production policy if any of the following are true:

```text
raw_branch1 has insufficient coverage;
atlasA0 is aligned with raw_branch1 within current thresholds;
identityA0Diagnostic is closer to raw_branch1 only in isolated cases;
branch_families shows multiple plausible competing families;
identityA0Diagnostic improves continuity by reconnecting ambiguous or untraceable regions;
```

This is the default expected outcome because `atlasA0` is intentionally conservative.

### Investigate `identityA0Diagnostic` further

Do not promote it directly. Only open a deeper investigation if all of the following are true:

```text
IdentityOverlapFraction is comparable to or better than AtlasOverlapFraction;
MedianIdentityRawRelError is consistently lower than MedianAtlasRawRelError;
MaxIdentityRawRelError remains below the acceptance threshold;
FirstIdentityMismatch_Hz is later than FirstAtlasMismatch_Hz across the tested IOP range;
branch_families does not show multiple competing low-rank high-coverage families;
```

Even then, the next step should be a dedicated validation branch, not a production policy change.

### Investigate `raw_branch1` further

Do not promote raw_branch1 directly. It can be used as a reference if:

```text
RawValidFraction is high;
MedianRank is low;
FrequencyCoverageFraction is high;
Roughness is low;
branch-family ambiguity is limited;
```

If raw_branch1 is merely the global lowest-residual branch without stable modal identity, it should remain diagnostic-only.

### Do not change policy in ambiguous regimes

If `diagnose_branch_families` reports multiple high-coverage low-rank families, the correct conclusion is ambiguity, not automatic promotion of another branch.

In that case, keep `atlasA0` as the official conservative output and report the last valid frequency.

## Current review interpretation

The current repository policy remains valid unless the user reruns the diagnostics and obtains consistent evidence against it.

Expected interpretation:

```text
atlasA0 = official conservative A0-like output
identityA0Diagnostic = possible extension candidate, diagnostic-only
raw_branch1 = modal-atlas reference, diagnostic-only
branch_families = ambiguity diagnostic, diagnostic-only
```

## Validation after changing diagnostic code

After any change to branch-policy diagnostics, run:

```matlab
clear functions
rehash toolboxcache
startup

run_acoustoelastic_smoke_tests
```

For broad changes, also run:

```matlab
run_gui_smoke_tests
run_mrlfe_smoke_tests
```
