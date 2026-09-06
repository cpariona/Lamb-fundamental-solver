# Lamb Fundamental Solver

MATLAB tools for forward fundamental Lamb-wave dispersion and inverse
dispersion fitting in soft materials. The maintained model families are
Rayleigh-Lamb A0/S0, fluid-loaded mRLFE A0Like/S0Like, and prestressed AE
IOP/HGO atlasA0.

## Start

From the repository root in MATLAB:

```matlab
startup
runApp
% Independent fitting surface:
FitTool_GUI
```

The production path contains the repository root, `src/`, `app/`, and only
the six validation launchers under `tests/runners/`. Studies, test bodies,
examples, and generated outputs are not loaded by `startup`.

GUI requests use `executionProfile` (Fast, Balanced, Robust). The established
`robustness` compatibility alias is restricted to app normalization. See the
[profile contract](docs/architecture/execution_profiles_surface_integration.md).

## Programmatic APIs

| Family | Public operations |
| --- | --- |
| RL | `lamb.models.rayleigh_lamb.rlDefaultParams`, `lamb.models.rayleigh_lamb.rlDefaultOptions`, `lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes`, `lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations` |
| mRLFE | `lamb.models.mrlfe.mrlfeDefaultParameters`, `lamb.models.mrlfe.mrlfeDefaultOptions`, `lamb.models.mrlfe.mrlfeSolve` |
| AE | `lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions`, `lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch` |
| Fitting | `lamb.fitting.rayleigh_lamb.rlFitDispersionData`, `lamb.fitting.mrlfe.mrlfeFitDispersionData`, `lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData` |
| Sweep infrastructure | `lamb.sweeps.runParametricSweep` |

Sensitivity campaigns are not production APIs. They live under `studies/`
and call canonical solvers through the generic sweep engine.

## Examples and studies

Six short, opt-in examples remain for complete runnable solver and fitting
demonstrations:

```matlab
run('examples/rayleigh_lamb/basic/run_default_A0_S0.m')
run('examples/rayleigh_lamb/fitting/fit_default_A0.m')
```

Sensitivity campaigns and solver investigations are opt-in studies. A study
script configures its own study path and never changes normal startup:

```matlab
run('studies/sensitivity/rayleigh_lamb/study_thickness_A0.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_modal_atlas.m')
```

Generated figures and results are untracked.

## Validation

After `startup`, invoke any of the six commands directly:

```matlab
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

Each runner loads tests and studies explicitly and restores the caller path.
See [tests](tests/README.md).

## Architecture

- `src/+lamb/+models/` owns physics, tracking, quality, and scientific results.
- `src/+lamb/+fitting/` owns inverse fitting and neutral fitting primitives.
- `src/+lamb/+sweeps/` owns only generic repeated-evaluation infrastructure.
- `app/` owns the solver GUI, FitTool, and request/view translation.
- `studies/` owns sensitivity campaigns and solver investigations.
- `examples/` contains only short solver/fitting API demonstrations.
- `tests/` owns validation and benchmark tooling.

Start with [repository structure](docs/repository/repository_structure.md) and
the [GUI routes](docs/workflows/gui/adapter_architecture.md).
