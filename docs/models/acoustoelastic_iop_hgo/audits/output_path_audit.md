### Output path audit

This document records the current output-path cleanup status for the acoustoelastic IOP/HGO example and diagnostic layer after the archived-diagnostic cleanup passes, raw-branch helper extraction, and modal-atlas consolidation.

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

### Raw-branch output status

The raw-branch candidate extraction logic lives in:

```text
analysis/acoustoelastic_iop_hgo/aeExtractRawBranch1Candidate.m
```

It writes maintained outputs to:

```text
Results/ae_iop_hgo/raw_branch1
```

and reads the consolidated modal-atlas output from:

```text
Results/ae_iop_hgo/modal_atlas
```

It retains fallback reads for older local outputs only as input migration paths:

```text
Results/ae_iop_hgo/modal_atlas_lowfreq
Results/acoustoelastic_iop_hgo_low_frequency_modal_atlas
```

These fallbacks do not create new legacy output folders.

The previous long implementation script was removed:

```text
examples/acoustoelastic_iop_hgo/diagnostics/track_acoustoelastic_iop_hgo_raw_branch1_candidate.m
```

Current behavior:

```text
track_raw_branch1
  calls aeExtractRawBranch1Candidate directly

compare_atlasA0_vs_raw_branch1
  reads Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv when present
  regenerates raw_branch1_curve.csv through aeExtractRawBranch1Candidate when missing
```

### Modal-atlas dependency review

Before consolidating the modal-atlas wrapper layer, the following dependency searches were reviewed:

```text
diagnose_modal_atlas
diagnose_acoustoelastic_iop_hgo_modal_atlas
acoustoelastic_iop_hgo_modal_atlas
modal_atlas
modal_atlas_lowfreq
```

The search did not reveal external code consumers of the old low-frequency modal-atlas entrypoint beyond diagnostic documentation and the raw-branch helper dependency that has now been redirected to `modal_atlas`.

### Modal-atlas migration status

The maintained modal-atlas short entrypoint is now consolidated.

Current behavior:

```text
diagnose_modal_atlas.m
  delegates to diagnose_acoustoelastic_iop_hgo_modal_atlas.m while preserving the MATLAB launch folder.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  starts at low frequency by design;
  writes to Results/ae_iop_hgo/modal_atlas through aeOutputFolder, relative to the preserved launch folder;
  writes canonical short aliases modal_atlas_minima.csv and modal_atlas_branches.csv for downstream helpers.
```

Removed redundant modal-atlas entrypoints:

```text
diagnose_modal_atlas_lowfreq.m
diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
```

Reason:

```text
Low-frequency initialization is now implicit in diagnose_modal_atlas.
```

The previous temporary-copy output patch is no longer required. The short entrypoint delegates through `aeRunLegacyScript`, which preserves the MATLAB launch folder for output placement.

User-reported MATLAB validation passed for the consolidated modal-atlas entrypoint, downstream raw-branch comparison, and smoke tests.

### Remaining output-path notes

The remaining legacy-path references are controlled fallback reads or historical documentation.

Current classification:

```text
aeExtractRawBranch1Candidate.m
  COMPATIBILITY_FALLBACK_READ
  Reads old modal_atlas_lowfreq output only if the maintained modal_atlas output is unavailable.
  Writes to Results/ae_iop_hgo/raw_branch1.

track_raw_branch1.m
  DIRECT_HELPER_ENTRYPOINT
  Calls aeExtractRawBranch1Candidate and writes maintained short-path outputs.

compare_atlasA0_vs_raw_branch1.m
  DIRECT_HELPER_FALLBACK
  Can regenerate raw_branch1_curve.csv from consolidated modal_atlas outputs if needed.

diagnose_modal_atlas.m
  DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION_WITH_LAUNCH_FOLDER_PRESERVATION
  The short entrypoint preserves the MATLAB launch folder for output placement.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  MIGRATED_SHORT_OUTPUT_PATH
  Writes through aeOutputFolder(pwd, 'modal_atlas'); `pwd` is preserved by the maintained short entrypoint.
```

### Current conclusion

The modal-atlas output-path migration is closed. The raw_branch1 output path is helper-backed and reproducible from consolidated `modal_atlas` outputs. Remaining cleanup should focus on heavy validation wrappers and solver-interface consistency checks.
