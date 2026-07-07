### Legacy entrypoint map

This document maps maintained short entrypoints to older descriptive legacy scripts in the `acoustoelastic_iop_hgo` examples tree.

The current convention is:

```text
Use short entrypoints for user-facing execution.
Keep long descriptive scripts only for implementation history or heavy retained diagnostics.
```

Do not call long legacy scripts directly unless there is a specific reason to inspect historical behavior.

### Basic examples

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `run_atlas_branch` | `run_acoustoelastic_iop_hgo_atlas_branch` | archived alias; use the maintained short entrypoint |

### Sweeps

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `ae_sweep_iop_A0Like` | `sweep_acoustoelastic_iop_hgo_iop` | archived alias; use the maintained short entrypoint |
| `ae_sweep_mu_A0Like` | `sweep_acoustoelastic_iop_hgo_mu` | archived alias; use the maintained short entrypoint |

### Branch policy and tracking diagnostics

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `diagnose_sweep_reliability` | `diagnose_acoustoelastic_iop_hgo_sweep_reliability` | archived alias; use the maintained short entrypoint |
| `diagnose_atlas_truncation` | `diagnose_acoustoelastic_iop_hgo_atlasA0_truncation_cause` | archived alias; use the maintained short entrypoint |

### Identity-A0 diagnostics

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `validate_idA0_score_grid` | `validate_acoustoelastic_iop_hgo_branch_identity_score_grid` | historical wrapper; target exists; consolidation deferred |
| `validate_idA0_grid` | `validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid` | historical wrapper; target exists; consolidation deferred |
| `diagnose_idA0_score` | `diagnose_acoustoelastic_iop_hgo_branch_identity_score` | archived alias; use the maintained short entrypoint |
| `diagnose_idA0_plausibility` | `diagnose_idA0_plausibility_impl` | maintained short entrypoint |
| `diagnose_identityA0_plausibility` | `diagnose_idA0_plausibility_impl` | archived alias; use `diagnose_idA0_plausibility` |

### Modal atlas and raw-branch diagnostics

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `diagnose_modal_atlas` | `diagnose_acoustoelastic_iop_hgo_modal_atlas` | historical thesis-analysis diagnostic; short entrypoint writes to short output path |
| `track_raw_branch1` | `track_acoustoelastic_iop_hgo_raw_branch1_candidate` | archived implementation; use `track_raw_branch1` or `aeExtractRawBranch1Candidate` |

### Archived diagnostics and aliases removed from examples

| Removed short entrypoint or alias | Removed legacy/descriptive file | Replacement or retained evidence |
|---|---|---|
| `diagnose_modal_atlas_lowfreq` | `diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas` | use `diagnose_modal_atlas`; low-frequency initialization is implicit |
| `run_acoustoelastic_iop_hgo_atlas_branch` | same file | use `run_atlas_branch` |
| `sweep_acoustoelastic_iop_hgo_iop` | same file | use `ae_sweep_iop_A0Like` |
| `sweep_acoustoelastic_iop_hgo_mu` | same file | use `ae_sweep_mu_A0Like` |
| `diagnose_acoustoelastic_iop_hgo_sweep_reliability` | same file | use `diagnose_sweep_reliability` |
| `diagnose_acoustoelastic_iop_hgo_branch_identity_score` | same file | use `diagnose_idA0_score` |
| `diagnose_acoustoelastic_iop_hgo_atlasA0_truncation_cause` | same file | use `diagnose_atlas_truncation` |
| `diagnose_identityA0_plausibility` | same file | use `diagnose_idA0_plausibility` |
| `track_acoustoelastic_iop_hgo_raw_branch1_candidate` | same file | use `track_raw_branch1`; implementation moved to `aeExtractRawBranch1Candidate` |
| `compare_branch_policies` | `compare_acoustoelastic_iop_hgo_branch_policies` | `atlasA0` policy closure is documented in `docs/models/acoustoelastic_iop_hgo/archive/phase_closure_atlasA0.md` and `docs/models/acoustoelastic_iop_hgo/active/solver_optimization_status.md` |
| `diagnose_branch_policy` | `diagnose_acoustoelastic_iop_hgo_branch_policy` | branch-policy comparison history retained in documentation; use maintained `atlasA0` policy |
| `diagnose_atlas_resolution` | `diagnose_acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity` | resolution-sensitivity conclusions retained in `docs/models/acoustoelastic_iop_hgo/diagnostics/atlasA0_truncation_cause_diagnostic.md` |
| `diagnose_truncation_cases` | `diagnose_acoustoelastic_iop_hgo_truncation_cases` | use `diagnose_atlas_truncation`; see `docs/models/acoustoelastic_iop_hgo/diagnostics/atlasA0_truncation_validation.md` |
| `diagnose_landscape_failure` | `diagnose_acoustoelastic_iop_hgo_failure_landscape` | use `diagnose_atlas_truncation`; see `docs/models/acoustoelastic_iop_hgo/diagnostics/atlasA0_truncation_cause_diagnostic.md` |
| `diagnose_branch_persistence` | `diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement` | helper behavior retained in `aeAnalyzeBranchPersistenceCandidates`, `aeRefineAtlasA0BranchPersistence`, and `test_acoustoelastic_iop_hgo_branch_persistence_refinement` |

### New diagnostics without legacy counterpart

| Maintained entrypoint | Legacy/descriptive file | Status |
|---|---|---|
| `compare_atlasA0_vs_raw_branch1` | none | maintained diagnostic; regenerates raw_branch1 curve if needed |
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
