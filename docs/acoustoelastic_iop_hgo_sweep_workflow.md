# Acoustoelastic IOP/HGO sweep workflow

This document describes the maintained sweep workflow for the acoustoelastic IOP/HGO model.

The sweep layer is intentionally separated from the numerical branch solver. The current implementation uses the public solver entrypoint, but the sweep scripts are organized by physical campaign rather than by branch-tracking policy.

## Design rule

Do not encode internal branch policies in maintained sweep file names.

Use physical or workflow names instead:

```matlab
sweep_iop
sweep_mu
compare_acoustoelastic_iop_hgo_branch_policies
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

Legacy descriptive implementations remain available:

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

Legacy command:

```matlab
sweep_acoustoelastic_iop_hgo_iop
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

Legacy command:

```matlab
sweep_acoustoelastic_iop_hgo_mu
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

Run:

```matlab
compare_acoustoelastic_iop_hgo_branch_policies
```

This diagnostic compares the current atlas policy with the earlier backward global-scan strategy.

Default legacy output folder:

```text
Results/acoustoelastic_iop_hgo_branch_policy_comparison/
```

Generated files:

```text
acoustoelastic_iop_hgo_branch_policy_comparison_summary.csv
acoustoelastic_iop_hgo_branch_policy_comparison_workspace.mat
```

## Interpretation guidance

Use the reliability fields before interpreting any phase-speed curve:

```matlab
ValidFraction
ValidPoints
MissingPoints
LastValidFrequency_kHz
FirstMissingFrequency_kHz
A0StartFilterPassed
SelectionFallbackUsed
YStart
StartRank
MaxBranchRelativeCpDrop
```

A missing high-frequency segment should be interpreted as a numerical traceability limit of the current solver/policy, not as proof that the physical mode disappears.

## Future renaming stage

The current migration keeps legacy descriptive scripts for backward compatibility. A later cleanup may remove or archive legacy names once short entrypoints and short result paths have been validated across the workflow.
