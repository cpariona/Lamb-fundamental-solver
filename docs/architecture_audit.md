# Architecture audit

Scope: audit-only inventory of MATLAB files on branch `rename/internal-acoustoelastic-api`. No implementation migration is performed here.

Category key:

1. GUI/app
2. Rayleigh-Lamb base physics
3. mRLFE physics
4. Acoustoelastic IOP/HGO physics
5. generic analysis utility
6. model-specific analysis/diagnostic
7. maintained example
8. validation script
9. smoke/integration test
10. archive/prototype/legacy

| Current path | Primary function/script | Category | Proposed target folder | Rename? | Wrapper? | Risk | Reason |
|---|---|---:|---|---|---|---|---|
| `analysis/plotParametricSweepCp.m` | `plotParametricSweepCp` | 5 | `analysis/` | No | No | Low | Generic plotting helper for sweep outputs. |
| `analysis/runParametricSweep.m` | `runParametricSweep` | 5 | `analysis/` | No | No | Low | Generic parameter-sweep utility, not model-specific by name. |
| `analysis/summarizeLi2024TrackingQuality.m` | `summarizeLi2024TrackingQuality` | 6 | `analysis/acoustoelastic_iop_hgo/` | Yes, later | Yes | Medium | Acoustoelastic tracking-quality summary still carries Li2024 internal naming. |
| `analysis/summarizeParametricSweepBranch.m` | `summarizeParametricSweepBranch` | 5 | `analysis/` | No | No | Low | Generic branch summary helper for parametric sweeps. |
| `app/LambFundamental_GUI.m` | `LambFundamental_GUI` | 1 | `app/` | No | No | High | Main GUI entrypoint depends on many paths and callbacks. |
| `app/SweepTool_GUI.m` | `SweepTool_GUI` | 1 | `app/` | No | No | High | GUI sweep tool with user-facing callback dependencies. |
| `app/createAdvancedTab.m` | `createAdvancedTab` | 1 | `app/` | No | No | Medium | GUI tab construction helper. |
| `app/createModelTabs.m` | `createModelTabs` | 1 | `app/` | No | No | Medium | GUI model-tab helper; may reference model entrypoints. |
| `app/createPlotTab.m` | `createPlotTab` | 1 | `app/` | No | No | Medium | GUI plotting-tab helper. |
| `app/createSetupTab.m` | `createSetupTab` | 1 | `app/` | No | No | Medium | GUI setup-tab helper. |
| `approximations/computeA0ThinPlateApproximation.m` | `computeA0ThinPlateApproximation` | 2 | `models/rayleigh_lamb/approximations/` | No | Maybe | Medium | Rayleigh-Lamb low-frequency A0 approximation. |
| `approximations/computeAnalyticalApproximations.m` | `computeAnalyticalApproximations` | 2 | `models/rayleigh_lamb/approximations/` | No | Maybe | Medium | Aggregates Rayleigh-Lamb analytical approximations. |
| `approximations/computeS0ExtensionalApproximation.m` | `computeS0ExtensionalApproximation` | 2 | `models/rayleigh_lamb/approximations/` | No | Maybe | Medium | Rayleigh-Lamb low-frequency S0 approximation. |
| `core/buildFrequencyVector.m` | `buildFrequencyVector` | 2 | `models/rayleigh_lamb/core/` | No | Maybe | Medium | Core frequency-grid setup for base solver workflows. |
| `core/computeFundamentalLambModes.m` | `computeFundamentalLambModes` | 2 | `models/rayleigh_lamb/solvers/` | No | Yes | High | Public/base solver orchestration used by GUI, examples, and tests. |
| `core/computeGeometry.m` | `computeGeometry` | 2 | `models/rayleigh_lamb/core/` | No | Maybe | Medium | Base plate geometry normalization. |
| `core/computeMaterial.m` | `computeMaterial` | 2 | `models/rayleigh_lamb/core/` | No | Maybe | Medium | Base material-property normalization. |
| `core/defaultOptions.m` | `defaultOptions` | 2 | `models/rayleigh_lamb/options/` | No | Yes | High | Broadly used base numerical defaults and GUI defaults. |
| `core/defaultParams.m` | `defaultParams` | 2 | `models/rayleigh_lamb/options/` | No | Yes | High | Broadly used base physical defaults and GUI defaults. |
| `core/makeBranchSpec.m` | `makeBranchSpec` | 2 | `models/rayleigh_lamb/core/` | No | Maybe | Medium | Branch-specification helper for fundamental mode solves. |
| `core/validateOptions.m` | `validateOptions` | 2 | `models/rayleigh_lamb/options/` | No | Maybe | Medium | Base options validation. |
| `core/validateParams.m` | `validateParams` | 2 | `models/rayleigh_lamb/options/` | No | Maybe | Medium | Base parameter validation. |
| `equations/rayleighLambAResidual.m` | `rayleighLambAResidual` | 2 | `models/rayleigh_lamb/equations/` | No | Maybe | Medium | Antisymmetric Rayleigh-Lamb residual. |
| `equations/rayleighLambSResidual.m` | `rayleighLambSResidual` | 2 | `models/rayleigh_lamb/equations/` | No | Maybe | Medium | Symmetric Rayleigh-Lamb residual. |
| `examples/acoustoelastic_iop_hgo/basic/run_acoustoelastic_iop_hgo_atlas_branch.m` | `run_acoustoelastic_iop_hgo_atlas_branch` | 7 | `examples/acoustoelastic_iop_hgo/basic/` | No | No | Low | Maintained author-neutral acoustoelastic example entrypoint. |
| `examples/acoustoelastic_iop_hgo/basic/run_li2024_IOP_HGO_A0_atlas_branch.m` | `run_li2024_IOP_HGO_A0_atlas_branch` | 7 | `examples/acoustoelastic_iop_hgo/basic/` | Yes, later | Yes | Medium | Compatibility/development example equivalent to author-neutral atlas branch. |
| `examples/acoustoelastic_iop_hgo/basic/run_li2024_IOP_HGO_A0_backward.m` | `run_li2024_IOP_HGO_A0_backward` | 7 | `examples/acoustoelastic_iop_hgo/basic/` | Yes, later | Yes | Medium | Maintained acoustoelastic backward sweep example with legacy name. |
| `examples/acoustoelastic_iop_hgo/basic/run_li2024_IOP_HGO_A0_complexC.m` | `run_li2024_IOP_HGO_A0_complexC` | 7 | `examples/acoustoelastic_iop_hgo/basic/` | Yes, later | Yes | Medium | Maintained complex-c acoustoelastic example with legacy name. |
| `examples/acoustoelastic_iop_hgo/basic/run_li2024_direct_alpha_beta_gamma.m` | `run_li2024_direct_alpha_beta_gamma` | 7 | `examples/acoustoelastic_iop_hgo/basic/` | Yes, later | Yes | Medium | Constitutive demonstration using legacy alpha/beta/gamma naming. |
| `examples/acoustoelastic_iop_hgo/diagnostics/compare_li2024_tracking_strategies_IOP_HGO.m` | `compare_li2024_tracking_strategies_IOP_HGO` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Maybe | Medium | Model-specific tracking diagnostic with legacy naming. |
| `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_branch_policy.m` | `diagnose_acoustoelastic_iop_hgo_branch_policy` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | No | No | Low | Maintained author-neutral branch-policy diagnostic. |
| `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_IOP_grid_convergence.m` | `diagnose_li2024_IOP_grid_convergence` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Maybe | Medium | Acoustoelastic grid-convergence diagnostic with legacy name. |
| `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_atlas_branch_policy.m` | `diagnose_li2024_atlas_branch_policy` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Yes | Medium | Legacy branch-policy diagnostic; public author-neutral replacement exists. |
| `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_dimensionless_A1.m` | `diagnose_li2024_dimensionless_A1` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Maybe | Medium | Acoustoelastic dimensional diagnostic with legacy name. |
| `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_low_frequency_modal_atlas.m` | `diagnose_li2024_low_frequency_modal_atlas` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Maybe | Medium | Acoustoelastic modal-atlas diagnostic with legacy name. |
| `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_matrix_variants.m` | `diagnose_li2024_matrix_variants` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Maybe | Medium | Matrix-form comparison diagnostic for acoustoelastic model. |
| `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_modal_atlas.m` | `diagnose_li2024_modal_atlas` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Maybe | Medium | Acoustoelastic modal atlas diagnostic with legacy name. |
| `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_residual_landscape.m` | `diagnose_li2024_residual_landscape` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Maybe | Medium | Acoustoelastic residual-landscape diagnostic. |
| `examples/acoustoelastic_iop_hgo/diagnostics/track_li2024_raw_branch1_candidate.m` | `track_li2024_raw_branch1_candidate` | 6 | `examples/acoustoelastic_iop_hgo/diagnostics/` | Yes, later | Maybe | Medium | Low-level candidate tracking diagnostic. |
| `examples/acoustoelastic_iop_hgo/sweeps/sweep_li2024_IOP_HGO_A0_backward.m` | `sweep_li2024_IOP_HGO_A0_backward` | 6 | `examples/acoustoelastic_iop_hgo/sweeps/` | Yes, later | Maybe | Medium | Model-specific acoustoelastic sweep with legacy name. |
| `examples/archive/diagnose_mrlfe_a0_candidates.m` | `diagnose_mrlfe_a0_candidates` | 10 | `examples/archive/` | No | No | Low | Archived mRLFE development diagnostic. |
| `examples/archive/diagnose_mrlfe_a0_visco_residual.m` | `diagnose_mrlfe_a0_visco_residual` | 10 | `examples/archive/` | No | No | Low | Archived viscoelastic residual diagnostic. |
| `examples/archive/diagnose_mrlfe_elastic_soft_range_candidates.m` | `diagnose_mrlfe_elastic_soft_range_candidates` | 10 | `examples/archive/` | No | No | Low | Archived mRLFE soft-range diagnostic. |
| `examples/archive/diagnose_mrlfe_etaS1_local_candidates.m` | `diagnose_mrlfe_etaS1_local_candidates` | 10 | `examples/archive/` | No | No | Low | Archived mRLFE local-candidate diagnostic. |
| `examples/archive/diagnose_mrlfe_etaS1_transition.m` | `diagnose_mrlfe_etaS1_transition` | 10 | `examples/archive/` | No | No | Low | Archived transition diagnostic. |
| `examples/archive/diagnose_mrlfe_s0_visco_residual.m` | `diagnose_mrlfe_s0_visco_residual` | 10 | `examples/archive/` | No | No | Low | Archived S0 viscoelastic residual diagnostic. |
| `examples/archive/prototype_mrlfe_a0_multicandidate_tracker.m` | `prototype_mrlfe_a0_multicandidate_tracker` | 10 | `examples/archive/` | No | No | Low | Historical prototype tracker. |
| `examples/archive/prototype_mrlfe_han_visco_a0_multicandidate_tracker.m` | `prototype_mrlfe_han_visco_a0_multicandidate_tracker` | 10 | `examples/archive/` | No | No | Low | Historical Han viscoelastic prototype tracker. |
| `examples/archive/run_mrlfe_complexk_prototype.m` | `run_mrlfe_complexk_prototype` | 10 | `examples/archive/` | No | No | Low | Archived complex-k prototype. |
| `examples/archive/stress_test_mrlfe_parameter_space.m` | `stress_test_mrlfe_parameter_space` | 10 | `examples/archive/` | No | No | Low | Archived broad parameter-space stress test. |
| `examples/archive/sweep_mrlfe_viscosity.m` | `sweep_mrlfe_viscosity` | 10 | `examples/archive/` | No | No | Low | Archived viscosity sweep. |
| `examples/basic/run_default_A0.m` | `run_default_A0` | 7 | `examples/basic/` | No | No | Low | Maintained base Rayleigh-Lamb A0 example. |
| `examples/basic/run_default_A0_S0.m` | `run_default_A0_S0` | 7 | `examples/basic/` | No | No | Low | Maintained base A0/S0 example. |
| `examples/basic/sweep_thickness_A0_S0.m` | `sweep_thickness_A0_S0` | 7 | `examples/basic/` | No | No | Low | Maintained base thickness-sweep example. |
| `examples/mrlfe/basic/compare_mrlfe_elastic_vs_han_visco_cp.m` | `compare_mrlfe_elastic_vs_han_visco_cp` | 7 | `examples/mrlfe/basic/` | No | No | Low | Maintained mRLFE comparison example. |
| `examples/mrlfe/basic/run_mrlfe_prototype.m` | `run_mrlfe_prototype` | 7 | `examples/mrlfe/basic/` | No | No | Low | Maintained mRLFE example despite prototype suffix. |
| `examples/mrlfe/diagnostics/compare_mrlfe_tracker_vs_condition_peaks.m` | `compare_mrlfe_tracker_vs_condition_peaks` | 6 | `examples/mrlfe/diagnostics/` | No | No | Low | Maintained mRLFE diagnostic. |
| `examples/mrlfe/diagnostics/diagnose_mrlfe_han_visco_residual_landscape.m` | `diagnose_mrlfe_han_visco_residual_landscape` | 6 | `examples/mrlfe/diagnostics/` | No | No | Low | Maintained mRLFE residual-landscape diagnostic. |
| `examples/mrlfe/diagnostics/diagnose_mrlfe_han_visco_validity_breakdown.m` | `diagnose_mrlfe_han_visco_validity_breakdown` | 6 | `examples/mrlfe/diagnostics/` | No | No | Low | Maintained mRLFE validity diagnostic. |
| `examples/mrlfe/sweeps/sweep_mrlfe_shear_viscosity_phase_velocity.m` | `sweep_mrlfe_shear_viscosity_phase_velocity` | 6 | `examples/mrlfe/sweeps/` | No | No | Low | Maintained model-specific sweep. |
| `examples/mrlfe/sweeps/sweep_stiffness_A0Like_viscoelastic.m` | `sweep_stiffness_A0Like_viscoelastic` | 6 | `examples/mrlfe/sweeps/` | No | No | Low | Maintained mRLFE stiffness sweep. |
| `examples/mrlfe/sweeps/sweep_stiffness_S0Like_viscoelastic.m` | `sweep_stiffness_S0Like_viscoelastic` | 6 | `examples/mrlfe/sweeps/` | No | No | Low | Maintained mRLFE stiffness sweep. |
| `examples/mrlfe/sweeps/sweep_thickness_A0Like_viscoelastic.m` | `sweep_thickness_A0Like_viscoelastic` | 6 | `examples/mrlfe/sweeps/` | No | No | Low | Maintained mRLFE thickness sweep. |
| `examples/mrlfe/sweeps/sweep_thickness_S0Like_viscoelastic.m` | `sweep_thickness_S0Like_viscoelastic` | 6 | `examples/mrlfe/sweeps/` | No | No | Low | Maintained mRLFE thickness sweep. |
| `examples/mrlfe/sweeps/sweep_viscosity_A0Like_viscoelastic.m` | `sweep_viscosity_A0Like_viscoelastic` | 6 | `examples/mrlfe/sweeps/` | No | No | Low | Maintained mRLFE viscosity sweep. |
| `examples/mrlfe/sweeps/sweep_viscosity_S0Like_viscoelastic.m` | `sweep_viscosity_S0Like_viscoelastic` | 6 | `examples/mrlfe/sweeps/` | No | No | Low | Maintained mRLFE viscosity sweep. |
| `examples/validation/check_default_outputs.m` | `check_default_outputs` | 8 | `examples/validation/` | No | No | Medium | Validation script checking default output behavior. |
| `examples/validation/stress_test_mrlfe_elastic_range.m` | `stress_test_mrlfe_elastic_range` | 8 | `examples/validation/` | No | No | Medium | Maintained mRLFE validation/stress script. |
| `examples/validation/stress_test_mrlfe_han_visco_range.m` | `stress_test_mrlfe_han_visco_range` | 8 | `examples/validation/` | No | No | Medium | Maintained Han-visco mRLFE validation/stress script. |
| `models/acoustoelastic_iop_hgo/constitutive/computeABGFromIOPHGO_Li2024.m` | `computeABGFromIOPHGO_Li2024` | 4 | `models/acoustoelastic_iop_hgo/constitutive/` | Yes | Yes | High | Constitutive core has legacy name and likely many solver/test callers. |
| `models/acoustoelastic_iop_hgo/constitutive/computeAlphaBetaGamma_Li2024.m` | `computeAlphaBetaGamma_Li2024` | 4 | `models/acoustoelastic_iop_hgo/constitutive/` | Yes | Yes | High | Core constitutive coefficient function with legacy name. |
| `models/acoustoelastic_iop_hgo/constitutive/computePrestressSigma_Li2024.m` | `computePrestressSigma_Li2024` | 4 | `models/acoustoelastic_iop_hgo/constitutive/` | Yes | Yes | High | Prestress computation used by acoustoelastic public paths. |
| `models/acoustoelastic_iop_hgo/constitutive/solveStretchHGO_Li2024.m` | `solveStretchHGO_Li2024` | 4 | `models/acoustoelastic_iop_hgo/constitutive/` | Yes | Yes | High | Nonlinear HGO stretch solve; high numerical sensitivity. |
| `models/acoustoelastic_iop_hgo/core/buildMatrix_Li2024_Acoustoelastic.m` | `buildMatrix_Li2024_Acoustoelastic` | 4 | `models/acoustoelastic_iop_hgo/core/` | Yes | Yes | High | Central acoustoelastic matrix assembly. |
| `models/acoustoelastic_iop_hgo/core/computeSRoots_Li2024.m` | `computeSRoots_Li2024` | 4 | `models/acoustoelastic_iop_hgo/core/` | Yes | Yes | High | Core root calculation for acoustoelastic residual. |
| `models/acoustoelastic_iop_hgo/core/objectiveComplexDet_Li2024_Acoustoelastic.m` | `objectiveComplexDet_Li2024_Acoustoelastic` | 4 | `models/acoustoelastic_iop_hgo/core/` | Yes | Yes | High | Objective function for complex-c branch solving. |
| `models/acoustoelastic_iop_hgo/core/objective_Li2024_Acoustoelastic.m` | `objective_Li2024_Acoustoelastic` | 4 | `models/acoustoelastic_iop_hgo/core/` | Yes | Yes | High | Main acoustoelastic objective for atlas/dispersion solves. |
| `models/acoustoelastic_iop_hgo/options/defaultAcoustoelasticIOPHGOOptions.m` | `defaultAcoustoelasticIOPHGOOptions` | 4 | `models/acoustoelastic_iop_hgo/options/` | No | No | Low | Maintained author-neutral public options entrypoint. |
| `models/acoustoelastic_iop_hgo/options/defaultLi2024AcoustoelasticOptions.m` | `defaultLi2024AcoustoelasticOptions` | 4 | `models/acoustoelastic_iop_hgo/options/` | No | Yes | Low | Existing legacy compatibility wrapper should remain for one release. |
| `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticIOPHGOBranch.m` | `solveAcoustoelasticIOPHGOBranch` | 4 | `models/acoustoelastic_iop_hgo/solvers/` | No | No | Low | Maintained author-neutral public solver entrypoint. |
| `models/acoustoelastic_iop_hgo/solvers/solveDispersionAtlasBranch_Li2024_Acoustoelastic.m` | `solveDispersionAtlasBranch_Li2024_Acoustoelastic` | 4 | `models/acoustoelastic_iop_hgo/solvers/` | Yes | Yes | High | Internal atlas branch solver with broad acoustoelastic dependencies. |
| `models/acoustoelastic_iop_hgo/solvers/solveDispersionComplexC_Li2024_Acoustoelastic.m` | `solveDispersionComplexC_Li2024_Acoustoelastic` | 4 | `models/acoustoelastic_iop_hgo/solvers/` | Yes | Yes | High | Complex-c solver pathway; less likely covered by smoke tests. |
| `models/acoustoelastic_iop_hgo/solvers/solveDispersionIOPHGOAtlasBranch_Li2024.m` | `solveDispersionIOPHGOAtlasBranch_Li2024` | 4 | `models/acoustoelastic_iop_hgo/solvers/` | Yes | Yes | High | Legacy IOP/HGO atlas wrapper/solver. |
| `models/acoustoelastic_iop_hgo/solvers/solveDispersionIOPHGO_Li2024.m` | `solveDispersionIOPHGO_Li2024` | 4 | `models/acoustoelastic_iop_hgo/solvers/` | Yes | Yes | High | Legacy IOP/HGO dispersion solver. |
| `models/acoustoelastic_iop_hgo/solvers/solveDispersion_Li2024_Acoustoelastic.m` | `solveDispersion_Li2024_Acoustoelastic` | 4 | `models/acoustoelastic_iop_hgo/solvers/` | Yes | Yes | High | Legacy low-level acoustoelastic dispersion solver. |
| `models/mrlfe/core/mrlfeMatrix.m` | `mrlfeMatrix` | 3 | `models/mrlfe/core/` | No | No | Medium | Core mRLFE matrix assembly. |
| `models/mrlfe/core/mrlfeResidual.m` | `mrlfeResidual` | 3 | `models/mrlfe/core/` | No | No | Medium | Core mRLFE residual function. |
| `models/mrlfe/options/defaultMRLFEParams.m` | `defaultMRLFEParams` | 3 | `models/mrlfe/options/` | No | No | Low | mRLFE defaults; model name should be preserved. |
| `models/mrlfe/solvers/computeMRLFE.m` | `computeMRLFE` | 3 | `models/mrlfe/solvers/` | No | No | High | High-level mRLFE solver used by examples and tests. |
| `models/mrlfe/solvers/refineMRLFEComplexKRoot.m` | `refineMRLFEComplexKRoot` | 3 | `models/mrlfe/solvers/` | No | No | Medium | mRLFE root-refinement helper. |
| `models/mrlfe/solvers/refineMRLFERealKRoot.m` | `refineMRLFERealKRoot` | 3 | `models/mrlfe/solvers/` | No | No | Medium | mRLFE root-refinement helper. |
| `models/mrlfe/solvers/solveMRLFEBranch.m` | `solveMRLFEBranch` | 3 | `models/mrlfe/solvers/` | No | No | High | Main mRLFE branch solver. |
| `models/mrlfe/solvers/solveMRLFEBranchDP.m` | `solveMRLFEBranchDP` | 3 | `models/mrlfe/solvers/` | No | No | Medium | Dynamic-programming branch solver variant. |
| `runApp.m` | `runApp` | 1 | repo root | No | No | Medium | Top-level GUI launcher. |
| `startup.m` | `startup` | 5 | repo root | No | No | High | Path bootstrapper; explicitly out of scope for edits. |
| `tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_constitutive_identity.m` | `test_acoustoelastic_iop_hgo_constitutive_identity` | 9 | `tests/acoustoelastic_iop_hgo/` | No | No | Low | Maintained author-neutral acoustoelastic smoke/identity test. |
| `tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_strictA0_smoke.m` | `test_acoustoelastic_iop_hgo_strictA0_smoke` | 9 | `tests/acoustoelastic_iop_hgo/` | No | No | Low | Maintained author-neutral strictA0 smoke test. |
| `tests/acoustoelastic_iop_hgo/test_li2024_constitutive_identity.m` | `test_li2024_constitutive_identity` | 9 | `tests/acoustoelastic_iop_hgo/` | Yes, later | Yes | Medium | Legacy compatibility test should wrap/delegate to author-neutral test after migration. |
| `tests/acoustoelastic_iop_hgo/test_li2024_strictA0_smoke.m` | `test_li2024_strictA0_smoke` | 9 | `tests/acoustoelastic_iop_hgo/` | Yes, later | Yes | Medium | Legacy compatibility smoke test should remain for one release. |
| `tests/mrlfe/test_mrlfe_smoke.m` | `test_mrlfe_smoke` | 9 | `tests/mrlfe/` | No | No | Low | Maintained mRLFE smoke test. |
| `tests/run_all_smoke_tests.m` | `run_all_smoke_tests` | 9 | `tests/` | No | No | High | Top-level validation sequence entrypoint. |
| `tracking/solveFundamentalBranch.m` | `solveFundamentalBranch` | 2 | `models/rayleigh_lamb/tracking/` | No | Yes | High | Base Rayleigh-Lamb branch tracker used by solver orchestration. |
