# Maintained entrypoints

This document lists the maintained solver, example, diagnostic, and test entrypoints after the acoustoelastic IOP/HGO compatibility-layer cleanup and the mRLFE refactor.

## Setup

From the repository root, run:

```matlab
clear functions
rehash toolboxcache
startup
```

## Rayleigh-Lamb base solver

The `rl*` Rayleigh-Lamb functions under `models/rayleigh_lamb/` are the maintained implementation entrypoints for the base solver.

```matlab
rlBuildFrequencyVector
rlComputeFundamentalLambModes
rlComputeGeometry
rlComputeMaterial
rlDefaultOptions
rlDefaultParams
rlMakeBranchSpec
rlValidateOptions
rlValidateParams
rlAResidual
rlSResidual
rlComputeA0ThinPlateApproximation
rlComputeAnalyticalApproximations
rlComputeS0ExtensionalApproximation
rlSolveFundamentalBranch
```

## Acoustoelastic IOP/HGO model

The supported acoustoelastic API is author-neutral. The former author-specific compatibility wrappers were removed; GUI code, examples, diagnostics, tests, and analysis scripts should call author-neutral functions only.

Recommended entrypoints:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
buildAcoustoelasticMatrix
defaultAcoustoelasticIOPHGOOptions
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
computeAcoustoelasticSRoots
solveAcoustoelasticHGOStretch
summarizeAcoustoelasticIOPHGOTrackingQuality
aeRunSweep
aeSummarizeSweep
```

Maintained examples and diagnostics use `acoustoelastic_iop_hgo` names only:

```matlab
run_acoustoelastic_iop_hgo_atlas_branch
run_acoustoelastic_iop_hgo_A0_backward
run_acoustoelastic_iop_hgo_A0_complexC
run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma
compare_acoustoelastic_iop_hgo_tracking_strategies
compare_acoustoelastic_iop_hgo_branch_policies
diagnose_acoustoelastic_iop_hgo_branch_policy
diagnose_acoustoelastic_iop_hgo_grid_convergence
diagnose_acoustoelastic_iop_hgo_dimensionless_A1
diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas
diagnose_acoustoelastic_iop_hgo_matrix_variants
diagnose_acoustoelastic_iop_hgo_modal_atlas
diagnose_acoustoelastic_iop_hgo_residual_landscape
track_acoustoelastic_iop_hgo_raw_branch1_candidate
sweep_acoustoelastic_iop_hgo_A0_backward
sweep_acoustoelastic_iop_hgo_iop
sweep_acoustoelastic_iop_hgo_mu
```

Maintained tests:

```matlab
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
```

See `docs/acoustoelastic_iop_hgo_public_api.md` for the public API list. Naming guidance is documented in `docs/naming_strategy.md`.

## mRLFE model

Main high-level function:

```matlab
computeMRLFE
```

Useful examples and diagnostics:

```matlab
run_mrlfe_prototype
compare_mrlfe_elastic_vs_han_visco_cp
sweep_mrlfe_shear_viscosity_phase_velocity
diagnose_mrlfe_han_visco_validity_breakdown
diagnose_mrlfe_han_visco_residual_landscape
compare_mrlfe_tracker_vs_condition_peaks
test_mrlfe_smoke
```

## Smoke-test scope

`run_all_smoke_tests` verifies the maintained Rayleigh-Lamb `rl*` path checks, minimal Rayleigh-Lamb numerical fixtures, author-neutral acoustoelastic IOP/HGO entrypoints and tests, and the mRLFE smoke test.

## Active documentation links

The active documentation set is:

```text
docs/repository_structure.md
docs/naming_strategy.md
docs/validation_status.md
docs/rayleigh_lamb_overview.md
docs/rayleigh_lamb_public_api.md
docs/acoustoelastic_iop_hgo_overview.md
docs/acoustoelastic_iop_hgo_public_api.md
docs/acoustoelastic_iop_hgo_branch_policy.md
docs/acoustoelastic_iop_hgo_sweep_workflow.md
docs/parametric_sweeps.md
docs/mrlfe_tracker_diagnostic_summary.md
```
