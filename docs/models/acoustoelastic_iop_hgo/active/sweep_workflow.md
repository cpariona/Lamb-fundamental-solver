# Acoustoelastic IOP/HGO sweep workflow

This document describes the maintained sweep workflow for the acoustoelastic IOP/HGO module.

## Maintained sweep entrypoints

Run from the repository root after startup:

```matlab
clear functions
rehash toolboxcache
startup

ae_sweep_iop_A0Like
ae_sweep_mu_A0Like
ae_sweep_thickness_A0Like
ae_sweep_k1_A0Like
ae_sweep_k2_A0Like
ae_sweep_radius_A0Like
ae_sweep_mu_iop_A0Like
```

The one-parameter workflows use the same maintained structure:

```text
aeDefaultSweepParams
    -> aeDefaultSweepOptions
    -> aeRunSweep
    -> aeSummarizeSweep
    -> aeWriteSweepOutputs
    -> aePlotSweepCp
    -> aeSaveExampleFigure
```

Public sweep scripts define only the physical campaign, display units, and task metadata. Reusable setup, solver, output, and plotting behavior remains in the maintained helpers.

The maintained one-parameter Cp figures use Alternative B plotting: `aeBuildSweepPlotData` adapts AE sweep results to neutral plot data, then `plotSweepCpFigure` renders the main Cp(f) axes and a separate right-side information panel for fixed parameters and sweep values. The swept parameter is omitted from the fixed-parameter block.

## Maintained campaigns

| Entrypoint | Swept field | Display values | Fixed reference values |
|---|---|---|---|
| `ae_sweep_iop_A0Like` | `IOP` | `[5, 10, 15, 20, 25] mmHg` | shared AE defaults |
| `ae_sweep_mu_A0Like` | `mu` | `[25, 50, 75, 100] kPa` | shared AE defaults |
| `ae_sweep_thickness_A0Like` | `thickness` | `[400, 475, 550, 625, 700] um` | shared AE defaults |
| `ae_sweep_k1_A0Like` | `k1` | `[10, 25, 50, 75, 100] kPa` | shared AE defaults |
| `ae_sweep_k2_A0Like` | `k2` | `[50, 100, 200, 300, 400]` | shared AE defaults |
| `ae_sweep_radius_A0Like` | `R` | `[7.0, 7.4, 7.8, 8.2, 8.6] mm` | shared AE defaults |
| `ae_sweep_mu_iop_A0Like` | `mu`, `IOP` | `mu = 60:5:80 kPa`; `IOP = [12.5, 15, 17.5] mmHg` | shared AE defaults |

## Output convention

Generated data outputs are written under:

```text
Results/ae_iop_hgo/<task>/
```

Static example figures are written under:

```text
examples/acoustoelastic_iop_hgo/sweeps/figures/<task>/
```

Current task names are:

```text
iop_sweep
mu_sweep
thickness_sweep
k1_sweep
k2_sweep
radius_sweep
mu_iop_sweep
```

Each one-parameter workflow writes condition-summary, dispersion, selected-branch, and workspace outputs through `aeWriteSweepOutputs`. Static figures are saved as `.fig` and `.png` through `aeSaveExampleFigure`.

The combined `ae_sweep_mu_iop_A0Like` workflow additionally displays an interactive frequency surface that is not saved automatically.

The repository-wide naming and result-root conventions are documented in
`docs/repository/naming_strategy.md` and
`docs/repository/repository_structure.md`.

## Validation

After changing public AE sweep examples, run:

```matlab
clear functions
rehash toolboxcache
startup

test_ae_physical_sweep_examples_contract
run_acoustoelastic_smoke_tests
```

Execute each changed sweep manually to validate generated tables and figures. Before merging broader changes, also run `run_all_smoke_tests`.

Branch-policy behavior is owned by `branch_policy.md`; sweep workflows
must not reinterpret diagnostic branches as production output.
