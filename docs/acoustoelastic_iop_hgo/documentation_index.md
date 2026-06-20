### Acoustoelastic IOP/HGO documentation index

This document provides a curated map of the acoustoelastic IOP/HGO documentation set.

Use this index to decide which document to read or update. It separates active user-facing documentation, solver-policy evidence, diagnostic evidence, framework hygiene records, and historical archives.

### Reading order

For normal use, read in this order:

```text
1. README.md
2. solver_optimization_status.md
3. examples_inventory.md
4. naming_and_paths_convention.md
5. retained_diagnostic_dependency_review.md
```

For branch-policy reasoning, read:

```text
1. solver_optimization_status.md
2. phase_closure_atlasA0.md
3. atlas_vs_raw_branch1_diagnostic.md
4. branch_families_diagnostic.md
5. identityA0_diagnostic_policy.md
```

For cleanup or refactor work, read:

```text
1. framework_hygiene_status.md
2. examples_inventory.md
3. retained_diagnostic_dependency_review.md
4. code_retention_review_plan.md
5. structural_audit_refresh.md
```

### Active operational documentation

These documents should remain concise and current. They are the first layer for users and future development.

| Document | Role |
|---|---|
| `README.md` | Module landing page and short command summary. |
| `examples_inventory.md` | Current executable inventory under `examples/acoustoelastic_iop_hgo/`. |
| `naming_and_paths_convention.md` | Short-name and output-path convention for the module. |
| `solver_optimization_status.md` | Current solver status and official `atlasA0` policy. |
| `retained_diagnostic_dependency_review.md` | Current retained dependencies, especially raw_branch1 and heavy validation wrappers. |
| `framework_hygiene_status.md` | Current framework status after cleanup and refactor passes. |

### Module-level public API and workflow docs

These live one level up in `docs/` because they describe public API or workflow boundaries across the repository documentation layer.

| Document | Role |
|---|---|
| `../acoustoelastic_iop_hgo_overview.md` | High-level model overview. |
| `../acoustoelastic_iop_hgo_public_api.md` | Public API list. |
| `../acoustoelastic_iop_hgo_branch_policy.md` | Branch policy summary. |
| `../acoustoelastic_iop_hgo_sweep_workflow.md` | Sweep workflow documentation. |

### Solver-policy closure and branch ambiguity evidence

These documents support why `atlasA0` is official and why `identityA0Diagnostic`, `raw_branch1`, and `branch_families` remain diagnostic-only.

| Document | Role |
|---|---|
| `phase_closure_atlasA0.md` | Formal closure note for the `atlasA0` optimization phase. |
| `solver_optimization_status.md` | Current validation status and ambiguity boundary. |
| `atlas_vs_raw_branch1_diagnostic.md` | Comparison of official `atlasA0`, diagnostic `identityA0Diagnostic`, and `raw_branch1`. |
| `branch_families_diagnostic.md` | Competing branch-family analysis in the difficult corner. |
| `atlasA0_truncation_validation.md` | Historical atlas-A0 truncation validation notes. |

### Identity-A0 diagnostic evidence

These documents explain why identity-A0 related branches remain diagnostic-only.

| Document | Role |
|---|---|
| `identityA0_diagnostic_policy.md` | Policy for keeping `identityA0Diagnostic` diagnostic-only. |
| `identityA0_diagnostic_grid_validation.md` | Grid validation of identity-A0 diagnostic behavior. |
| `identityA0_physical_plausibility_diagnostic.md` | Plausibility checks for identity-A0 candidate output. |
| `branch_identity_score_diagnostic.md` | Branch identity score diagnostic. |
| `branch_identity_score_grid_validation.md` | Grid validation for branch identity scoring. |

### Modal atlas and raw-branch reproducibility

These documents explain the retained modal-atlas and raw-branch diagnostic path.

| Document | Role |
|---|---|
| `modal_atlas_wrapper_review.md` | Review of modal-atlas wrapper/output behavior. |
| `retained_diagnostic_dependency_review.md` | Current raw_branch1 dependency and helper-backed regeneration. |
| `examples_inventory.md` | Current executable status for modal atlas and raw branch entrypoints. |
| `output_path_audit.md` | Output path status and fallback-read rules. |

### Cleanup and retention records

These documents are primarily for maintainers. They should not be treated as user-facing workflow docs.

| Document | Role |
|---|---|
| `code_retention_review_plan.md` | Retention policy and archival history. |
| `legacy_entrypoint_map.md` | Mapping from short entrypoints to archived or retained descriptive files. |
| `remaining_wrapper_inventory.md` | Remaining wrapper inventory after consolidation passes. |
| `structural_audit_refresh.md` | Refreshed cleanup audit and candidate-group history. |
| `structural_cleanup_backlog.md` | Cleanup backlog and historical status. |
| `post_rename_audit.md` | Post-renaming audit status. |
| `validation_grid_wrapper_review.md` | Review of heavy validation wrappers. |
| `output_path_audit.md` | Output-path cleanup and fallback reads. |

### Archived exploratory diagnostics

These documents preserve conclusions from scripts that were removed from `examples/acoustoelastic_iop_hgo/`.

| Document | Archived topic |
|---|---|
| `exploratory_diagnostic_review.md` | Summary of E1-E3 exploratory archival. |
| `direct_matrix_landscape_archive.md` | Direct alpha-beta-gamma, M54, dimensionless A1, residual landscape. |
| `a0_backward_tracking_archive.md` | A0 backward tracking, sweep, strategy comparison, grid convergence. |
| `complex_c_continuation_archive.md` | Complex-C continuation example. |

### Documents that should remain short

The following documents should stay concise and should link outward rather than accumulate historical detail:

```text
README.md
solver_optimization_status.md
examples_inventory.md
naming_and_paths_convention.md
```

### Documents that may contain historical detail

The following documents are allowed to be longer because they preserve audit, retention, or archival history:

```text
code_retention_review_plan.md
legacy_entrypoint_map.md
structural_audit_refresh.md
structural_cleanup_backlog.md
exploratory_diagnostic_review.md
*_archive.md
```

### Update policy

When adding or deleting an executable file under `examples/acoustoelastic_iop_hgo/`, update:

```text
examples_inventory.md
maintained_entrypoints.md
code_retention_review_plan.md
```

When changing solver policy, update:

```text
solver_optimization_status.md
phase_closure_atlasA0.md
../acoustoelastic_iop_hgo_branch_policy.md
```

When changing output paths, update:

```text
naming_and_paths_convention.md
output_path_audit.md
examples_inventory.md
```

When archiving exploratory diagnostics, update:

```text
exploratory_diagnostic_review.md
code_retention_review_plan.md
legacy_entrypoint_map.md
```
