### Output path audit

This document records the current output-path cleanup status for the acoustoelastic IOP/HGO example and diagnostic layer after the archived-diagnostic cleanup passes.

### Scope

The audit focused on references to legacy acoustoelastic result roots of the form:

```text
Results/acoustoelastic_iop_hgo_...
```

and compared them with the maintained short result root:

```text
Results/ae_iop_hgo/<task>
```

### Current policy

New executable workflows should write to:

```text
Results/ae_iop_hgo/<task>
```

using:

```matlab
aeOutputFolder(launchFolder, taskName)
```

Fallback reads from legacy result folders are allowed only when needed for migration or historical reproducibility.

### Search summary

A focused search for direct code references matching:

```text
fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo
```

found only one remaining code path:

```text
examples/acoustoelastic_iop_hgo/diagnostics/track_acoustoelastic_iop_hgo_raw_branch1_candidate.m
```

That reference is a fallback input path:

```matlab
legacyInputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_low_frequency_modal_atlas');
```

It does not create a new legacy output folder. It allows `track_raw_branch1` to read older low-frequency modal-atlas outputs when the short-path output is not available.

### Modal-atlas dependency review

Before modifying the modal-atlas wrapper layer, the following dependency searches were reviewed:

```text
diagnose_modal_atlas
diagnose_acoustoelastic_iop_hgo_modal_atlas
acoustoelastic_iop_hgo_modal_atlas
modal_atlas
modal_atlas_lowfreq
```

The search did not reveal external code consumers of the legacy modal-atlas CSV filenames. References are concentrated in:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m
docs/acoustoelastic_iop_hgo/output_path_audit.md
docs/acoustoelastic_iop_hgo/modal_atlas_wrapper_review.md
docs/acoustoelastic_iop_hgo/legacy_entrypoint_map.md
docs/acoustoelastic_iop_hgo/remaining_wrapper_inventory.md
```

### Remaining modal-atlas legacy-output pattern

A separate search for the legacy modal-atlas output string found:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m
```

Current behavior:

```text
diagnose_modal_atlas.m
  patches a temporary copy of the legacy implementation so the short entrypoint writes to Results/ae_iop_hgo/modal_atlas.
  The wrapper is now migration-tolerant: it accepts either the old legacy output-folder line or an already migrated aeOutputFolder line.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  still contains the original legacy output-folder line.
```

This means routine use of the short entrypoint writes to the short result tree, but the legacy descriptive implementation still contains a legacy output-root line.

### Interpretation

The remaining legacy-path references are not broad uncontrolled writes.

Current classification:

```text
track_acoustoelastic_iop_hgo_raw_branch1_candidate.m
  COMPATIBILITY_FALLBACK_READ
  Keep while raw_branch1 reproducibility is required.

diagnose_modal_atlas.m
  SHORT_ENTRYPOINT_TEMP_PATCH_MIGRATION_TOLERANT
  Safe in routine use and tolerant of a future direct migration of the legacy implementation output line, but not a final ownership inversion.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  LEGACY_IMPLEMENTATION_OUTPUT_LINE
  Candidate for focused modal-atlas wrapper cleanup.
```

### Recommended next cleanup

Do not change modal-atlas implementation ownership without running the modal-atlas diagnostics.

A focused modal-atlas cleanup may do the following:

```text
1. Move the short output-folder assignment directly into diagnose_acoustoelastic_iop_hgo_modal_atlas.m.
2. Simplify diagnose_modal_atlas.m so it delegates without temporary patching.
3. Run diagnose_modal_atlas in MATLAB.
4. Run test_acoustoelastic_iop_hgo_short_entrypoints and run_all_smoke_tests.
```

The same pass should not modify `diagnose_modal_atlas_lowfreq.m` unless it also runs `diagnose_modal_atlas_lowfreq`, because that wrapper uses a separate temporary-copy patching pattern.

### Do not change yet

Do not remove:

```text
track_raw_branch1
track_acoustoelastic_iop_hgo_raw_branch1_candidate.m
```

Reason:

```text
track_raw_branch1 produces Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv, which is consumed by compare_atlasA0_vs_raw_branch1.
```

### Current conclusion

The next executable cleanup should remain a focused modal-atlas wrapper pass, not a broad legacy-output rewrite.
