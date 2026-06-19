### Remaining wrapper inventory

This document records the remaining `aeRunLegacyScript` wrappers after the diagnostic wrapper consolidation and archived-diagnostic cleanup passes.

### Status

The following cleanup layers are complete:

```text
critical MATLAB filename risk closed
official Cp mutation review closed
auto-detected missing aeRunLegacyScript targets closed
basic example and sweep short entrypoints converted to direct maintained implementations
six diagnostic short entrypoints converted to direct maintained implementations
archived branch-policy, truncation-case, failure-landscape, branch-persistence, and atlas-resolution executable diagnostics removed
```

The following cleanup layer remains open:

```text
remaining wrapper consolidation and legacy deletion review
```

### Remaining wrappers

The current remaining example-layer wrappers are intentional. They are not known missing-target errors.

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_idA0_plausibility.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_identityA0_plausibility.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_score_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/track_raw_branch1.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
```

A separate wrapper pattern also exists in:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
```

That script is not a simple one-line `aeRunLegacyScript` wrapper. It creates or edits a temporary diagnostic copy and should be handled separately.

### Classification

```text
diagnose_idA0_plausibility.m
  KEEP_AS_WRAPPER
  Target is diagnose_idA0_plausibility_impl.m, a renamed implementation file rather than a legacy descriptive script.

diagnose_identityA0_plausibility.m
  KEEP_AS_COMPATIBILITY_ALIAS
  Compatibility alias for diagnose_idA0_plausibility. It preserves the old user-facing identityA0 name.

validate_idA0_grid.m
  KEEP_AS_WRAPPER
  Target exists and writes directly to the short result tree. The validation grid is heavy, so consolidation should be a focused pass.

validate_idA0_score_grid.m
  KEEP_AS_WRAPPER
  Target exists and writes directly to the short result tree. The validation grid is heavy, so consolidation should be a focused pass.

track_raw_branch1.m
  RETAIN_FOR_COMPARISON_REPRODUCIBILITY
  Generates the raw_branch1 curve consumed by compare_atlasA0_vs_raw_branch1. Do not delete until that comparison no longer depends on the generated curve.

diagnose_modal_atlas.m
  KEEP_AS_WRAPPER
  Short wrapper has additional result-copy compatibility behavior. Do not convert mechanically without preserving that behavior.

diagnose_modal_atlas_lowfreq.m
  SPECIAL_CASE_DEFER
  Uses temporary-copy behavior rather than a simple static wrapper. Review manually before any consolidation.
```

### Archived wrappers removed

These former wrappers or executable diagnostics have already been removed from `examples/acoustoelastic_iop_hgo/diagnostics/`:

```text
compare_branch_policies.m
compare_acoustoelastic_iop_hgo_branch_policies.m
diagnose_branch_policy.m
diagnose_acoustoelastic_iop_hgo_branch_policy.m
diagnose_truncation_cases.m
diagnose_acoustoelastic_iop_hgo_truncation_cases.m
diagnose_landscape_failure.m
diagnose_acoustoelastic_iop_hgo_failure_landscape.m
diagnose_branch_persistence.m
diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement.m
diagnose_atlas_resolution.m
diagnose_acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity.m
```

### Next safe cleanup pass

The next safe pass should not be broad.

Recommended order:

```text
1. Keep validate_idA0_grid.m and validate_idA0_score_grid.m as wrappers unless their heavy implementations are intentionally modified and executed.
2. Keep track_raw_branch1.m while compare_atlasA0_vs_raw_branch1 depends on raw_branch1_curve.csv.
3. Review diagnose_modal_atlas.m and diagnose_modal_atlas_lowfreq.m only in a focused pass with MATLAB execution of both diagnostics.
```

### Deletion policy

No remaining legacy diagnostic should be deleted solely because it has a long descriptive name.

Before deleting any legacy script:

```bash
git grep "<candidate_basename>"
git grep "<candidate_filename>"
```

Then run at minimum:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
```

If the deleted or consolidated script is executable, run its maintained short entrypoint as well.

### Current conclusion

Wrapper consolidation is partially complete and safe to continue, but the remaining wrappers are not simple missing-target defects. They should be handled as focused groups rather than a broad mechanical pass.
