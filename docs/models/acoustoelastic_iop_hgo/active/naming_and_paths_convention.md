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
ae_sweep_iop_A0Like
ae_sweep_mu_A0Like
ae_sweep_thickness_A0Like
ae_sweep_k1_A0Like
ae_sweep_k2_A0Like
ae_sweep_radius_A0Like
ae_sweep_mu_iop_A0Like
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

Repeatable diagnostics retained for scientific reproducibility:

```matlab
validate_idA0_score_grid
validate_idA0_grid
diagnose_idA0_score
diagnose_modal_atlas
track_raw_branch1
```

The canonical commands are the substantive implementations; no forwarding
aliases are retained.

### Result folder convention

Preferred new result root:

```text
Results/ae_iop_hgo/<task>
```

Examples:

```text
Results/ae_iop_hgo/iop_sweep
Results/ae_iop_hgo/mu_sweep
Results/ae_iop_hgo/thickness_sweep
Results/ae_iop_hgo/k1_sweep
Results/ae_iop_hgo/k2_sweep
Results/ae_iop_hgo/radius_sweep
Results/ae_iop_hgo/mu_iop_sweep
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

### Migration rule

Do not mass-delete existing scripts or result folders unless necessary. For maintained sweep entrypoint renames, rename the entrypoint directly, update active callers and documentation, and do not leave a wrapper or alias under the old name. Generated result folders do not need gratuitous renames.

### Recommended user commands

Prefer:

```matlab
run_atlas_branch
ae_sweep_iop_A0Like
ae_sweep_mu_A0Like
ae_sweep_thickness_A0Like
ae_sweep_k1_A0Like
ae_sweep_k2_A0Like
ae_sweep_radius_A0Like
ae_sweep_mu_iop_A0Like
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

### Practical limit

Keep new executable `.m` filenames below about 45 characters. This leaves margin for suffixes and avoids MATLAB name-length issues.
