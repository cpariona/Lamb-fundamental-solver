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
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
docs/acoustoelastic_iop_hgo/output_path_audit.md
docs/acoustoelastic_iop_hgo/modal_atlas_wrapper_review.md
docs/acoustoelastic_iop_hgo/legacy_entrypoint_map.md
docs/acoustoelastic_iop_hgo/remaining_wrapper_inventory.md
```

### Modal-atlas migration status

Both maintained modal-atlas short entrypoints are now migrated.

Current behavior:

```text
diagnose_modal_atlas.m
  delegates to diagnose_acoustoelastic_iop_hgo_modal_atlas.m while preserving the MATLAB launch folder.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  writes to Results/ae_iop_hgo/modal_atlas through aeOutputFolder, relative to the preserved launch folder.

diagnose_modal_atlas_lowfreq.m
  delegates to diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m while preserving the MATLAB launch folder.

diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
  writes to Results/ae_iop_hgo/modal_atlas_lowfreq through aeOutputFolder, relative to the preserved launch folder.
  Routine interactive plotting is disabled in the implementation.
```

The previous temporary-copy output patch is no longer required for either maintained modal-atlas short entrypoint.

A follow-up correction was applied after detecting that `run(fullfile(...))` can execute relative to the script folder and create `Results/` under `examples/acoustoelastic_iop_hgo/diagnostics/`. The short entrypoints now add the diagnostics folder to the MATLAB path temporarily and call the descriptive scripts by name so that `pwd` remains the user launch folder.

User-reported MATLAB validation passed for both modal-atlas entrypoints and the smoke tests.

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
  DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION_WITH_LAUNCH_FOLDER_PRESERVATION
  The short entrypoint no longer patches a temporary copy and preserves the MATLAB launch folder for output placement.

diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
  MIGRATED_SHORT_OUTPUT_PATH
  Writes through aeOutputFolder(pwd, 'modal_atlas_lowfreq'); `pwd` is preserved by the maintained short entrypoint.
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

The standard and low-frequency modal-atlas output-path migrations are closed. Remaining cleanup should move back to the broader wrapper inventory and legacy-script classification, not additional modal-atlas output-path work.
