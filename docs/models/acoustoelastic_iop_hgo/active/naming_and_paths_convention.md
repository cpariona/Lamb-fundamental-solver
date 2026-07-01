### Naming and path convention

This project uses descriptive folders for context and short executable names for MATLAB compatibility.

### Motivation

MATLAB only recognizes function and script names up to `namelengthmax`, usually 63 characters. Very descriptive script names can exceed this limit and be truncated by MATLAB.

Windows paths can also become fragile when folders repeat the full model name at every level.

Therefore the convention is:

> Put model context in the folder path, not repeatedly in every filename.

### Model tag

For the acoustoelastic IOP/HGO model, use the short model tag:

```text
ae_iop_hgo
```

This replaces repeated long prefixes such as:

```text
acoustoelastic_iop_hgo_...
```

when naming new result folders or short entrypoints.

### Entry point convention

Inside:

```text
examples/acoustoelastic_iop_hgo/
```

prefer short task-oriented script names.

Basic examples:

```matlab
run_atlas_branch
```

Sweeps:

```matlab
sweep_iop
sweep_mu
```

Maintained diagnostics:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
```

Historical diagnostics retained for traceability:

```matlab
validate_idA0_score_grid
validate_idA0_grid
diagnose_idA0_score
diagnose_modal_atlas
track_raw_branch1
```

instead of repeating the full model name in every script filename.

`diagnose_modal_atlas` now starts at low frequency by design. The separate `diagnose_modal_atlas_lowfreq` entrypoint was removed and should not be listed as a retained command.

Long descriptive files can remain as implementation files for backward compatibility, but user-facing execution should use the short entrypoints.

### Result folder convention

Preferred new result root:

```text
Results/ae_iop_hgo/<task>
```

Examples:

```text
Results/ae_iop_hgo/iop_sweep
Results/ae_iop_hgo/mu_sweep
Results/ae_iop_hgo/idA0_score_grid
Results/ae_iop_hgo/idA0_grid
Results/ae_iop_hgo/idA0_plausibility
Results/ae_iop_hgo/sweep_reliability
Results/ae_iop_hgo/atlas_truncation
Results/ae_iop_hgo/idA0_score
Results/ae_iop_hgo/modal_atlas
Results/ae_iop_hgo/raw_branch1
Results/ae_iop_hgo/atlas_vs_raw_branch1
Results/ae_iop_hgo/atlas_vs_raw_branch1_grid
Results/ae_iop_hgo/raw_branch_corner
Results/ae_iop_hgo/branch_families
```

Legacy folders remain valid and should not be deleted automatically:

```text
Results/acoustoelastic_iop_hgo_identityA0_diagnostic_grid
Results/acoustoelastic_iop_hgo_identityA0_physical_plausibility
Results/ae_iop_hgo/modal_atlas_lowfreq
```

### Helper functions

Use:

```matlab
aeOutputFolder(launchFolder, taskName)
```

for new scripts. It returns:

```text
<launchFolder>/Results/ae_iop_hgo/<taskName>
```

Use:

```matlab
aeResolveResultFile(launchFolder, shortTaskName, shortFileName, legacyFolderName, legacyFileName)
```

when reading files during migration. It checks the short path first, then falls back to the legacy path.

Use:

```matlab
aeRunLegacyScript(scriptPath)
```

for short wrappers that need to execute legacy descriptive scripts. This helper copies the legacy script to a short temporary filename, restores the caller launch folder, and runs the copy. It avoids MATLAB `namelengthmax` failures without duplicating implementation code.

### Migration rule

Do not mass-delete existing scripts or result folders unless necessary. Instead:

1. Add a short entrypoint.
2. Keep the legacy descriptive script for backward compatibility.
3. Write new outputs to `Results/ae_iop_hgo/<task>`.
4. Resolve inputs from short paths first, then legacy paths.
5. Update documentation to show the short entrypoint.

### Recommended user commands

Prefer:

```matlab
run_atlas_branch
sweep_iop
sweep_mu
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
validate_idA0_score_grid
validate_idA0_grid
diagnose_idA0_score
diagnose_modal_atlas
track_raw_branch1
```

instead of the longer descriptive script names.

### Practical limit

Keep new executable `.m` filenames below about 45 characters. This leaves margin for suffixes and avoids MATLAB name-length issues.
