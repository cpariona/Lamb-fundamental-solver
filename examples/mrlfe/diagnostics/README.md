# mRLFE diagnostics

This folder contains diagnostic scripts used to validate and compare real-k mRLFE atlas policies. These scripts are not lightweight unit tests. They are intended for numerical inspection, policy validation, and generation of `.mat` outputs and figures.

For quick automated checks, use the focused test runner instead:

```matlab
run_mrlfe_atlas_tests
```

For FitTool route checks, use:

```matlab
run_mrlfe_fit_atlas_tests
```

## Classification policy

Diagnostic scripts are classified as:

| Class | Meaning |
|---|---|
| Primary maintained diagnostic | Current diagnostic workflow for atlas policy, A0/S0 route quality, or FitTool-relevant behavior. |
| Secondary investigation diagnostic | Useful for debugging known failure modes, but not part of the standard validation sequence. |
| Archived diagnostic | Historical exploratory diagnostic preserved under `archive/` for traceability, not part of the maintained workflow. |
| Removed historical diagnostic | Exploratory diagnostic already removed after reference and coverage review. |

A diagnostic can be slow and still be maintained. Do not archive diagnostics based on runtime alone.

## Recommended diagnostic workflow

Use the scripts in this order when validating the current atlas implementation.

### 1. Unified atlas mu sweep

```matlab
diagnose_mrlfe_unified_atlas_mu_sweep
```

Purpose:

- Compare the conservative A0 policy against the adaptive physical-tail A0 policy.
- Keep S0 adaptive continuation as reference.
- Verify that `mrlfeA0Policy = "adaptivePhysicalTail"` improves difficult A0 branches.

Main output:

```text
outputs/mrlfe/mrlfe_unified_atlas_mu_sweep.mat
```

Use this as the first dense diagnostic after code changes affecting A0/S0 atlas behavior.

### 2. A0 policy parametric sweep

```matlab
diagnose_mrlfe_a0_policy_parametric_sweep
```

Purpose:

- Compare A0 policies over a wider grid of `mu`, `etaS`, and thickness.
- Quantify valid-point gain, last-valid-frequency gain, tail cuts, and valley fallback usage.
- Generate diagnostic figures.

Main outputs:

```text
outputs/mrlfe/mrlfe_a0_policy_parametric_sweep.mat
outputs/mrlfe/figures/*.png
outputs/mrlfe/figures/*.fig
```

This script is slower than the mu sweep because it evaluates 84 cases and two A0 policies per case.

### 3. A0 physical-corridor focused diagnostic

```matlab
diagnose_mrlfe_a0_physical_corridor_mu_sweep
```

Purpose:

- Validate the conditional physical tail cut independently of the high-level policy selector.
- Confirm that soft cases are cut after collapse while stiffer cases are preserved.

This is useful when changing:

```matlab
mrlfeA0PhysicalMinRatioToGuide
mrlfeA0PhysicalMaxLocalDropRelative
mrlfeA0PhysicalMaxTwoStepDropRelative
mrlfeA0PhysicalMinValidRunBeforeCut
```

## Current script inventory

### Primary maintained diagnostics

| Script | Role |
|---|---|
| `diagnose_mrlfe_unified_atlas_mu_sweep.m` | Primary A0/S0 unified atlas comparison. |
| `diagnose_mrlfe_a0_policy_parametric_sweep.m` | Broad A0 policy validation over `mu`, `etaS`, and thickness. |
| `diagnose_mrlfe_a0_physical_corridor_mu_sweep.m` | Focused validation of the conditional physical tail cut. |
| `diagnose_mrlfe_atlas_primary_policy_matrix.m` | High-level matrix of policy choices and routing behavior. |
| `diagnose_fit_timing.m` | FitTool-oriented timing diagnostic for mRLFE fitting performance. |
| `diagnose_fit_option_sensitivity.m` | FitTool-oriented option sensitivity diagnostic. |
| `diagnose_etaS_forward_cache.m` | Checks etaS forward-cache behavior relevant to fitting and GUI consistency. |
| `diagnose_etaS_direct_atlas_fit.m` | Direct-atlas etaS fitting diagnostic retained for comparison against maintained FitTool route. |

### Secondary investigation diagnostics

| Script | Role |
|---|---|
| `compare_mrlfe_tracker_vs_condition_peaks.m` | Tracker vs residual/condition-peak diagnostic; supports `docs/mrlfe/diagnostics/tracker_diagnostic_summary.md`. |
| `diagnose_mrlfe_visco_validity_breakdown.m` | Investigates valid/invalid real-k viscous branch segments. |
| `diagnose_mrlfe_visco_residual_landscape.m` | Inspects viscous residual landscapes. |
| `stress_test_mrlfe_real_k_range.m` | Heavy range stress test for material/frequency coverage. |
| `diagnose_direct_atlas_etaS_zero_limit.m` | Checks whether direct atlas can reproduce etaS = 0 behavior; useful but not current default. |
| `diagnose_mrlfe_visco_direct_atlas.m` | Direct-viscous route comparison retained as secondary diagnostic while direct-atlas tests and route-policy docs remain active. |
| `diagnose_mrlfe_gui_performance_32kHz.m` | GUI performance diagnostic for high-frequency mRLFE cases. |

### Archived diagnostics

The following weakly referenced exploratory diagnostics were moved under:

```text
examples/mrlfe/diagnostics/archive/
```

They are preserved for traceability, but they are not part of the maintained diagnostic workflow.

| Script | Archived reason |
|---|---|
| `diagnose_mrlfe_a0_adaptive_policy_mu_sweep.m` | Likely superseded by `diagnose_mrlfe_unified_atlas_mu_sweep.m` and `diagnose_mrlfe_a0_policy_parametric_sweep.m`. |
| `diagnose_mrlfe_a0_direct_visco_atlas_start_failure.m` | Focused direct-atlas failure investigation; likely superseded by route-policy tests plus direct-atlas secondary diagnostics. |
| `diagnose_mrlfe_a0_direct_visco_atlas_vs_maintained.m` | Focused direct-vs-maintained comparison; likely overlaps with retained direct-atlas diagnostics and route-policy tests. |
| `diagnose_mrlfe_a0_low_residual_basins_mu_sweep.m` | Residual-basin exploration; likely overlaps with residual landscape diagnostics. |
| `diagnose_mrlfe_a0_residual_landscape_mu_sweep.m` | Residual landscape exploration; may be redundant with maintained/secondary residual diagnostics. |
| `diagnose_mrlfe_s0_direct_visco_atlas_cut_boundary.m` | Focused S0 direct-atlas boundary investigation; historical unless S0 direct-atlas validation is resumed. |

Before restoring, deleting, or using any archived diagnostic as active evidence:

1. Search active docs, tests, and code references by exact script name.
2. Check whether the diagnostic reproduces an unresolved numerical issue not covered elsewhere.
3. Confirm that primary diagnostics and focused runners still cover the maintained behavior.
4. Run the relevant focused validation before merge.

### Removed historical diagnostics

The following exploratory diagnostics were removed after reference and coverage review because their role is superseded by current diagnostics, tests, or policy documentation:

```text
diagnose_mrlfe_a0_dp_scan_cost.m
diagnose_mrlfe_a0_modal_atlas.m
diagnose_mrlfe_a0_modal_atlas_candidates_23kHz.m
diagnose_mrlfe_a0_modal_atlas_cluster_cut_policy.m
diagnose_mrlfe_a0_modal_atlas_error_map.m
diagnose_mrlfe_a0_modal_atlas_hook_policy.m
diagnose_mrlfe_a0_modal_atlas_integrated_cut.m
diagnose_mrlfe_a0_modal_atlas_seed_identity.m
```

## Current A0 policy wording

The conservative comparison policy is:

```matlab
options.mrlfeA0Policy = "delayedCut";
```

The current FitTool A0Like fitting default and recommended policy for difficult soft, viscous, fluid-loaded A0 cases is:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

Do not treat either policy as experimentally validated for all physical regimes. `adaptivePhysicalTail` is the maintained FitTool route default because it improves the difficult A0-like fitting path, but the parametric sweep showed that some difficult cases use `valleyFallback`, which should be reported as a confidence indicator.

## FitTool dense-grid diagnostic

FitTool uses a fit-consistent primary curve and stores dense solver re-evaluation under:

```matlab
normalized.fullCurve.denseSolver
```

See:

```text
docs/mrlfe/fittool_grid_path_sensitivity.md
```

## Outputs and generated files

Diagnostic scripts save outputs under:

```text
outputs/mrlfe
```

Generated output files are intentionally not source files. Do not commit large `.mat`, `.fig`, or `.png` diagnostic outputs unless a specific report or release requires them.

## When to rerun diagnostics

Rerun the primary diagnostics after changes to:

- `solveMRLFEAtlasUnified.m`
- `solveMRLFEBranchAdaptiveAtlas.m`
- `mrlfeApplyPhysicalCorridorCut.m`
- `mrlfeApplyDelayedViscoModalCut.m`
- `mrlfeMakePhysicalSeedMode.m`
- default mRLFE atlas options

For documentation-only changes, the lightweight test runner is normally sufficient.

## Next cleanup step

For archived diagnostics, choose one of these outcomes only after a focused validation pass:

```text
keep archived for traceability
restore as secondary diagnostic
delete after validation if fully superseded
```
