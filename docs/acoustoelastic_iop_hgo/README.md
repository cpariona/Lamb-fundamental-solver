### Acoustoelastic IOP/HGO module documentation

This folder collects module-specific documentation for the acoustoelastic IOP/HGO branch of the Lamb fundamental solver.

For the curated documentation map, start with:

```text
documentation_index.md
```

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

See:

```text
solver_optimization_status.md
phase_closure_atlasA0.md
```

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

Maintained diagnostics:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
```

Do not execute long legacy scripts directly unless reproducing historical behavior.

### Most relevant documents

| Document | Purpose |
|---|---|
| `documentation_index.md` | Curated map of active docs, evidence docs, cleanup records, and archives. |
| `examples_inventory.md` | Current executable inventory under `examples/acoustoelastic_iop_hgo/`. |
| `solver_optimization_status.md` | Current solver policy, validation status, and ambiguity boundary. |
| `naming_and_paths_convention.md` | Short-name and result-path convention. |
| `retained_diagnostic_dependency_review.md` | Current retained dependencies, including raw_branch1 helper-backed regeneration. |
| `framework_hygiene_status.md` | Current framework cleanup state. |

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

Simple compatibility aliases and exploratory example scripts have been archived. New user-facing work should extend the maintained short-entrypoint layer, not the legacy long-name layer.
