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

### Acoustoelastic IOP/HGO

Primary production API:

```matlab
solveAcoustoelasticIOPHGOBranch
defaultAcoustoelasticIOPHGOOptions
```

The supported production policy is `atlasA0`. Direct real-Cp, complex-C, and
identity branches are retained diagnostics, not public production outputs.

### mRLFE

```matlab
mrlfeSolve
mrlfeDefaultParameters
mrlfeDefaultOptions
```

`mrlfeSolve` is the production solver entrypoint. Configuration, validation,
presets, tracking, termination, quality, and result builders are maintained
internals, listed separately below.

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

Fitting helpers under `analysis/acoustoelastic_iop_hgo/fitting/`:

```matlab
aeBuildFitProblem
aeEvaluateFitModel
aeFitDispersionData
```

Sweep orchestration, summarization, visualization, and outputs under
`analysis/acoustoelastic_iop_hgo/sweeps/`:

```matlab
aeDefaultSweepOptions
aeDefaultSweepParams
aeRunSweep
aeRunGridSweep
aeBuildGridSweepCpCube
aeBuildSweepPlotData
aeSummarizeSweep
aeSummarizeGridSweep
aePlotSweepCp
aePlotGridSweepCp
aePlotGridSweepCpByAxis
aeWriteSweepOutputs
```

Result/output IO under `analysis/acoustoelastic_iop_hgo/io/`:

```matlab
aeOutputFolder
aeResolveResultFile
aeSaveExampleFigure
aeDeleteExampleFigure
```

Diagnostic computation and defaults under
`analysis/acoustoelastic_iop_hgo/diagnostics/`:

```matlab
summarizeAcoustoelasticIOPHGOTrackingQuality
aeDiagnoseAtlasA0TruncationCause
aeAnalyzeBranchPersistenceCandidates
aeAnalyzeFirstUnrecoveredBreak
aeAnalyzeSweepReliability
aeAnalyzeTruncationRecovery
aeClassifyTruncationRecovery
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
mrlfeSetYoungModulusForShearPoisson
summarizeMRLFETrackingQuality
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

### Rayleigh-Lamb numerical internals

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

### AE numerical internals

```matlab
aeResolveConfiguration
aeValidateRequest
aeGetNumericalPreset
aeBuildInternalTrackingGrid
aeBuildAtlas
aeFindAtlasLocalMinima
aeLinkAtlasBranches
aeSplitAtlasBranches
aeSelectAtlasA0Branch
aeApplyAtlasA0FallbackPolicy
aeEvaluateAtlasA0Quality
aeBuildResult
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
buildAcoustoelasticMatrix
computeAcoustoelasticSRoots
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
solveAcoustoelasticHGOStretch
```

`aeBuildResult` and `aeEvaluateAtlasA0Quality` are canonical internal
owners, not additional public solver routes.

### AE diagnostic model internals

```matlab
aeDefaultDiagnosticOptions
solveAcoustoelasticAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
aeBuildIdentityA0DiagnosticBranch
aeScoreBranchIdentityCandidates
```

These model-owned diagnostic algorithms live under
`models/acoustoelastic_iop_hgo/diagnostics/`. They are used only when the
explicit `identityA0Diagnostic` policy is requested and never own production
`atlasA0` selection or result construction.

### mRLFE production internals

```matlab
mrlfeResolveConfiguration
mrlfeValidateRequest
mrlfeGetNumericalPreset
mrlfeBuildProblem
mrlfeDefaultInternalParameters
mrlfeObjectiveResidual
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
run_default_mrlfe
```

`run_default_mrlfe` demonstrates the default elastic A0Like/S0Like mRLFE route.

## Diagnostics

AE diagnostics:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
diagnose_modal_atlas
validate_idA0_score_grid
validate_idA0_grid
```

mRLFE diagnostics:

```matlab
diagnose_mrlfe_fit_performance
validate_mrlfe_targeted_grid
validate_grid_presets
validate_grid_presets_full
```

## Tests and runners

Use the maintained validation tiers:

```matlab
run_repository_hygiene_tests
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
run_mrlfe_route_integrity_tests
```

Five public convenience wrappers delegate to canonical implementations under
`tests/runners/` through `runRepositoryTestRunner`. Specialized commands resolve
directly from their single canonical runner definitions. The exact wrapper and
ownership contract is maintained in `tests/README.md` and
`docs/repository/test_runner_ownership.md`.

Repository hygiene tests are:

```matlab
test_repository_structure_contract
test_repository_documentation_contract
test_repository_naming_contract
test_repository_tracked_artifacts_contract
test_repository_dependency_boundaries_contract
test_startup_path_policy
test_repository_root_utilities
```
