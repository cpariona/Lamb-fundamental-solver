# Maintained entrypoints

Run `startup` from the repository root for production APIs. Examples and
executable diagnostics are opt-in through the explicit paths shown below.
The six runner launchers are available but load test internals only while running.

## User and model APIs

```matlab
runApp
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI

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

The supported AE production policy is `atlasA0`. Diagnostic branch algorithms
are not alternative production APIs.

## Fitting APIs

The primary family fit APIs and explicit forward evaluators are:

```matlab
lamb.fitting.rayleigh_lamb.rlFitDispersionData
lamb.fitting.rayleigh_lamb.rlEvaluateFitModel
lamb.fitting.mrlfe.mrlfeFitDispersionData
lamb.fitting.mrlfe.mrlfeEvaluateFitModel
lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData
lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel
```

Family-specific fitting defaults are available where the model defaults alone
do not reproduce the established fitting setup:

```matlab
lamb.fitting.mrlfe.mrlfeDefaultFitParameters
lamb.fitting.mrlfe.mrlfeDefaultFitOptions
lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitParameters
lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions
```

## Sweep analysis APIs

The generic 1D workflow is `runParametricSweep`. Model sweep APIs are:

```matlab
rlRunSweep
mrlfeRunSweep
aeRunSweep
aeRunGridSweep
```

Main GUI, SweepTool, and FitTool reach mRLFE only through `lamb.models.mrlfe.mrlfeSolve`.
Shared optimizers, data normalizers, plot-data builders, and renderers are
implementation helpers, not additional public model APIs.

## Examples

Rayleigh-Lamb:

```matlab
run('examples/rayleigh_lamb/basic/run_default_A0_S0.m')
run('examples/rayleigh_lamb/fitting/fit_default_A0.m')
run('examples/rayleigh_lamb/sweeps/rl_sweep_thickness_A0.m')
```

mRLFE:

```matlab
run('examples/mrlfe/basic/run_default_mrlfe.m')
run('examples/mrlfe/fitting/fit_mrlfe_A0Like.m')
run('examples/mrlfe/sweeps/mrlfe_sweep_etaS_A0Like.m')
```

AE IOP/HGO:

```matlab
run('examples/acoustoelastic_iop_hgo/basic/run_atlas_branch.m')
run('examples/acoustoelastic_iop_hgo/fitting/fit_ae_atlasA0.m')
run('examples/acoustoelastic_iop_hgo/sweeps/ae_sweep_iop_A0Like.m')
run('examples/acoustoelastic_iop_hgo/sweeps/ae_sweep_mu_iop_A0Like.m')
```

## Diagnostics

```matlab
run('examples/mrlfe/diagnostics/validate_grid_presets.m')

run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_atlas_truncation.m')
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_branch_families.m')
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_grid_start_sensitivity.m')
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m')
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_sweep_reliability.m')
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
`../../tests/README.md`.
