# Acoustoelastic IOP/HGO documentation index

This document provides a curated map of the acoustoelastic IOP/HGO documentation set.

Use this index to decide which document to read or update. It separates active user-facing documentation, solver-policy evidence, diagnostic evidence, framework hygiene records, and historical archives.

## Folder structure

```text
active/       current operational references
diagnostics/  diagnostic evidence and validation notes
audits/       cleanup, retention, and maintenance records
archive/      historical exploratory notes
```

## Reading order

For normal use, read in this order:

```text
1. README.md
2. active/public_api.md
3. active/branch_policy.md
4. active/solver_optimization_status.md
5. active/solver_pending_work.md
6. active/main_gui_integration_closure.md
7. active/examples_inventory.md
8. active/naming_and_paths_convention.md
```

For branch-policy reasoning, read:

```text
1. active/branch_policy.md
2. active/solver_optimization_status.md
3. active/main_gui_integration_closure.md
4. diagnostics/atlas_vs_raw_branch1_diagnostic.md
5. diagnostics/branch_families_diagnostic.md
6. diagnostics/identityA0_diagnostic_policy.md
7. archive/phase_closure_atlasA0_only.md
8. archive/phase_closure_atlasA0.md
```

For cleanup or refactor work, read:

```text
1. audits/framework_hygiene_status.md
2. active/main_gui_integration_closure.md
3. active/examples_inventory.md
4. audits/retained_diagnostic_dependency_review.md
5. audits/code_retention_review_plan.md
6. audits/structural_audit_refresh.md
```

## Active operational documentation

These documents should remain concise and current. They are the first layer for users and future development.

| Document | Role |
|---|---|
| `active/public_api.md` | Public API list. |
| `active/branch_policy.md` | Branch policy summary and official atlas-A0 selection rule. |
| `active/sweep_workflow.md` | Sweep workflow documentation. |
| `active/fitting_workflow.md` | Fitting workflow documentation. |
| `active/examples_inventory.md` | Current executable inventory under `examples/acoustoelastic_iop_hgo/`. |
| `active/naming_and_paths_convention.md` | Short-name and output-path convention for the module. |
| `active/solver_optimization_status.md` | Current solver status and official `atlasA0` policy. |
| `active/solver_pending_work.md` | Pending solver-side numerical work. |
| `active/main_gui_integration_closure.md` | Closure note for the first main-GUI integration and handoff into solver-interface work. |
| `active/framework_hygiene_status.md` | Short current cleanup status if kept active. |

## Diagnostic evidence

These documents support why `atlasA0` is official and why `identityA0Diagnostic`, `raw_branch1`, and `branch_families` remain diagnostic-only.

| Document | Role |
|---|---|
| `diagnostics/atlas_vs_raw_branch1_diagnostic.md` | Comparison of official `atlasA0`, diagnostic `identityA0Diagnostic`, and `raw_branch1`. |
| `diagnostics/branch_families_diagnostic.md` | Competing branch-family analysis in the difficult corner. |
| `diagnostics/atlasA0_truncation_cause_diagnostic.md` | Cause analysis for atlas-A0 truncation. |
| `diagnostics/atlasA0_truncation_validation.md` | Historical atlas-A0 truncation validation notes. |
| `diagnostics/identityA0_diagnostic_policy.md` | Policy for keeping `identityA0Diagnostic` diagnostic-only. |
| `diagnostics/identityA0_diagnostic_grid_validation.md` | Grid validation of identity-A0 diagnostic behavior. |
| `diagnostics/identityA0_physical_plausibility_diagnostic.md` | Plausibility checks for identity-A0 candidate output. |
| `diagnostics/branch_identity_score_diagnostic.md` | Branch identity score diagnostic. |
| `diagnostics/branch_identity_score_grid_validation.md` | Grid validation for branch identity scoring. |

## Audit and retention records

These documents are primarily for maintainers. They should not be treated as user-facing workflow docs.

| Document | Role |
|---|---|
| `audits/code_retention_review_plan.md` | Retention policy and archival history. |
| `audits/legacy_entrypoint_map.md` | Mapping from short entrypoints to archived or retained descriptive files. |
| `audits/structural_audit_refresh.md` | Refreshed cleanup audit and candidate-group history. |
| `audits/validation_grid_wrapper_review.md` | Review of heavy validation wrappers. |
| `audits/output_path_audit.md` | Output-path cleanup and fallback reads. |
| `audits/modal_atlas_wrapper_review.md` | Review of modal-atlas wrapper/output behavior. |
| `audits/retained_diagnostic_dependency_review.md` | Current raw_branch1 dependency and helper-backed regeneration. |
| `audits/official_cp_mutation_review.md` | Official Cp mutation review. |

## Archived exploratory diagnostics

These documents preserve conclusions from scripts that were removed from `examples/acoustoelastic_iop_hgo/` or from closed policy phases.

| Document | Archived topic |
|---|---|
| `archive/direct_matrix_landscape_archive.md` | Direct alpha-beta-gamma, M54, dimensionless A1, residual landscape. |
| `archive/a0_backward_tracking_archive.md` | A0 backward tracking, sweep, strategy comparison, grid convergence. |
| `archive/complex_c_continuation_archive.md` | Complex-C continuation example. |
| `archive/phase_closure_atlasA0.md` | Earlier closure note for the atlasA0 optimization phase. |
| `archive/phase_closure_atlasA0_only.md` | Final closure note for the single production atlasA0 policy. |

## Documents that should remain short

The following documents should stay concise and should link outward rather than accumulate historical detail:

```text
README.md
active/public_api.md
active/branch_policy.md
active/sweep_workflow.md
active/fitting_workflow.md
active/solver_optimization_status.md
active/solver_pending_work.md
active/main_gui_integration_closure.md
active/examples_inventory.md
active/naming_and_paths_convention.md
```

## Update policy

When adding or deleting an executable file under `examples/acoustoelastic_iop_hgo/`, update:

```text
active/examples_inventory.md
../maintained_entrypoints.md
audits/code_retention_review_plan.md
```

When changing solver policy, update:

```text
active/solver_optimization_status.md
active/branch_policy.md
active/main_gui_integration_closure.md
```

When changing output paths, update:

```text
active/naming_and_paths_convention.md
audits/output_path_audit.md
active/examples_inventory.md
```
