# Acoustoelastic IOP/HGO sweep workflow

This document describes the maintained sweep workflow for the acoustoelastic IOP/HGO module.

## Maintained sweep entrypoints

Run from the repository root after startup:

```matlab
clear functions
rehash toolboxcache
startup

sweep_iop
sweep_mu
sweep_mu_iop
```

## Output convention

Generated outputs should be written under:

```text
Results/ae_iop_hgo/<task>/
```

The current naming convention is documented in:

```text
docs/models/acoustoelastic_iop_hgo/active/naming_and_paths_convention.md
```

## IOP sweep

The maintained IOP sweep produces a table and figures for the official atlas-A0 output policy.

Expected output examples:

```text
iop_sweep_condition_summary.csv
iop_sweep_dispersion_table.csv
iop_sweep_selected_branch_table.csv
iop_sweep_workspace.mat
```

## Mu sweep

The maintained mu sweep produces a table and figures for the official atlas-A0 output policy.

Expected output examples:

```text
mu_sweep_condition_summary.csv
mu_sweep_dispersion_table.csv
mu_sweep_selected_branch_table.csv
mu_sweep_workspace.mat
```

Legacy output folder from earlier runs may still exist:

```text
Results/acoustoelastic_iop_hgo_mu_sweep/
```

## Branch-policy diagnostic comparison

The earlier executable branch-policy comparison has been archived. Current branch-policy status and retained evidence are documented in:

```text
docs/models/acoustoelastic_iop_hgo/archive/phase_closure_atlasA0.md
docs/models/acoustoelastic_iop_hgo/active/solver_optimization_status.md
docs/models/acoustoelastic_iop_hgo/active/branch_policy.md
```
