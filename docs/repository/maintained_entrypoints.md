# Maintained entrypoints

This document lists the current maintained execution surface of the repository. Test names are listed by MATLAB entrypoint name; the current folder layout is documented in `tests/README.md`.

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
guiBuildFitParameterSummaryTable
guiBuildFitQualitySummaryTable
guiBuildFitParameterDisplayTable
guiBuildFitQualityDisplayTable
guiFitDisplayLabel
guiEvaluateRequestedFitCurve
guiPlotFitResult
guiAppendExperimentalFitRow
guiDeleteExperimentalFitRows
guiMarkExperimentalFitDataEdited
guiValidateFitAxisLimits
guiApplyFitAxisView
```

## Shared sweep helpers

```matlab
runParametricSweep
plotParametricSweepCp
summarizeParametricSweepBranch
resolveModelOutputFolder
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

Shared path and utility helpers/tests:

```matlab
runRepositoryTestRunner
testRepositoryRoot
test_model_output_folder_helpers
test_repository_root_utilities
test_startup_path_policy
```

Shared app adapter infrastructure:

```matlab
guiGetStructField
guiMergeStructs
test_gui_struct_helpers_contract
```

Shared numerical regression:

```matlab
test_lightweight_numerical_regression
```

Focused fitting validation suite:

```matlab
run_fit_validation_tests
run_fit_tool_interaction_tests
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
rl_sweep_thickness_A0
rl_sweep_thickness_S0
check_default_outputs
fit_default_A0
```

Maintained Rayleigh-Lamb tests:

```matlab
test_rl_fit_synthetic_A0
test_rl_fit_evaluator_branch_consistency
```

Focused Rayleigh-Lamb fitting validation is covered by:

```matlab
run_fit_validation_tests
```

with Rayleigh-Lamb cases documented in:

```text
docs/models/rayleigh_lamb/fitting_workflow.md
docs/workflows/fitting/validation_suite.md
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
ae_sweep_iop_A0Like
ae_sweep_mu_A0Like
ae_sweep_thickness_A0Like
ae_sweep_k1_A0Like
ae_sweep_k2_A0Like
ae_sweep_radius_A0Like
ae_sweep_mu_iop_A0Like
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

Initial maintained public real-k mRLFE contract:

```matlab
mrlfeSolve
mrlfeDefaultParameters
mrlfeDefaultOptions
mrlfeValidateRequest
mrlfeResolveConfiguration
mrlfeGetNumericalPreset
mrlfeBuildResult
mrlfeEvaluateBranchQuality
mrlfeBuildProblem
mrlfeSolveBranch
mrlfeSolveElasticBranch
mrlfeSolveViscoelasticBranch
mrlfeBuildSeed
mrlfeTrackBranchAdaptive
mrlfeApplyTerminationPolicy
```

This public contract is model-oriented and author-neutral. Main GUI, SweepTool,
and FitTool all reach the maintained production core through `mrlfeSolve`.
Obsolete parallel solver routes have been removed from the maintained surface.

Maintained analysis helpers:

```matlab
objectiveMRLFEResidual
mrlfeModelCandidateNames
mrlfeSetYoungModulusForShearPoisson
mrlfeSelectRealKBranches
summarizeMRLFETrackingQuality
compareMRLFETrackingStrategies
mrlfeEvaluatePhysicalTail
```

Maintained mRLFE fitting helpers:

```matlab
mrlfeBuildFitProblem
mrlfeBuildFitSolveRequest
mrlfeBuildGuiSolveRequest
mrlfeBuildSweepSolveRequest
mrlfeEvaluateFitModel
mrlfeFitDispersionData
```

`mrlfeEvaluateFitModel` is the maintained production fitting evaluator and calls
the public `mrlfeSolve` API. `mrlfeEvaluateAtlasFitModel` has been removed.

`guiRunMRLFESweep` is the maintained production SweepTool mRLFE adapter and
calls the public `mrlfeSolve` API once per sweep point through
`mrlfeBuildSweepSolveRequest`. SweepTool no longer delegates mRLFE solving to
the Main GUI adapter, and the maintained sweep route does not apply legacy
zero-viscosity fallback.

`guiRunMRLFEModel` is the maintained production Main GUI mRLFE adapter and calls
the public `mrlfeSolve` API through `mrlfeBuildGuiSolveRequest`. Main GUI no
longer contains low-level mRLFE solver selection or zero-viscosity fallback.

Maintained mRLFE real-k production helpers:

```matlab
mrlfeSolveElasticBranch
mrlfeSolveViscoelasticBranch
mrlfeTrackBranchAdaptive
mrlfeBuildSeed
mrlfeApplyTerminationPolicy
mrlfeEvaluatePhysicalTail
```

Removed legacy route names are documented in
`docs/validation/mrlfe_legacy_route_inventory.md`; they are not maintained
entrypoints.

Maintained sweep plotting and summaries may use the normalized model name `mRLFEViscoRealK` for etaS > 0 real-k cases.

Current A0 policy selector:

```matlab
options.mrlfeA0Policy = "physicalTail";
```

For A0Like FitTool fitting, the current default is:

```matlab
options.mrlfeA0Policy = "physicalTail";
```

Maintained public sweep entrypoints:

```matlab
mrlfe_sweep_mu_A0Like
mrlfe_sweep_mu_S0Like
mrlfe_sweep_etaS_A0Like
mrlfe_sweep_etaS_S0Like
mrlfe_sweep_thickness_A0Like
mrlfe_sweep_thickness_S0Like
```

Maintained mRLFE fitting example:

```matlab
fit_mrlfe_A0Like
```

Maintained mRLFE diagnostics:

```matlab
compare_mrlfe_tracker_vs_condition_peaks
diagnose_etaS_forward_cache
diagnose_fit_timing
diagnose_fit_option_sensitivity
diagnose_mrlfe_atlas_primary_policy_matrix
diagnose_mrlfe_gui_performance_32kHz
diagnose_mrlfe_visco_validity_breakdown
diagnose_mrlfe_visco_residual_landscape
stress_test_mrlfe_real_k_range
```

Additional mRLFE secondary and historical diagnostics are documented in:

```text
examples/mrlfe/diagnostics/README.md
```

Maintained mRLFE model-family tests:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
test_mrlfe_smoke
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
test_mrlfe_etaS_fit_forward_cache
```

Maintained mRLFE FitTool public-solver migration tests:

```matlab
run_mrlfe_fit_public_solver_tests
test_mrlfe_fit_uses_public_solver
test_mrlfe_fit_public_solver_characterization
test_mrlfe_fit_public_solver_parameter_regression
```

Maintained mRLFE SweepTool public-solver migration tests:

```matlab
run_mrlfe_sweeptool_public_solver_tests
test_mrlfe_sweep_uses_public_solver
test_mrlfe_sweep_point_characterization
test_mrlfe_sweep_metadata_and_mapping
```

Maintained mRLFE Main GUI public-solver migration tests:

```matlab
run_mrlfe_main_gui_public_solver_tests
test_mrlfe_main_gui_uses_public_solver
test_mrlfe_main_gui_characterization
test_mrlfe_main_gui_consumer_equivalence
test_mrlfe_main_gui_result_contract
```

Maintained mRLFE legacy-cleanup tests:

```matlab
run_mrlfe_legacy_cleanup_tests
test_mrlfe_no_legacy_routes
test_mrlfe_no_legacy_route_flags
test_mrlfe_legacy_cleanup_characterization
```

Maintained GUI mRLFE public-solver integration tests:

```matlab
test_gui_mrlfe_fit_route_policy_contract
test_gui_mrlfe_fixed_etaS_fit_contract
test_gui_mrlfe_fit_full_curve_fast_contract
```

## Smoke-test scope

### Public commands and implementations

The maintained public runner commands below intentionally resolve through thin
compatibility wrappers to same-named implementations under `tests/runners/`:

```matlab
run_acoustoelastic_smoke_tests
run_all_smoke_tests
run_core_smoke_tests
run_gui_smoke_tests
run_mrlfe_legacy_cleanup_tests
run_mrlfe_production_core_tests
run_mrlfe_public_contract_tests
run_mrlfe_smoke_tests
run_fit_validation_tests
```

The first eight wrappers are at the root of `tests/`. The fitting wrapper is
deliberately retained at `tests/fitting/run_fit_validation_tests.m` for legacy
path compatibility. `run_main_gui_export_tests` is also a maintained public
command, but it is a standalone root runner rather than a wrapper.

Runner maintenance should target the implementation under `tests/runners/`.
The wrapper files preserve command compatibility and should remain thin.

Use the maintained validation tiers for new work:

```matlab
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

`run_quick_smoke_tests` is the routine command. The numerical, extended, and
performance commands are explicit opt-in surfaces. The canonical mapping is in
`docs/repository/test_runner_ownership.md`.

The historical `run_all_smoke_tests` command remains a broad compatibility
aggregate. It reaches contracts, numerical regression, and historical model
coverage, so its name does not imply a quick-runtime guarantee.

Run focused groups after localized changes:

```matlab
run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
run_mrlfe_legacy_cleanup_tests
```

Run focused fitting validation separately:

```matlab
run_fit_validation_tests
```

The execution-profile matrix, diagnostic runners, mRLFE production-core
characterization/performance coverage, and consumer characterization are
maintained extended or manual validation surfaces. They are intentionally not
normal quick-smoke prerequisites. `run_main_gui_export_tests` remains the
focused standalone public runner for the Main GUI export contract. The stale
mapped-to-Fast benchmark is manual and deferred; it is not executed by any
normal runner.

Run focused mRLFE FitTool public-solver validation after mRLFE fitting-route or fitted-curve changes:

```matlab
run_mrlfe_fit_public_solver_tests
```

## Active documentation links

```text
docs/README.md
docs/repository/repository_structure.md
docs/repository/naming_strategy.md
docs/repository/validation_status.md
docs/repository/maintained_entrypoints.md
docs/repository/matlab_dependency_audit.md
docs/repository/repository_hygiene_plan.md
docs/repository/docs_foundation_cleanup_audit.md
docs/workflows/fitting/README.md
docs/workflows/fitting/architecture.md
docs/workflows/fitting/validation_suite.md
docs/models/mrlfe/README.md
docs/models/mrlfe/fitting_workflow.md
docs/models/mrlfe/fittool_grid_path_sensitivity.md
docs/models/mrlfe/current_sweeps.md
docs/models/mrlfe/docs_cleanup_audit.md
docs/models/mrlfe/diagnostics/README.md
docs/models/mrlfe/diagnostics/tracker_diagnostic_summary.md
docs/models/mrlfe/atlas_policy_notes.md
examples/mrlfe/diagnostics/README.md
docs/workflows/gui/adapter_architecture.md
docs/workflows/gui/mrlfe_atlas_policy_integration.md
docs/workflows/gui/integration_audit.md
docs/workflows/gui/main_pending_cleanup.md
docs/workflows/sweeps/parametric_sweeps.md
docs/workflows/sweeps/sweep_tool_usage.md
docs/models/acoustoelastic_iop_hgo/README.md
docs/models/acoustoelastic_iop_hgo/documentation_index.md
```

## Archived or historical documentation

```text
docs/archive/fitting_phase_logs.md
docs/archive/fitting_phases/fitting_phase*_status.md
docs/models/mrlfe/archive/pending_cleanup.md
```
