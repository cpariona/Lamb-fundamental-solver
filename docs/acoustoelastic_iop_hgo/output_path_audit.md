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

Here `launchFolder` means the MATLAB working directory from which the user calls the maintained entrypoint. It should not be assumed to be the repository root.

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

The search did not reveal external code consumers of the legacy modal-atlas CSV filenames. References were concentrated in:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m
docs/acoustoelastic_iop_hgo/output_path_audit.md
docs/acoustoelastic_iop_hgo/modal_atlas_wrapper_review.md
docs/acoustoelastic_iop_hgo/legacy_entrypoint_map.md
docs/acoustoelastic_iop_hgo/remaining_wrapper_inventory.md
```

### Modal-atlas migration status

The standard modal-atlas short entrypoint is now migrated.

Current behavior:

```text
diagnose_modal_atlas.m
  delegates to diagnose_acoustoelastic_iop_hgo_modal_atlas.m while preserving the MATLAB launch folder.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  writes to Results/ae_iop_hgo/modal_atlas through aeOutputFolder, relative to the preserved launch folder.
```

The previous temporary-copy output patch is no longer required for `diagnose_modal_atlas`.

A follow-up correction was applied after detecting that `run(fullfile(...))` can execute relative to the script folder and create `Results/` under `examples/acoustoelastic_iop_hgo/diagnostics/`. The short entrypoint now adds the diagnostics folder to the MATLAB path temporarily and calls the descriptive script by name so that `pwd` remains the user launch folder.

User-reported MATLAB validation passed for the migration before the launch-folder correction. Re-run the same checks after pulling the correction:

```matlab
clear functions
rehash toolboxcache
startup

diagnose_modal_atlas
test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

### Remaining output-path notes

The remaining legacy-path references are not broad uncontrolled writes.

Current classification:

```text
track_acoustoelastic_iop_hgo_raw_branch1_candidate.m
  COMPATIBILITY_FALLBACK_READ
  Keep while raw_branch1 reproducibility is required.

diagnose_modal_atlas.m
  DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION_WITH_LAUNCH_FOLDER_PRESERVATION
  The short entrypoint no longer patches a temporary copy and preserves the MATLAB launch folder for output placement.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  MIGRATED_SHORT_OUTPUT_PATH
  Writes through aeOutputFolder(pwd, 'modal_atlas'); `pwd` is preserved by the maintained short entrypoint.

diagnose_modal_atlas_lowfreq.m
  SEPARATE_TEMP_PATCH_PATTERN
  Review separately only with diagnose_modal_atlas_lowfreq execution.
```

### Recommended next cleanup

Do not modify `diagnose_modal_atlas_lowfreq.m` by analogy unless the low-frequency diagnostic is also executed, because that wrapper uses a separate temporary-copy patching pattern.

A focused low-frequency modal-atlas cleanup may do the following:

```text
1. Run dependency searches for diagnose_modal_atlas_lowfreq and diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.
2. Move the short output-folder and noninteractive plotting edits directly into the low-frequency implementation if safe.
3. Simplify diagnose_modal_atlas_lowfreq.m so it delegates without temporary patching while preserving the MATLAB launch folder.
4. Run diagnose_modal_atlas_lowfreq in MATLAB.
5. Run test_acoustoelastic_iop_hgo_short_entrypoints and run_all_smoke_tests.
```

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

The standard modal-atlas output-path migration is closed, with launch-folder output placement corrected in the short entrypoint. The remaining executable cleanup candidate in this area is the separate low-frequency modal-atlas wrapper pattern.
