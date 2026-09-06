# Lamb Fundamental Solver

MATLAB tools for fundamental Lamb-wave dispersion, fitting, and parameter
sweeps in soft materials. Models: Rayleigh-Lamb A0/S0, fluid-loaded mRLFE
A0Like/S0Like, and prestressed AE IOP/HGO atlasA0. S0 and difficult
low-stiffness/high-pressure regimes require careful scientific interpretation.

## Start

From the repository root in MATLAB:

```matlab
startup
runApp
% Other human surfaces:
FitTool_GUI
SweepTool_GUI
```

The production path contains the repository root, `src/`, the remaining
`analysis/` workflows, `app/`, and only the six validation launchers under `tests/runners/`.
It does not load test bodies, examples, or executable diagnostics.

GUI requests use `executionProfile` (Fast, Balanced, Robust). The established
`robustness` input compatibility alias is restricted to app normalization;
new callers use `executionProfile`. See the
[profile contract](docs/architecture/execution_profiles_surface_integration.md).

## Programmatic APIs

| Family | Public operations |
| --- | --- |
| RL | `lamb.models.rayleigh_lamb.rlDefaultParams`, `lamb.models.rayleigh_lamb.rlDefaultOptions`, `lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes`, `lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations` |
| mRLFE | `lamb.models.mrlfe.mrlfeDefaultParameters`, `lamb.models.mrlfe.mrlfeDefaultOptions`, `lamb.models.mrlfe.mrlfeSolve` |
| AE | `lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions`, `lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch` |
| Fitting | `lamb.fitting.rayleigh_lamb.rlFitDispersionData`, `lamb.fitting.mrlfe.mrlfeFitDispersionData`, `lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData` |
| Sweeps | `rlRunSweep`, `mrlfeRunSweep`, `aeRunSweep`, `aeRunGridSweep` |

See [maintained entrypoints](docs/repository/maintained_entrypoints.md) for
scope and [model documentation](docs/README.md) for requests and limitations.

## Examples

Examples are opt-in files, not global production commands:

```matlab
run('examples/rayleigh_lamb/basic/run_default_A0_S0.m')
```

Each example bootstraps the project from its own location. Navigate to its
folder or pass its absolute path to `run`. Generated figures and results are
untracked; scripts may write relative to their execution folder.

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

Each runner loads its test path explicitly and restores the caller path on
success or failure. See [tests](tests/README.md) and
[validation status](docs/repository/validation_status.md).

## Architecture

- `src/+lamb/+models/` owns physics, tracking, quality, and scientific results.
- `src/+lamb/+fitting/` owns inverse fitting and model-neutral fitting primitives.
- `analysis/` temporarily retains sweeps, plotting, IO, and diagnostic interpretation.
- `app/` owns Main GUI, FitTool, SweepTool, and their request/view translation.
- `examples/` contains representative scripts and optional diagnostics.
- `tests/` owns validation and benchmark tooling.

Start with [repository structure](docs/repository/repository_structure.md)
and the [GUI routes](docs/workflows/gui/adapter_architecture.md).
