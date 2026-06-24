### Current acoustoelastic IOP/HGO examples inventory

This document records the final post-cleanup inventory of executable files under:

```text
examples/acoustoelastic_iop_hgo/
```

It separates public workflows, maintained diagnostic evidence, retained historical diagnostics, and long implementation targets.

### Summary

After the compatibility-alias cleanup, exploratory archival passes E1-E3, and the sweep-helper refactor, no long exploratory example scripts remain as retained public or semi-public workflows.

Current retained executable layers:

```text
1. Public workflows
2. Maintained diagnostic evidence
3. Historical diagnostics retained for thesis/traceability
4. Long implementation targets for short wrappers
```

The raw-branch extraction logic has been moved to:

```text
analysis/acoustoelastic_iop_hgo/aeExtractRawBranch1Candidate.m
```

Reusable sweep helper logic lives in:

```text
analysis/setSweepPlotLimits.m
analysis/acoustoelastic_iop_hgo/aeDefaultSweepParams.m
analysis/acoustoelastic_iop_hgo/aeDefaultSweepOptions.m
analysis/acoustoelastic_iop_hgo/aeRunGridSweep.m
analysis/acoustoelastic_iop_hgo/aeSummarizeGridSweep.m
analysis/acoustoelastic_iop_hgo/aeWriteSweepOutputs.m
analysis/acoustoelastic_iop_hgo/aeBuildGridSweepCpCube.m
analysis/acoustoelastic_iop_hgo/aePlotSweepCp.m
analysis/acoustoelastic_iop_hgo/aePlotGridSweepCp.m
analysis/acoustoelastic_iop_hgo/aePlotGridSweepCpByAxis.m
analysis/acoustoelastic_iop_hgo/aePlotGridSweepFrequencySurfaceInteractive.m
analysis/acoustoelastic_iop_hgo/aeSaveExampleFigure.m
analysis/acoustoelastic_iop_hgo/aeDeleteExampleFigure.m
```

Reusable modal-atlas diagnostic logic lives in:

```text
analysis/acoustoelastic_iop_hgo/aeComputeModalAtlasForCase.m
analysis/acoustoelastic_iop_hgo/aeFindTopModalAtlasLocalMinima.m
analysis/acoustoelastic_iop_hgo/aeLinkModalAtlasMinimaIntoBranches.m
```

Reusable heavy-validation setup lives in:

```text
analysis/acoustoelastic_iop_hgo/aeDefaultIdentityA0ValidationParams.m
analysis/acoustoelastic_iop_hgo/aeDefaultIdentityA0ValidationOptions.m
analysis/acoustoelastic_iop_hgo/aeDefaultIdentityA0ValidationGrid.m
```

Generated figures, local results, MAT files, CSV files, and image exports are ignored by the repository-level `.gitignore`.

Sweep plots use the following visual convention: the Cp axis starts at zero, while frequency, mu, IOP, and other non-Cp axes use data-driven limits with padding. Grouped Cp figures created from a single grid sweep use a common Cp axis limit computed from all conditions in the sweep. The interactive 3D sweep surface keeps fixed axis limits and preserves the current camera view when the slider is moved.

### Basic examples

#### Public workflow

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `basic/run_atlas_branch.m` | `PUBLIC_WORKFLOW` | Writes to `Results/ae_iop_hgo/atlas_branch` through the maintained atlas solver workflow. | Keep. |

Notes:

```text
All old long-name basic exploratory examples have been archived.
No basic alias file remains.
```

### Sweeps

#### Public workflows

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `sweeps/sweep_iop.m` | `PUBLIC_WORKFLOW` | Writes tables/workspace to `Results/ae_iop_hgo/iop_sweep`; shows Cp figure and saves `.fig`/`.png` under `examples/acoustoelastic_iop_hgo/sweeps/figures/iop_sweep`. | Keep. |
| `sweeps/sweep_mu.m` | `PUBLIC_WORKFLOW` | Writes tables/workspace to `Results/ae_iop_hgo/mu_sweep`; shows Cp figure and saves `.fig`/`.png` under `examples/acoustoelastic_iop_hgo/sweeps/figures/mu_sweep`. | Keep. |
| `sweeps/sweep_mu_iop.m` | `PUBLIC_WORKFLOW` | Runs a combined mu-IOP case-study grid sweep with `mu = 60:5:80 kPa` and `IOP = [12.5, 15, 17.5] mmHg`. Writes tables/workspace to `Results/ae_iop_hgo/mu_iop_sweep`; shows one Cp figure per IOP with a common Cp axis and one interactive Cp(f, IOP) surface with a mu slider. Static `.fig`/`.png` curve figures are saved under `examples/acoustoelastic_iop_hgo/sweeps/figures/mu_iop_sweep`; obsolete `mu_iop_sweep_cp_surface_5kHz` files are deleted if present; the interactive surface is displayed only and is not saved automatically. | Keep. |

Notes:

```text
Legacy sweep aliases and historical A0-backward sweep examples have been archived.
No sweep alias file remains.
Public sweep examples should define the sweep variable and campaign metadata only.
Reusable setup, solver options, output writing, plotting, and figure saving should live in analysis/acoustoelastic_iop_hgo/ helpers.
Generated files are ignored by the repository-level .gitignore.
```

### Maintained diagnostic evidence

These diagnostics support the current `atlasA0` policy, ambiguity interpretation, official-vs-diagnostic branch comparisons, or solver-interface reliability checks.

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `diagnostics/compare_atlasA0_vs_raw_branch1.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Reads `Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv` when present; otherwise regenerates it from the consolidated `modal_atlas` output using `aeExtractRawBranch1Candidate`. Writes to `Results/ae_iop_hgo/atlas_vs_raw_branch1`. | Keep. |
| `diagnostics/validate_atlas_raw_grid.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/atlas_vs_raw_branch1_grid`. | Keep. |
| `diagnostics/diagnose_raw_branch_corner.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/raw_branch_corner`. | Keep. |
| `diagnostics/diagnose_branch_families.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/branch_families`. | Keep. |
| `diagnostics/diagnose_sweep_reliability.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/sweep_reliability`. Requires sweep workspaces. | Keep. |
| `diagnostics/diagnose_atlas_truncation.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/atlas_truncation`. Requires sweep workspaces. | Keep. |
| `diagnostics/diagnose_idA0_plausibility.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE_WRAPPER` | Delegates to `diagnose_idA0_plausibility_impl.m`; requires `idA0_grid` workspace. | Keep. |
| `diagnostics/diagnose_idA0_plausibility_impl.m` | `MAINTAINED_DIAGNOSTIC_IMPLEMENTATION` | Writes to `Results/ae_iop_hgo/idA0_plausibility`. | Keep as implementation target. |

### Historical diagnostics retained for traceability

These scripts are retained because they support thesis traceability or heavy validation, but they are not routine workflows.

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `diagnostics/diagnose_idA0_score.m` | `HISTORICAL_DIAGNOSTIC_RETAINED` | Writes to `Results/ae_iop_hgo/idA0_score`. Requires sweep workspaces. | Keep. |
| `diagnostics/validate_idA0_grid.m` | `HEAVY_VALIDATION_WRAPPER` | Delegates to long validation implementation that uses shared identity-A0 validation defaults. | Keep. |
| `diagnostics/validate_idA0_score_grid.m` | `HEAVY_VALIDATION_WRAPPER` | Delegates to long validation implementation that uses shared identity-A0 validation defaults. | Keep. |
| `diagnostics/diagnose_modal_atlas.m` | `HISTORICAL_DIAGNOSTIC_WRAPPER` | Delegates to the consolidated modal-atlas implementation. The implementation starts at low frequency by design and writes to `Results/ae_iop_hgo/modal_atlas`. | Keep. |
| `diagnostics/diagnose_grid_start_sensitivity.m` | `HISTORICAL_DIAGNOSTIC_RETAINED` | Writes to `Results/ae_iop_hgo/grid_start_sensitivity`. Retained as evidence for the decision that modal-atlas workflows should start at low frequency by default. | Keep for traceability; do not list as maintained evidence. |
| `diagnostics/track_raw_branch1.m` | `REPRODUCIBILITY_ENTRYPOINT` | Calls `aeExtractRawBranch1Candidate` and writes `Results/ae_iop_hgo/raw_branch1`. | Keep. |

### Removed redundant modal-atlas entrypoints

The separate low-frequency modal-atlas scripts were removed because low-frequency initialization is now implicit in the standard modal-atlas diagnostic.

```text
diagnostics/diagnose_modal_atlas_lowfreq.m
diagnostics/diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
```

### Long implementation targets retained by design

These long descriptive files remain because they contain implementation logic for short entrypoints.

| File | Classification | Reason | Action |
|---|---|---|---|
| `diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m` | `LONG_IMPLEMENTATION_TARGET` | Implementation for `diagnose_modal_atlas`. Generates modal-family ambiguity evidence from low frequency to high frequency; shared atlas-map computation uses `aeComputeModalAtlasForCase`. | Keep. |
| `diagnostics/validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid.m` | `LONG_HEAVY_VALIDATION_IMPLEMENTATION` | Implementation for `validate_idA0_grid`. Writes to clean short path and uses shared validation defaults. | Keep. |
| `diagnostics/validate_acoustoelastic_iop_hgo_branch_identity_score_grid.m` | `LONG_HEAVY_VALIDATION_IMPLEMENTATION` | Implementation for `validate_idA0_score_grid`. Writes to clean short path and uses shared validation defaults. | Keep. |

### Archived categories no longer present in examples

The following categories have been removed from `examples/acoustoelastic_iop_hgo/` after preserving their conclusions in documentation or moving implementation logic into `analysis/`:

```text
simple compatibility aliases
old branch-policy comparison diagnostics
old truncation/failure-landscape/persistence executable diagnostics
E1 direct-matrix exploratory diagnostics
E2 A0-backward/tracking exploratory diagnostics
E3 complex-C example diagnostic
raw_branch1 long implementation script
redundant low-frequency modal-atlas wrapper and implementation
```

Relevant archive and review documents:

```text
docs/acoustoelastic_iop_hgo/legacy_entrypoint_map.md
docs/acoustoelastic_iop_hgo/code_retention_review_plan.md
docs/acoustoelastic_iop_hgo/direct_matrix_landscape_archive.md
docs/acoustoelastic_iop_hgo/a0_backward_tracking_archive.md
docs/acoustoelastic_iop_hgo/complex_c_continuation_archive.md
docs/acoustoelastic_iop_hgo/retained_diagnostic_dependency_review.md
```

### Deletion recommendation

Do not delete more files from `examples/acoustoelastic_iop_hgo/` based only on name similarity.

The remaining cleanup should be tied to solver-interface or physical-model decisions rather than mechanical file cleanup.

### Validation command

After any future change in this module, run:

```matlab
clear functions
rehash toolboxcache
startup

run_acoustoelastic_smoke_tests
```

After broad repository changes, also run:

```matlab
run_all_smoke_tests
```

After raw-branch helper changes, also run:

```matlab
diagnose_modal_atlas
track_raw_branch1
compare_atlasA0_vs_raw_branch1
```
