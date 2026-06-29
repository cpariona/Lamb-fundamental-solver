# mRLFE diagnostics

This folder contains diagnostic scripts used to validate and compare real-k mRLFE atlas policies. These scripts are not lightweight unit tests. They are intended for numerical inspection, policy validation, and generation of `.mat` outputs and figures.

For quick automated checks, use the test runner instead:

```matlab
tests/run_mrlfe_atlas_tests
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
| Historical/candidate for archive | Earlier exploratory diagnostic likely superseded by current tests, primary diagnostics, or policy docs. Do not delete until references and coverage are checked. |

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
| `diagnose_mrlfe_a0_adaptive_policy_mu_sweep.m` | Early adaptive A0 policy sweep; useful for comparing tracker options. |
| `diagnose_mrlfe_a0_direct_visco_atlas_start_failure.m` | Investigates early-start failure in direct viscous A0 atlas tracking. |
| `diagnose_mrlfe_a0_direct_visco_atlas_vs_maintained.m` | Compares direct viscous atlas behavior against maintained/continued branches. |
| `diagnose_mrlfe_a0_low_residual_basins_mu_sweep.m` | Inspects low-residual basin structure over a mu sweep. |
| `diagnose_mrlfe_a0_residual_landscape_mu_sweep.m` | Inspects residual landscapes for A0 branch ambiguity. |
| `diagnose_mrlfe_s0_direct_visco_atlas_cut_boundary.m` | Investigates S0 direct-visco cut boundaries. |
| `diagnose_mrlfe_gui_performance_32kHz.m` | GUI performance diagnostic for high-frequency mRLFE cases. |
| `diagnose_mrlfe_unified_atlas_mu_sweep.m` | Also used as a regression-like manual diagnostic after atlas policy changes. |

### Historical or candidate-for-archive diagnostics

These scripts should not be deleted yet. They should be checked for references and coverage first.

| Script | Provisional reason |
|---|---|
| `diagnose_mrlfe_a0_dp_scan_cost.m` | Likely superseded by current fast atlas preset and timing diagnostics. |
| `diagnose_mrlfe_a0_modal_atlas.m` | Earlier modal-atlas exploration; likely superseded by current adaptive/unified atlas docs. |
| `diagnose_mrlfe_a0_modal_atlas_candidates_23kHz.m` | Narrow historical candidate exploration. |
| `diagnose_mrlfe_a0_modal_atlas_cluster_cut_policy.m` | Earlier policy design diagnostic. |
| `diagnose_mrlfe_a0_modal_atlas_error_map.m` | Earlier residual/error-map exploration. |
| `diagnose_mrlfe_a0_modal_atlas_hook_policy.m` | Earlier hook-policy exploration. |
| `diagnose_mrlfe_a0_modal_atlas_integrated_cut.m` | Earlier integrated-cut exploration. |
| `diagnose_mrlfe_a0_modal_atlas_seed_identity.m` | Earlier seed-identity exploration. |
| `diagnose_mrlfe_visco_direct_atlas.m` | Direct-viscous route exploration likely superseded by direct-atlas evaluator tests and route-policy docs. |

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

Before deleting or moving any diagnostic script, perform a reference search for its function name and verify that any protected behavior is covered by maintained tests or by a retained primary/secondary diagnostic.
