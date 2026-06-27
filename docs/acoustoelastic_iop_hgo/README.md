# Acoustoelastic IOP/HGO module documentation

This folder contains documentation for the acoustoelastic IOP/HGO branch of the Lamb fundamental solver.

## Folder map

```text
active/       current operational references
diagnostics/  diagnostic evidence and validation notes
audits/       cleanup, retention, and maintenance records
archive/      historical exploratory notes
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
sweep_iop
sweep_mu
sweep_mu_iop
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
| `active/examples_inventory.md` | Current executable inventory under `examples/acoustoelastic_iop_hgo/`. |
| `active/solver_optimization_status.md` | Current solver policy, validation status, and ambiguity boundary. |
| `active/naming_and_paths_convention.md` | Short-name and result-path convention. |
| `active/solver_pending_work.md` | Pending solver-side numerical work. |
| `active/main_gui_integration_closure.md` | Main-GUI integration closure note. |

## Structure convention

Use this structure for new work:

```text
analysis/acoustoelastic_iop_hgo/              reusable helpers
models/acoustoelastic_iop_hgo/                model and solver implementation
examples/acoustoelastic_iop_hgo/basic/        simple executable examples
examples/acoustoelastic_iop_hgo/sweeps/       sweep entrypoints
examples/acoustoelastic_iop_hgo/diagnostics/  diagnostics and validations
tests/acoustoelastic_iop_hgo/                 tests
docs/acoustoelastic_iop_hgo/active/           current module documentation
docs/acoustoelastic_iop_hgo/diagnostics/      diagnostic evidence
docs/acoustoelastic_iop_hgo/audits/           maintenance records
docs/acoustoelastic_iop_hgo/archive/          historical notes
Results/ae_iop_hgo/<task>                     generated outputs
```

## Cleanup status

The framework currently has two layers:

1. Maintained short entrypoints.
2. Retained long descriptive implementations or diagnostics.

Simple compatibility aliases and exploratory example scripts have been archived. New user-facing work should extend the maintained short-entrypoint layer, not the legacy long-name layer.
