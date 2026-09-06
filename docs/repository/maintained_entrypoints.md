# Maintained entrypoints

Run `startup` from the repository root for production APIs. The maintained
human surfaces are the solver GUI and FitTool.

## User and model APIs

```matlab
runApp
LambFundamental_GUI
FitTool_GUI

lamb.models.rayleigh_lamb.rlDefaultParams
lamb.models.rayleigh_lamb.rlDefaultOptions
lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes
lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations

lamb.models.mrlfe.mrlfeDefaultParameters
lamb.models.mrlfe.mrlfeDefaultOptions
lamb.models.mrlfe.mrlfeSolve

lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions
lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch
```

## Fitting APIs

```matlab
lamb.fitting.rayleigh_lamb.rlFitDispersionData
lamb.fitting.rayleigh_lamb.rlEvaluateFitModel
lamb.fitting.mrlfe.mrlfeFitDispersionData
lamb.fitting.mrlfe.mrlfeEvaluateFitModel
lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData
lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel

lamb.fitting.mrlfe.mrlfeDefaultFitParameters
lamb.fitting.mrlfe.mrlfeDefaultFitOptions
lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitParameters
lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions
```

## Generic sweep infrastructure

```matlab
lamb.sweeps.runParametricSweep
```

This function is an iteration primitive, not a family-specific scientific
surface. Maintained campaigns and diagnostics are opt-in scripts under
`studies/sensitivity/` and `studies/solver_diagnostics/`.

## Examples and studies

Short solver/fitting examples remain under `examples/<family>/basic/` and
`examples/<family>/fitting/`. Nontrivial campaigns and investigations run by
explicit file path, for example:

```matlab
run('studies/sensitivity/mrlfe/study_etaS_A0Like.m')
run('studies/solver_diagnostics/mrlfe/investigate_mrlfe_grid_presets.m')
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

These are the complete maintained runner surface.
