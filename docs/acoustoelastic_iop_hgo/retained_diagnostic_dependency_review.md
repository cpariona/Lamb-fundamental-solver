### Retained diagnostic dependency review

This document records the review performed after the simple compatibility-alias cleanup, exploratory archival passes, and raw-branch helper extraction.

### Scope

Reviewed retained acoustoelastic IOP/HGO scripts that still look similar to older long-name workflows, but are not simple aliases.

Main focus:

```text
track_raw_branch1
compare_atlasA0_vs_raw_branch1
validate_idA0_grid
validate_idA0_score_grid
retained long descriptive diagnostic implementations
```

### Summary decision

The simple compatibility-alias cleanup is complete. Exploratory groups E1-E3 have been archived after preserving their conclusions in documentation. The raw-branch candidate extraction logic has been moved into a reusable analysis helper.

Current conclusion:

```text
The remaining short wrappers are intentional.
The remaining long descriptive files contain modal-atlas implementation logic or heavy validation logic.
raw_branch1 generation no longer depends on a long implementation script.
```

### Raw-branch comparison pipeline

The raw-branch dependency is now explicit and reusable.

Pipeline:

```text
diagnose_modal_atlas_lowfreq
  -> Results/ae_iop_hgo/modal_atlas_lowfreq

aeExtractRawBranch1Candidate
  -> reads modal_atlas_lowfreq outputs
  -> writes Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv

track_raw_branch1
  -> short entrypoint that calls aeExtractRawBranch1Candidate

compare_atlasA0_vs_raw_branch1
  -> reads Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv when present
  -> regenerates raw_branch1_curve.csv via aeExtractRawBranch1Candidate when missing
  -> compares raw_branch1, atlasA0, and identityA0Diagnostic
```

Relevant files:

```text
analysis/acoustoelastic_iop_hgo/aeExtractRawBranch1Candidate.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
examples/acoustoelastic_iop_hgo/diagnostics/track_raw_branch1.m
examples/acoustoelastic_iop_hgo/diagnostics/compare_atlasA0_vs_raw_branch1.m
```

Decision:

```text
KEEP track_raw_branch1
KEEP aeExtractRawBranch1Candidate
```

Reason:

```text
compare_atlasA0_vs_raw_branch1 still uses raw_branch1_curve.csv as comparison evidence, but it can now regenerate the file from modal_atlas_lowfreq outputs if the raw_branch1 artifact is missing.
```

The removed long implementation script was:

```text
examples/acoustoelastic_iop_hgo/diagnostics/track_acoustoelastic_iop_hgo_raw_branch1_candidate.m
```

### Validation-grid wrappers

Reviewed wrappers:

```text
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_score_grid.m
```

Targets:

```text
examples/acoustoelastic_iop_hgo/diagnostics/validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_acoustoelastic_iop_hgo_branch_identity_score_grid.m
```

Decision:

```text
KEEP_AS_WRAPPER
```

Reason:

```text
The short wrappers are stable.
The targets are heavy validation implementations.
The targets already write to clean short result folders through aeOutputFolder.
Inlining or inverting these files would reduce one wrapper layer, but would not fix a current defect.
```

Future simplification option:

```text
Invert the wrappers only if the heavy validations are intentionally modified and run locally:
1. Move implementation into the short file.
2. Convert the descriptive file into an archived note or remove it after reference checks.
3. Run both heavy validations before committing.
```

### Retained modal-atlas implementations

Reviewed retained implementations:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
```

Decision:

```text
KEEP_AS_RETAINED_IMPLEMENTATION
```

Reason:

```text
They are implementation targets of the maintained short entrypoints.
They generate diagnostic evidence for modal-family ambiguity.
They already write to Results/ae_iop_hgo/modal_atlas and Results/ae_iop_hgo/modal_atlas_lowfreq through aeOutputFolder.
```

### Archived exploratory diagnostics

Exploratory groups E1-E3 were archived after preserving conclusions in documentation.

Archive documents:

```text
docs/acoustoelastic_iop_hgo/direct_matrix_landscape_archive.md
docs/acoustoelastic_iop_hgo/a0_backward_tracking_archive.md
docs/acoustoelastic_iop_hgo/complex_c_continuation_archive.md
```

### Current action recommendation

Do not delete another retained diagnostic group until the raw-branch helper extraction has passed local validation.

Recommended validation:

```matlab
clear functions
rehash toolboxcache
startup

diagnose_modal_atlas_lowfreq
track_raw_branch1
compare_atlasA0_vs_raw_branch1
test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```
