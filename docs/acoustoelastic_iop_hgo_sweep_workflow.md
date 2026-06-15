# Acoustoelastic IOP/HGO sweep workflow

This document describes the maintained sweep workflow for the acoustoelastic IOP/HGO model.

The sweep layer is intentionally separated from the numerical branch solver. The current implementation uses the existing public solver entrypoint, but the sweep scripts are organized by physical campaign rather than by branch-tracking policy. This keeps the repository stable while the solver is improved.

## Design rule

Do not encode internal branch policies in maintained sweep file names.

Use physical or workflow names instead:

```text
sweep_acoustoelastic_iop_hgo_iop.m
sweep_acoustoelastic_iop_hgo_mu.m
compare_acoustoelastic_iop_hgo_branch_policies.m
```

The branch policy belongs in solver options:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

`"atlasA0"` is the canonical maintained name for the current atlas-based A0 branch policy. The previous name `"strictA0"` remains accepted as a legacy alias for backward compatibility.

This allows future changes to the branch-selection strategy without renaming physical sweep scripts.

## New maintained files

```text
models/acoustoelastic_iop_hgo/solvers/aeRunSweep.m
analysis/acoustoelastic_iop_hgo/aeSummarizeSweep.m
examples/acoustoelastic_iop_hgo/sweeps/sweep_acoustoelastic_iop_hgo_iop.m
examples/acoustoelastic_iop_hgo/sweeps/sweep_acoustoelastic_iop_hgo_mu.m
examples/acoustoelastic_iop_hgo/diagnostics/compare_acoustoelastic_iop_hgo_branch_policies.m
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

and calls the current public solver:

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

If the internal acoustoelastic solver is later renamed or replaced by a more robust implementation, this adapter should be the main file to update.

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
sweep_acoustoelastic_iop_hgo_iop
```

Location:

```text
examples/acoustoelastic_iop_hgo/sweeps/sweep_acoustoelastic_iop_hgo_iop.m
```

Default campaign:

```matlab
IOP_mmHg = [5, 10, 15, 20, 25];
```

Default output folder:

```text
Results/acoustoelastic_iop_hgo_iop_sweep/
```

Generated files:

```text
acoustoelastic_iop_hgo_iop_sweep_condition_summary.csv
acoustoelastic_iop_hgo_iop_sweep_dispersion_table.csv
acoustoelastic_iop_hgo_iop_sweep_selected_branch_table.csv
acoustoelastic_iop_hgo_iop_sweep_workspace.mat
```

## Shear-modulus sweep

Run:

```matlab
sweep_acoustoelastic_iop_hgo_mu
```

Location:

```text
examples/acoustoelastic_iop_hgo/sweeps/sweep_acoustoelastic_iop_hgo_mu.m
```

Default campaign:

```matlab
mu_kPa = [25, 50, 75, 100];
```

Default output folder:

```text
Results/acoustoelastic_iop_hgo_mu_sweep/
```

Generated files:

```text
acoustoelastic_iop_hgo_mu_sweep_condition_summary.csv
acoustoelastic_iop_hgo_mu_sweep_dispersion_table.csv
acoustoelastic_iop_hgo_mu_sweep_selected_branch_table.csv
acoustoelastic_iop_hgo_mu_sweep_workspace.mat
```

## Branch-policy diagnostic comparison

Run:

```matlab
compare_acoustoelastic_iop_hgo_branch_policies
```

Location:

```text
examples/acoustoelastic_iop_hgo/diagnostics/compare_acoustoelastic_iop_hgo_branch_policies.m
```

This diagnostic compares:

```text
atlas_a0_policy
legacy_backward_global_scan
```

The comparison is not a final physical sweep. It is meant to evaluate whether the current maintained atlas policy behaves better than the earlier backward global-scan strategy.

Default output folder:

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

When the solver is made more robust, the acoustoelastic section can enter additional dedicated renaming stages. The recommended direction from the repository naming strategy is to introduce short `ae*` names for functions clearly inside `models/acoustoelastic_iop_hgo/` while keeping high-level public names explicit only where needed.

The sweep layer already follows this direction with:

```matlab
aeRunSweep
aeSummarizeSweep
aeNormalizeBranchPolicy
```

Further renaming should be done in a dedicated refactor with path checks, smoke tests, updated examples, updated docs, and a migration note.
