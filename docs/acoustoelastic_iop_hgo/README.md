### Acoustoelastic IOP/HGO module documentation

This folder collects module-specific documentation for the acoustoelastic IOP/HGO branch of the Lamb fundamental solver.

### Current status

The current official production policy is:

```text
atlasA0 = conservative official output
```

The official solver output remains:

```matlab
result.Cp
result.validCp
```

The following branches and diagnostics are not production outputs:

```text
identityA0Diagnostic
raw_branch1
branch_families
```

See `solver_optimization_status.md` for the current validation status and closure criteria.

### Recommended user-facing commands

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup
```

Basic execution:

```matlab
run_atlas_branch
```

Sweeps:

```matlab
sweep_iop
sweep_mu
```

Validation and diagnostics:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
```

Do not execute long legacy scripts directly unless reproducing historical behavior.

### Documentation map

| Document | Purpose |
|---|---|
| `naming_and_paths_convention.md` | Short-name and result-path convention. |
| `legacy_entrypoint_map.md` | Mapping from maintained short entrypoints to legacy descriptive scripts. |
| `remaining_wrapper_inventory.md` | Remaining wrapper inventory after partial consolidation. |
| `structural_audit_refresh.md` | Refreshed cleanup audit and deletion-review candidate groups. |
| `retained_diagnostic_dependency_review.md` | Review of retained wrappers, raw-branch dependency, validation grids, and exploratory diagnostics. |
| `exploratory_diagnostic_review.md` | Classification of retained exploratory diagnostics and future archival groups. |
| `direct_matrix_landscape_archive.md` | Archived direct-matrix, M54, dimensionless, and residual-landscape exploratory conclusions. |
| `output_path_audit.md` | Current audit of short result paths, legacy fallback reads, and remaining output-path cleanup candidates. |
| `modal_atlas_wrapper_review.md` | Focused review of modal-atlas wrapper cleanup risks and plan. |
| `validation_grid_wrapper_review.md` | Focused review of identity-A0 validation-grid wrappers. |
| `framework_hygiene_status.md` | Current framework structure, naming, and cleanup status. |
| `post_rename_audit.md` | Post-renaming audit status and remaining naming decision. |
| `phase_closure_atlasA0.md` | Formal closure note for the `atlasA0` optimization phase. |
| `solver_optimization_status.md` | Current solver policy, ambiguity boundary, and closure status. |
| `atlas_vs_raw_branch1_diagnostic.md` | Validation snapshots comparing `atlasA0`, `identityA0Diagnostic`, and raw branches. |
| `branch_families_diagnostic.md` | Competing branch-family analysis for the low-stiffness/high-IOP corner. |
| `identityA0_diagnostic_policy.md` | Policy for keeping `identityA0Diagnostic` diagnostic-only. |
| `identityA0_diagnostic_grid_validation.md` | Grid validation of the identity-A0 diagnostic branch. |
| `identityA0_physical_plausibility_diagnostic.md` | Physical plausibility checks for the diagnostic identity-A0 candidate. |
| `branch_identity_score_diagnostic.md` | Branch identity score diagnostic. |
| `branch_identity_score_grid_validation.md` | Grid validation for branch identity scoring. |
| `branch_persistence_refinement.md` | Branch persistence refinement notes. |
| `atlasA0_truncation_validation.md` | Historical atlas-A0 truncation validation notes. |

Module-level public API and overview documents live one level up:

```text
docs/acoustoelastic_iop_hgo_overview.md
docs/acoustoelastic_iop_hgo_public_api.md
docs/acoustoelastic_iop_hgo_branch_policy.md
docs/acoustoelastic_iop_hgo_sweep_workflow.md
```

### Structure convention

Use this structure for new work:

```text
analysis/acoustoelastic_iop_hgo/              reusable helpers
models/acoustoelastic_iop_hgo/                model and solver implementation
examples/acoustoelastic_iop_hgo/basic/        simple executable examples
examples/acoustoelastic_iop_hgo/sweeps/       sweep entrypoints
examples/acoustoelastic_iop_hgo/diagnostics/  diagnostics and validations
tests/acoustoelastic_iop_hgo/                 tests
docs/acoustoelastic_iop_hgo/                  module documentation
Results/ae_iop_hgo/<task>                     generated outputs
```

### Cleanup status

The framework currently has two layers:

1. Maintained short entrypoints.
2. Retained long descriptive implementations or diagnostics.

Simple compatibility aliases that only redirected to short entrypoints have been archived. New user-facing work should extend the maintained short-entrypoint layer, not the legacy long-name layer.
