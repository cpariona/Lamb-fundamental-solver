# Maintained entrypoints

This document classifies the maintained MATLAB surface by responsibility. A
maintained internal function is not automatically a public contract.

## Setup

```matlab
clear functions
rehash toolboxcache
startup
```

## Public user entrypoints

GUI launch commands:

```matlab
runApp
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI
```

Maintained executable examples are listed under **Examples** below.

## Public programmatic model APIs

### Rayleigh-Lamb

Primary API:

```matlab
rlDefaultParams
rlDefaultOptions
rlComputeFundamentalLambModes
rlComputeAnalyticalApproximations
```

Advanced supported model functions:

```matlab
rlBuildFrequencyVector
rlComputeGeometry
rlComputeMaterial
rlMakeBranchSpec
rlValidateOptions
rlValidateParams
rlAResidual
rlSResidual
rlComputeA0ThinPlateApproximation
rlComputeS0ExtensionalApproximation
rlSolveFundamentalBranch
```

### Acoustoelastic IOP/HGO

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
defaultAcoustoelasticIOPHGOOptions
aeNormalizeBranchPolicy
```

The supported production policy is `atlasA0`. Diagnostic branches are not
public production outputs.

### mRLFE

```matlab
mrlfeSolve
mrlfeDefaultParameters
mrlfeDefaultOptions
mrlfeValidateRequest
mrlfeGetNumericalPreset
```

`mrlfeSolve` is the production solver entrypoint. The other functions define
the request/default/preset boundary. Configuration, tracking, termination,
quality, and result builders are maintained internals, listed separately below.

## Application APIs and helpers

Cross-surface dispatch and registries:

```matlab
guiGetSweepRegistry
guiBuildSweepRequest
guiRunSweep
guiPlotSweepResult
guiGetFitRegistry
guiBuildFitRequest
guiRunFit
guiNormalizeFitResult
guiEvaluateRequestedFitCurve
```

Model-to-surface adapters in `app/adapters/`:

```matlab
guiRunRayleighLambModel
guiRunMRLFEModel
guiRunAcoustoelasticIOPHGOModel
guiRunRLSweep
guiNormalizeRLSweep
guiRunMRLFESweep
guiNormalizeMRLFESweep
guiRunAcoustoelasticIOPHGOSweep
guiNormalizeAcoustoelasticIOPHGOSweep
guiFitRLSolver
guiFitMRLFESolver
guiFitAcoustoelasticIOPHGOSolver
rlResolveExecutionProfile
mrlfeResolveExecutionProfile
aeResolveExecutionProfile
mrlfeBuildSurfaceExecutionMetadata
```

Cross-surface infrastructure retained at the app root:

```matlab
guiExecutionProfileValues
guiNormalizeExecutionProfile
guiNormalizeControlExecutionProfile
guiFormatExecutionProfileDiagnostics
guiGetStructField
guiMergeStructs
```

FitTool workflow and visual helpers in `app/fitting/` include:

```matlab
createFittingTab
guiBuildFitParameterState
guiBuildFitParameterRequest
guiBuildFitParameterSummaryTable
guiBuildFitQualitySummaryTable
guiBuildFitParameterDisplayTable
guiBuildFitQualityDisplayTable
guiFitDisplayLabel
guiBuildFitDisplayCurve
guiPlotFitResult
guiAppendExperimentalFitRow
guiDeleteExperimentalFitRows
guiMarkExperimentalFitDataEdited
guiValidateFitAxisLimits
guiApplyFitAxisView
```

Main GUI control builders remain at the app root:

```matlab
createSetupTab
createPlotTab
createAdvancedTab
createModelTabs
```

The interactive AE two-parameter sweep visualization is owned by `app/sweep/`:

```matlab
aePlotGridSweepFrequencySurfaceInteractive
```

## Maintained analysis and workflow helpers

### Shared sweeps

The coherent shared sweep module lives under `analysis/sweeps/`:

```matlab
runParametricSweep
buildParametricSweepPlotData
plotParametricSweepCp
plotSweepCpFigure
setSweepPlotLimits
summarizeParametricSweepBranch
```

Shared output-path helper:

```matlab
resolveModelOutputFolder
```

### Shared fitting

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

### Rayleigh-Lamb analysis

```matlab
rlBuildFitProblem
rlEvaluateFitModel
rlFitDispersionData
rlDefaultSweepParams
rlDefaultSweepOptions
rlMakeSweepSpec
rlRunSweepExample
rlOutputFolder
rlWriteSweepOutputs
rlSaveExampleFigure
```

### AE IOP/HGO analysis

Campaign and fitting helpers:

```matlab
aeRunSweep
aeSummarizeSweep
aeDefaultSweepParams
aeDefaultSweepOptions
aeBuildFitProblem
aeEvaluateFitModel
aeFitDispersionData
aeOutputFolder
aeResolveResultFile
```

Maintained diagnostic-analysis helpers include:

```matlab
summarizeAcoustoelasticIOPHGOTrackingQuality
aeScoreBranchIdentityCandidates
aeBuildIdentityA0DiagnosticBranch
aeDiagnoseAtlasA0TruncationCause
aeAnalyzeBranchPersistenceCandidates
aeRefineAtlasA0BranchPersistence
aeClassifyAmbiguityRegime
aeExtractRawBranch1Candidate
aeComputeModalAtlasForCase
aeFindTopModalAtlasLocalMinima
aeLinkModalAtlasMinimaIntoBranches
aeDefaultIdentityA0ValidationParams
aeDefaultIdentityA0ValidationOptions
aeDefaultIdentityA0ValidationGrid
```

### mRLFE analysis

```matlab
mrlfeModelCandidateNames
mrlfeSetYoungModulusForShearPoisson
mrlfeSelectRealKBranches
summarizeMRLFETrackingQuality
compareMRLFETrackingStrategies
mrlfeBuildFitProblem
mrlfeBuildPublicSolveRequest
mrlfeBuildFitSolveRequest
mrlfeBuildGuiSolveRequest
mrlfeBuildSweepSolveRequest
mrlfeEvaluateFitModel
mrlfeFitDispersionData
mrlfeRunSweepExample
mrlfeOutputFolder
```

These are maintained workflows or analysis helpers, not additional public
solver routes.

## Maintained internal model implementation

### Shared materials

```matlab
elasticFromMuNu
elasticFromLame
```

### AE numerical internals

```matlab
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
buildAcoustoelasticMatrix
computeAcoustoelasticSRoots
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
solveAcoustoelasticHGOStretch
```

### mRLFE production internals

```matlab
mrlfeResolveConfiguration
mrlfeBuildProblem
objectiveMRLFEResidual
mrlfeSolveBranch
mrlfeSolveElasticBranch
mrlfeSolveViscoelasticBranch
mrlfeBuildSeed
mrlfeTrackBranchAdaptive
mrlfeApplyTerminationPolicy
mrlfeEvaluatePhysicalTail
mrlfeEvaluateBranchQuality
mrlfeBuildResult
```

Main GUI, SweepTool, and FitTool all reach these internals through `mrlfeSolve`.
No internal model policy, tracker, or result builder is a separate public solver
contract.

## Examples

### Rayleigh-Lamb

```matlab
run_default_A0
run_default_A0_S0
rl_sweep_thickness_A0
rl_sweep_thickness_S0
check_default_outputs
fit_default_A0
```

### AE IOP/HGO

```matlab
run_atlas_branch
ae_sweep_iop_A0Like
ae_sweep_mu_A0Like
ae_sweep_thickness_A0Like
ae_sweep_k1_A0Like
ae_sweep_k2_A0Like
ae_sweep_radius_A0Like
ae_sweep_mu_iop_A0Like
fit_ae_atlasA0
```

### mRLFE

```matlab
mrlfe_sweep_mu_A0Like
mrlfe_sweep_mu_S0Like
mrlfe_sweep_etaS_A0Like
mrlfe_sweep_etaS_S0Like
mrlfe_sweep_thickness_A0Like
mrlfe_sweep_thickness_S0Like
fit_mrlfe_A0Like
run_mrlfe_prototype
```

`run_mrlfe_prototype` remains the documented compatibility example; its name is
not normalized in this phase.

## Diagnostics

AE diagnostics:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility_impl
diagnose_acoustoelastic_iop_hgo_modal_atlas
validate_acoustoelastic_iop_hgo_branch_identity_score_grid
validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid
```

mRLFE diagnostics:

```matlab
diagnose_mrlfe_fit_performance
run_mrlfe_targeted_grid_validation
validate_grid_presets
validate_grid_presets_full
```

## Tests and runners

Use the maintained validation tiers:

```matlab
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

Focused maintained runners include:

```matlab
run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
run_fit_validation_tests
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_legacy_cleanup_tests
```

Nine public compatibility wrappers delegate to canonical implementations under
`tests/runners/` through `runRepositoryTestRunner`. The exact wrapper and
ownership contract is maintained in `tests/README.md` and
`docs/repository/test_runner_ownership.md`.
