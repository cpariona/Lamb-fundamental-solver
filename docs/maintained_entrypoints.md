# Maintained entrypoints

This document lists the current maintained execution surface of the repository.

## Setup

```matlab
clear functions
rehash toolboxcache
startup
```

## GUI entrypoints

```matlab
runApp
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI
createFittingTab
guiGetSweepRegistry
guiBuildSweepRequest
guiRunSweep
guiPlotSweepResult
guiRunMRLFESweep
guiNormalizeMRLFESweep
guiRunRLSweep
guiNormalizeRLSweep
guiRunAcoustoelasticIOPHGOSweep
guiNormalizeAcoustoelasticIOPHGOSweep
guiGetFitRegistry
guiBuildFitRequest
guiRunFit
guiFitRLSolver
guiFitMRLFESolver
guiFitAcoustoelasticIOPHGOSolver
guiNormalizeFitResult
guiEvaluateFitFullCurve
guiPlotFitResult
```

## Shared sweep helpers

```matlab
runParametricSweep
plotParametricSweepCp
summarizeParametricSweepBranch
```

mRLFE sweep helpers:

```matlab
mrlfeDefaultSweepParams
mrlfeDefaultSweepOptions
mrlfeMakeSweepSpec
mrlfeRunSweepExample
mrlfeOutputFolder
mrlfeWriteSweepOutputs
mrlfeSaveExampleFigure
```

Rayleigh-Lamb sweep helpers:

```matlab
rlDefaultSweepParams
rlDefaultSweepOptions
rlMakeSweepSpec
rlRunSweepExample
rlOutputFolder
rlWriteSweepOutputs
rlSaveExampleFigure
```

## Shared fitting helpers

```matlab
normalizeExperimentalDispersionData
validateExperimentalDispersionData
computeDispersionFitResiduals
computeDispersionFitMetrics
computeConstantSpeedBaseline
assessFitPhysicalQuality
buildParameterVector
unpackParameterVector
estimateLocalSensitivity
assessFitIdentifiability
```

Maintained fitting tests:

```matlab
test_fitting_helpers_smoke
test_gui_fit_registry_contract
test_fit_tool_model_registry_contract
test_fit_physical_qc_flat_rl
test_fit_physical_qc_synthetic_pass
```

Focused fitting validation suite:

```matlab
run_fit_validation_tests
test_fit_validation_rayleigh_lamb
test_fit_validation_mrlfe
test_fit_validation_mrlfe_hidden_params
test_fit_validation_ae_iop_hgo
test_fit_validation_ae_iop_hgo_hidden_params
assertFitRecovery
```

## Rayleigh-Lamb base solver

Maintained Rayleigh-Lamb implementation entrypoints use the `rl*` API:

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

Maintained Rayleigh-Lamb fitting helpers:

```matlab
rlBuildFitProblem
rlEvaluateFitModel
rlFitDispersionData
```

Maintained Rayleigh-Lamb examples:

```matlab
run_default_A0
run_default_A0_S0
sweep_thickness_A0_elastic
sweep_thickness_S0_elastic
check_default_outputs
fit_default_A0
```

Maintained Rayleigh-Lamb tests:

```matlab
test_rl_fit_synthetic_A0
```

Focused Rayleigh-Lamb fitting validation is covered by:

```matlab
run_fit_validation_tests
```

with Rayleigh-Lamb cases documented in:

```text
docs/rayleigh_lamb/fitting_workflow.md
docs/fitting/validation_suite.md
```

## Acoustoelastic IOP/HGO model

Recommended solver/API entrypoints:

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
aeNormalizeBranchPolicy
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
computeAcoustoelasticSRoots
solveAcoustoelasticHGOStretch
summarizeAcoustoelasticIOPHGOTrackingQuality
aeRunSweep
aeSummarizeSweep
```

Maintained AE IOP/HGO fitting helpers:

```matlab
aeBuildFitProblem
aeEvaluateFitModel
aeFitDispersionData
```

Maintained public workflows:

```matlab
run_atlas_branch
sweep_iop
sweep_mu
sweep_mu_iop
```

Maintained AE IOP/HGO fitting example:

```matlab
fit_ae_atlasA0
```

Maintained diagnostic evidence:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
```

Maintained AE IOP/HGO fitting test:

```matlab
test_ae_fit_synthetic_atlasA0
```

## mRLFE model

Main high-level function for the maintained forward workflow:

```matlab
computeMRLFE
```

Maintained analysis helpers:

```matlab
objectiveMRLFEResidual
mrlfeModelCandidateNames
mrlfeSetYoungModulusForShearPoisson
mrlfeSelectRealKBranches
summarizeMRLFETrackingQuality
compareMRLFETrackingStrategies
compareMRLFEAtlasPolicy
mrlfeApplyDelayedViscoModalCut
mrlfeApplyPhysicalCorridorCut
mrlfeMakeDirectViscoAtlasBranchOptions
```

Maintained mRLFE fitting helpers:

```matlab
mrlfeBuildFitProblem
mrlfeEvaluateFitModel
mrlfeEvaluateAtlasFitModel
mrlfeFitDispersionData
```

Maintained mRLFE real-k atlas solver helpers:

```matlab
solveMRLFEViscoBranchAtlas
solveMRLFEAtlasUnified
solveMRLFEBranchAdaptiveAtlas
mrlfeMakePhysicalSeedMode
```

`solveMRLFEViscoBranchAtlas` remains the direct viscous atlas route. `solveMRLFEAtlasUnified` is the unified real-k atlas route. FitTool fitting uses the atlas-first evaluator by default.

Current A0 policy selector:

```matlab
options.mrlfeA0Policy = "delayedCut";
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

For A0Like FitTool fitting, the current default is:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

Maintained public sweep wrappers:

```matlab
sweep_mu_A0Like_viscoelastic
sweep_mu_S0Like_viscoelastic
sweep_etaS_A0Like_viscoelastic
sweep_etaS_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

Maintained mRLFE fitting example:

```matlab
fit_mrlfe_A0Like
```

Maintained mRLFE diagnostics:

```matlab
compare_mrlfe_tracker_vs_condition_peaks
diagnose_etaS_direct_atlas_fit
diagnose_etaS_forward_cache
diagnose_fit_timing
diagnose_fit_option_sensitivity
diagnose_mrlfe_visco_validity_breakdown
diagnose_mrlfe_visco_residual_landscape
stress_test_mrlfe_real_k_range
```

Maintained mRLFE atlas diagnostics:

```matlab
diagnose_mrlfe_unified_atlas_mu_sweep
diagnose_mrlfe_a0_policy_parametric_sweep
diagnose_mrlfe_a0_physical_corridor_mu_sweep
diagnose_mrlfe_atlas_primary_policy_matrix
```

Additional mRLFE secondary and historical diagnostics are documented in:

```text
examples/mrlfe/diagnostics/README.md
```

Maintained mRLFE tests:

```matlab
test_mrlfe_smoke
test_mrlfe_direct_visco_atlas_evaluator
test_mrlfe_direct_visco_atlas_modal_cut_policy
test_mrlfe_direct_visco_atlas_option_alias_contract
test_mrlfe_etaS_fit_forward_cache
test_mrlfe_etaS_zero_limit
test_mrlfe_elastic_reference_buffer
test_mrlfe_residual_objective_contract
test_mrlfe_internal_tracking_grid
test_mrlfe_internal_tracking_grid_with_buffer
test_mrlfe_viscous_default_internal_tracking_grid
test_mrlfe_tracking_quality_summary
test_mrlfe_tracking_strategy_comparison
test_mrlfe_internal_grid_quality_guard
test_mrlfe_maintained_entrypoints_naming
test_mrlfe_model_candidate_names
test_mrlfe_diagnostic_material_sweep_contract
test_mrlfe_etaS_zero_diagnostic_selection
test_mrlfe_fit_synthetic_A0Like
test_mrlfe_fit_fast_options_quality
```

Maintained mRLFE atlas tests:

```matlab
run_mrlfe_atlas_tests
test_mrlfe_modal_atlas_ambiguity_contract
test_mrlfe_modal_atlas_s0_contract
test_mrlfe_atlas_policy_matrix_contract
test_mrlfe_direct_visco_branch_policy_contract
test_mrlfe_delayed_visco_modal_cut_contract
test_mrlfe_a0_delayed_direct_visco_opt_in_contract
test_mrlfe_a0_delayed_direct_visco_s0_guard_contract
test_mrlfe_unified_atlas_route_contract
test_mrlfe_s0_adaptive_atlas_tracker_contract
test_mrlfe_unified_atlas_mu_sweep_contract
test_mrlfe_a0_policy_selector_contract
```

Maintained GUI mRLFE atlas integration tests:

```matlab
test_gui_mrlfe_unified_atlas_policy_contract
test_gui_mrlfe_fit_zero_eta_atlas_contract
test_gui_mrlfe_fit_route_policy_contract
test_gui_mrlfe_fixed_etaS_fit_contract
test_gui_mrlfe_fit_full_curve_fast_contract
```

## Smoke-test scope

Run the full maintained suite:

```matlab
run_all_smoke_tests
```

Run focused groups after localized changes:

```matlab
run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
run_mrlfe_atlas_tests
```

Run focused fitting validation separately:

```matlab
run_fit_validation_tests
```

Run focused mRLFE FitTool atlas validation after mRLFE fitting-route or fitted-curve changes:

```matlab
run_mrlfe_fit_atlas_tests
```

## Active documentation links

```text
docs/README.md
docs/repository_structure.md
docs/naming_strategy.md
docs/validation_status.md
docs/maintained_entrypoints.md
docs/repository_hygiene_plan.md
docs/docs_foundation_cleanup_audit.md
docs/fitting/README.md
docs/fitting/architecture.md
docs/fitting/validation_suite.md
docs/mrlfe/README.md
docs/mrlfe/fitting_workflow.md
docs/mrlfe/fittool_grid_path_sensitivity.md
docs/mrlfe/current_sweeps.md
docs/mrlfe/docs_cleanup_audit.md
docs/mrlfe_atlas_policy_notes.md
examples/mrlfe/diagnostics/README.md
docs/gui/adapter_architecture.md
docs/gui/mrlfe_atlas_policy_integration.md
docs/gui/integration_audit.md
docs/gui/main_pending_cleanup.md
docs/sweeps/parametric_sweeps.md
docs/sweeps/sweep_tool_usage.md
docs/acoustoelastic_iop_hgo/README.md
docs/acoustoelastic_iop_hgo/documentation_index.md
```

## Archived or historical documentation

```text
docs/archive/fitting_phase_logs.md
docs/archive/fitting_phases/fitting_phase*_status.md
docs/mrlfe/archive/pending_cleanup.md
```
