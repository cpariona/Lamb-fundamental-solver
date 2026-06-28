# mRLFE diagnostics

This folder contains diagnostic scripts used to validate and compare real-k mRLFE atlas policies. These scripts are not lightweight unit tests. They are intended for numerical inspection, policy validation, and generation of `.mat` outputs and figures.

For quick automated checks, use the test runner instead:

```matlab
tests/run_mrlfe_atlas_tests
```

## Recommended diagnostic workflow

Use the scripts in this order when validating the current atlas implementation.

### 1. Unified atlas mu sweep

```matlab
diagnose_mrlfe_unified_atlas_mu_sweep
```

Purpose:

- Compare the conservative A0 policy against the adaptive physical-tail A0 policy.
- Keep S0 adaptive continuation as reference.
- Verify that `mrlfeA0Policy = "adaptivePhysicalTail"` improves difficult A0 branches without changing the default recommendation.

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

## Primary scripts

These scripts are the main diagnostics for the current policy workflow.

| Script | Role |
|---|---|
| `diagnose_mrlfe_unified_atlas_mu_sweep.m` | Primary A0/S0 unified atlas comparison. |
| `diagnose_mrlfe_a0_policy_parametric_sweep.m` | Broad A0 policy validation over `mu`, `etaS`, and thickness. |
| `diagnose_mrlfe_a0_physical_corridor_mu_sweep.m` | Focused validation of the conditional physical tail cut. |
| `diagnose_mrlfe_atlas_primary_policy_matrix.m` | High-level matrix of policy choices and routing behavior. |

## Secondary investigation scripts

These scripts were used to isolate specific failure modes or guide policy design. They are useful for debugging but are not part of the standard validation sequence.

| Script | Role |
|---|---|
| `diagnose_mrlfe_a0_adaptive_policy_mu_sweep.m` | Early adaptive A0 policy sweep. Useful for comparing tracker options. |
| `diagnose_mrlfe_a0_direct_visco_atlas_start_failure.m` | Investigates early-start failure in direct viscous A0 atlas tracking. |
| `diagnose_mrlfe_a0_direct_visco_atlas_vs_maintained.m` | Compares direct viscous atlas behavior against maintained/continued branches. |
| `diagnose_mrlfe_a0_low_residual_basins_mu_sweep.m` | Inspects low-residual basin structure over a mu sweep. |
| `diagnose_mrlfe_a0_residual_landscape_mu_sweep.m` | Inspects residual landscapes for A0 branch ambiguity. |
| `diagnose_mrlfe_s0_direct_visco_atlas_cut_boundary.m` | Investigates S0 direct-visco cut boundaries. |

## Current A0 policy recommendation

The conservative policy remains:

```matlab
options.mrlfeA0Policy = "delayedCut";
```

The recommended opt-in policy for difficult soft, viscous, fluid-loaded A0 cases is:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

Do not treat `adaptivePhysicalTail` as a global default without additional physical validation. The parametric sweep showed robust coverage improvement, but a substantial fraction of difficult cases used `valleyFallback`, which should be reported as a confidence indicator.

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
