### Legacy entrypoint map

This document maps maintained short entrypoints to older descriptive legacy scripts in the `acoustoelastic_iop_hgo` examples tree.

The current convention is:

```text
Use short entrypoints for user-facing execution.
Keep long descriptive scripts only for compatibility or implementation history.
```

Do not call long legacy scripts directly unless there is a specific reason to inspect historical behavior.

### Basic examples

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `run_atlas_branch` | `run_acoustoelastic_iop_hgo_atlas_branch` | direct maintained implementation; legacy file is alias to short entrypoint |

### Sweeps

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `sweep_iop` | `sweep_acoustoelastic_iop_hgo_iop` | direct maintained implementation; legacy file is alias to short entrypoint |
| `sweep_mu` | `sweep_acoustoelastic_iop_hgo_mu` | direct maintained implementation; legacy file is alias to short entrypoint |

### Branch policy and tracking diagnostics

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `compare_branch_policies` | `compare_acoustoelastic_iop_hgo_branch_policies` | direct maintained implementation; legacy file is alias to short entrypoint |
| `diagnose_branch_policy` | `diagnose_acoustoelastic_iop_hgo_branch_policy` | historical compatibility entrypoint |
| `diagnose_sweep_reliability` | `diagnose_acoustoelastic_iop_hgo_sweep_reliability` | direct maintained implementation; legacy file is alias to short entrypoint |
| `diagnose_branch_persistence` | `diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement` | direct maintained implementation; legacy file is alias to short entrypoint |
| `diagnose_atlas_truncation` | `diagnose_acoustoelastic_iop_hgo_atlasA0_truncation_cause` | direct maintained implementation; legacy file is alias to short entrypoint |
| `diagnose_atlas_resolution` | `diagnose_acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity` | direct maintained implementation; legacy file is alias to short entrypoint |

### Identity-A0 diagnostics

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `validate_idA0_score_grid` | `validate_acoustoelastic_iop_hgo_branch_identity_score_grid` | historical wrapper; target exists; consolidation deferred |
| `validate_idA0_grid` | `validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid` | historical wrapper; target exists; consolidation deferred |
| `diagnose_idA0_score` | `diagnose_acoustoelastic_iop_hgo_branch_identity_score` | direct maintained implementation; legacy file is alias to short entrypoint |
| `diagnose_idA0_plausibility` | `diagnose_idA0_plausibility_impl` | maintained short entrypoint |
| `diagnose_identityA0_plausibility` | `diagnose_idA0_plausibility_impl` | compatibility alias; prefer `diagnose_idA0_plausibility` |

### Modal atlas and raw-branch diagnostics

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `diagnose_modal_atlas` | `diagnose_acoustoelastic_iop_hgo_modal_atlas` | historical thesis-analysis diagnostic; short entrypoint writes to short output path |
| `diagnose_modal_atlas_lowfreq` | `diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas` | historical thesis-analysis diagnostic; short entrypoint writes to short output path |
| `track_raw_branch1` | `track_acoustoelastic_iop_hgo_raw_branch1_candidate` | historical raw-branch diagnostic retained for traceability |

### Deleted archived diagnostics

The following historical diagnostics were deleted after being removed from the maintained surface and after local smoke tests passed:

| Removed short entrypoint | Removed legacy/descriptive file | Replacement or retained evidence |
|---|---|---|
| `diagnose_truncation_cases` | `diagnose_acoustoelastic_iop_hgo_truncation_cases` | use `diagnose_atlas_truncation`; see `docs/acoustoelastic_iop_hgo/atlasA0_truncation_validation.md` |
| `diagnose_landscape_failure` | `diagnose_acoustoelastic_iop_hgo_failure_landscape` | use `diagnose_atlas_truncation`; see `docs/acoustoelastic_iop_hgo/atlasA0_truncation_cause_diagnostic.md` |

### New diagnostics without legacy counterpart

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `compare_atlasA0_vs_raw_branch1` | none | maintained diagnostic |
| `validate_atlas_raw_grid` | none | maintained diagnostic |
| `diagnose_raw_branch_corner` | none | maintained diagnostic |
| `diagnose_branch_families` | none | maintained diagnostic |

### Naming risk

The previous overlong identity-A0 plausibility implementation has been renamed to:

```text
diagnose_idA0_plausibility_impl.m
```

This removes the known namelengthmax risk for that diagnostic while preserving the user-facing command:

```matlab
diagnose_idA0_plausibility
```

### Migration rule

When adding new scripts:

1. Use a short task-oriented filename.
2. Put context in the folder path.
3. Write new outputs under `Results/ae_iop_hgo/<task>`.
4. Use `aeOutputFolder` for new output paths.
5. Use `aeResolveResultFile` only when short-path plus legacy fallback is required.
6. Do not add new user-facing files with the prefix `acoustoelastic_iop_hgo_...`.
