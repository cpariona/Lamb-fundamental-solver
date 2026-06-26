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
test_rl_fit_evaluator_branch_consistency
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
test_rl_fit_evaluator_branch_consistency
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
