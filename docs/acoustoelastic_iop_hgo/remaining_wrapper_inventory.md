### Remaining wrapper inventory

This document records the remaining `aeRunLegacyScript` wrappers after the diagnostic wrapper consolidation pass.

### Status

The following cleanup layers are complete:

```text
critical MATLAB filename risk closed
official Cp mutation review closed
auto-detected missing aeRunLegacyScript targets closed
basic example and sweep short entrypoints converted to direct maintained implementations
six diagnostic short entrypoints converted to direct maintained implementations
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
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_truncation_cases.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_landscape_failure.m
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
  TOO_RISKY_DEFER
  Target exists and is a validation-grid implementation. Consolidation should be a focused pass because the diagnostic can be heavy.

validate_idA0_score_grid.m
  TOO_RISKY_DEFER
  Target exists and is a validation-grid implementation. Consolidation should be a focused pass because the diagnostic can be heavy.

track_raw_branch1.m
  TOO_RISKY_DEFER
  Target exists and is diagnostic-only. Keep separate until raw_branch1 diagnostics are either archived or consolidated as a group.

diagnose_truncation_cases.m
  TOO_RISKY_DEFER
  Target exists and is a long/heavy diagnostic. Keep as wrapper until truncation diagnostics are reviewed as a group.

diagnose_landscape_failure.m
  TOO_RISKY_DEFER
  Target exists and is a long/heavy diagnostic. Keep as wrapper until failure-landscape diagnostics are reviewed as a group.

diagnose_modal_atlas.m
  KEEP_AS_WRAPPER
  Short wrapper has additional result-copy compatibility behavior. Do not convert mechanically without preserving that behavior.

diagnose_modal_atlas_lowfreq.m
  SPECIAL_CASE_DEFER
  Uses temporary-copy behavior rather than a simple static wrapper. Review manually before any consolidation.
```

### Next safe cleanup pass

The next safe pass should not be broad.

Recommended order:

```text
1. Review diagnose_modal_atlas.m and diagnose_modal_atlas_lowfreq.m together.
2. Review validate_idA0_grid.m and validate_idA0_score_grid.m together.
3. Review diagnose_truncation_cases.m and diagnose_landscape_failure.m together.
4. Review track_raw_branch1.m only after deciding whether raw_branch1 diagnostics remain actively maintained.
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
