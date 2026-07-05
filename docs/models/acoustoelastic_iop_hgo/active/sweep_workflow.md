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
sweep_thickness
sweep_k1
sweep_k2
sweep_radius
sweep_mu_iop
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

## Maintained campaigns

| Entrypoint | Swept field | Display values | Fixed reference values |
|---|---|---|---|
| `sweep_iop` | `IOP` | `[5, 10, 15, 20, 25] mmHg` | shared AE defaults |
| `sweep_mu` | `mu` | `[25, 50, 75, 100] kPa` | shared AE defaults |
| `sweep_thickness` | `thickness` | `[400, 475, 550, 625, 700] um` | shared AE defaults |
| `sweep_k1` | `k1` | `[10, 25, 50, 75, 100] kPa` | shared AE defaults |
| `sweep_k2` | `k2` | `[50, 100, 200, 300, 400]` | shared AE defaults |
| `sweep_radius` | `R` | `[7.0, 7.4, 7.8, 8.2, 8.6] mm` | shared AE defaults |
| `sweep_mu_iop` | `mu`, `IOP` | `mu = 60:5:80 kPa`; `IOP = [12.5, 15, 17.5] mmHg` | shared AE defaults |

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

The combined `sweep_mu_iop` workflow additionally displays an interactive frequency surface that is not saved automatically.

The naming convention is documented in:

```text
docs/models/acoustoelastic_iop_hgo/active/naming_and_paths_convention.md
```

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

## Branch-policy diagnostic comparison

The earlier executable branch-policy comparison has been archived. Current branch-policy status and retained evidence are documented in:

```text
docs/models/acoustoelastic_iop_hgo/archive/phase_closure_atlasA0.md
docs/models/acoustoelastic_iop_hgo/active/solver_optimization_status.md
docs/models/acoustoelastic_iop_hgo/active/branch_policy.md
```