# Acoustoelastic IOP/HGO sweep workflow

This document describes the maintained sweep workflow for the acoustoelastic IOP/HGO model.

The sweep layer is intentionally separated from the numerical branch solver. The current implementation uses the public solver entrypoint, but the sweep scripts are organized by physical campaign rather than by branch-tracking policy.

## Design rule

Do not encode internal branch policies in maintained sweep file names.

Use physical or workflow names instead:

```matlab
sweep_iop
sweep_mu
```

The branch policy belongs in solver options:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

`"atlasA0"` is the canonical maintained name for the current atlas-based A0 branch policy. The previous name `"strictA0"` remains accepted as a legacy alias for backward compatibility.

## Maintained files

Short user-facing sweep entrypoints:

```text
examples/acoustoelastic_iop_hgo/sweeps/sweep_iop.m
examples/acoustoelastic_iop_hgo/sweeps/sweep_mu.m
```

The previous descriptive sweep aliases have been archived:

```text
examples/acoustoelastic_iop_hgo/sweeps/sweep_acoustoelastic_iop_hgo_iop.m
examples/acoustoelastic_iop_hgo/sweeps/sweep_acoustoelastic_iop_hgo_mu.m
```

Core helpers:

```text
models/acoustoelastic_iop_hgo/solvers/aeRunSweep.m
analysis/acoustoelastic_iop_hgo/aeSummarizeSweep.m
analysis/acoustoelastic_iop_hgo/aeOutputFolder.m
```

## Setup

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup
```

## Generic sweep adapter

The generic sweep runner is:

```matlab
aeRunSweep
```

Location:

```text
models/acoustoelastic_iop_hgo/solvers/aeRunSweep.m
```

It receives:

```matlab
baseParams
sweepField
sweepValues
options
sweepConfig
```

and calls:

```matlab
solveAcoustoelasticIOPHGOBranch
```

The adapter returns:

```matlab
sweepResult.conditions(i).params
sweepResult.conditions(i).result
sweepResult.conditions(i).reliability
sweepResult.summaryTable
```

## Sweep summary helper

The analysis helper is:

```matlab
aeSummarizeSweep
```

Location:

```text
analysis/acoustoelastic_iop_hgo/aeSummarizeSweep.m
```

It builds:

```matlab
summary.conditionTable
summary.dispersionTable
summary.branchTable
```

The long dispersion table includes one row per frequency and condition, including phase speed, validity flag, point status, nearest rank, nearest branch ID, and objective value when available.

## IOP sweep

Run:

```matlab
sweep_iop
```

Default campaign:

```matlab
IOP_mmHg = [5, 10, 15, 20, 25];
```

Default output folder:

```text
Results/ae_iop_hgo/iop_sweep/
```

Generated files:

```text
iop_sweep_condition_summary.csv
iop_sweep_dispersion_table.csv
iop_sweep_selected_branch_table.csv
iop_sweep_workspace.mat
```

Legacy output folder from earlier runs may still exist:

```text
Results/acoustoelastic_iop_hgo_iop_sweep/
```

## Shear-modulus sweep

Run:

```matlab
sweep_mu
```

Default campaign:

```matlab
mu_kPa = [25, 50, 75, 100];
```

Default output folder:

```text
Results/ae_iop_hgo/mu_sweep/
```

Generated files:

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
docs/acoustoelastic_iop_hgo/phase_closure_atlasA0.md
docs/acoustoelastic_iop_hgo/solver_optimization_status.md
docs/acoustoelastic_iop_hgo_branch_policy.md
```
