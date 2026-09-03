# Maintained entrypoints

Run `startup` from the repository root before using these commands.

## User and model APIs

```matlab
runApp
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI

rlDefaultParams
rlDefaultOptions
rlComputeFundamentalLambModes
rlComputeAnalyticalApproximations

mrlfeDefaultParameters
mrlfeDefaultOptions
mrlfeSolve

defaultAcoustoelasticIOPHGOOptions
solveAcoustoelasticIOPHGOBranch
```

The supported AE production policy is `atlasA0`. Diagnostic branch algorithms
are not alternative production APIs.

## Analysis APIs

Shared sweep and fitting entrypoints are:

```matlab
runParametricSweep
buildParametricSweepPlotData
plotParametricSweepCp
normalizeExperimentalDispersionData
validateExperimentalDispersionData
solveDispersionFitProblem
```

Model workflow entrypoints are:

```matlab
rlRunSweep
rlFitDispersionData
mrlfeRunSweep
mrlfeFitDispersionData
aeRunSweep
aeRunGridSweep
aeFitDispersionData
```

Main GUI, SweepTool, and FitTool reach mRLFE only through `mrlfeSolve`.

## Examples

Rayleigh-Lamb:

```matlab
run_default_A0_S0
fit_default_A0
rl_sweep_thickness_A0
```

mRLFE:

```matlab
run_default_mrlfe
fit_mrlfe_A0Like
mrlfe_sweep_etaS_A0Like
```

AE IOP/HGO:

```matlab
run_atlas_branch
fit_ae_atlasA0
ae_sweep_iop_A0Like
ae_sweep_mu_iop_A0Like
```

## Diagnostics

```matlab
validate_grid_presets

diagnose_atlas_truncation
diagnose_branch_families
diagnose_grid_start_sensitivity
diagnose_modal_atlas
diagnose_sweep_reliability
```

## Validation

```matlab
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

These are the complete maintained runner surface. Detailed ownership is in
`test_runner_ownership.md`.
