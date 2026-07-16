# Acoustoelastic IOP/HGO module documentation

This folder contains documentation for the acoustoelastic IOP/HGO branch of the Lamb fundamental solver.

## Folder map

```text
active/       current operational references
diagnostics/  diagnostic evidence and validation notes
```

For the curated documentation map, start with:

```text
documentation_index.md
```

## Current status

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

Core policy references:

```text
active/branch_policy.md
active/solver_optimization_status.md
active/public_api.md
```

## Recommended user-facing commands

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
diagnose_modal_atlas
validate_idA0_score_grid
validate_idA0_grid
```

Focused smoke runner:

```matlab
run_acoustoelastic_smoke_tests
```

Do not execute long legacy scripts directly unless reproducing historical behavior.

## Most relevant active documents

| Document | Purpose |
|---|---|
| `active/public_api.md` | Public API list. |
| `active/branch_policy.md` | Branch policy summary and official atlas-A0 selection rule. |
| `active/sweep_workflow.md` | Sweep workflow documentation. |
| `active/fitting_workflow.md` | Fitting workflow documentation. |
| `active/solver_optimization_status.md` | Current solver policy, validation status, and ambiguity boundary. |
| `active/naming_and_paths_convention.md` | Short-name and result-path convention. |
| `active/solver_pending_work.md` | Pending solver-side numerical work. |

## Structure convention

Use this structure for new work:

```text
analysis/acoustoelastic_iop_hgo/              reusable helpers
models/acoustoelastic_iop_hgo/                model and solver implementation
examples/acoustoelastic_iop_hgo/basic/        simple executable examples
examples/acoustoelastic_iop_hgo/sweeps/       sweep entrypoints
examples/acoustoelastic_iop_hgo/diagnostics/  diagnostics and validations
tests/models/acoustoelastic_iop_hgo/          model tests
tests/app/                                    app-layer integration tests
docs/models/acoustoelastic_iop_hgo/active/           current module documentation
docs/models/acoustoelastic_iop_hgo/diagnostics/      diagnostic evidence
Results/ae_iop_hgo/<task>                     generated outputs
```

## Cleanup status

Simple forwarding aliases and exploratory scripts are absent. Retained long
diagnostic implementations remain unchanged in Phase 1; Git history preserves
the removed aliases and completed investigations.
