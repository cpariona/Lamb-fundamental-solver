# Lamb Fundamental Solver

MATLAB forward solvers and inverse-fitting tools for fundamental Lamb-wave
dispersion in soft materials. Maintained families are Rayleigh-Lamb A0/S0,
fluid-loaded mRLFE A0Like/S0Like, and prestressed acoustoelastic IOP/HGO
`atlasA0`.

## Start

From the repository root:

```matlab
startup
runApp                 % Solver GUI
FitTool_GUI            % Independent fitting GUI
```

GUI requests use `executionProfile` (`Fast`, `Balanced`, or `Robust`). The
`robustness` compatibility alias is accepted only at app normalization
boundaries.

## Canonical APIs

| Family | Public operations |
| --- | --- |
| Rayleigh-Lamb | `lamb.models.rayleigh_lamb.rlDefaultParams`, `lamb.models.rayleigh_lamb.rlDefaultOptions`, `lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes`, `lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations` |
| mRLFE | `lamb.models.mrlfe.mrlfeDefaultParameters`, `lamb.models.mrlfe.mrlfeDefaultOptions`, `lamb.models.mrlfe.mrlfeSolve` |
| AE IOP/HGO | `lamb.models.acoustoelastic_iop_hgo.aeDefaultOptions`, `lamb.models.acoustoelastic_iop_hgo.aeSolveBranch` |
| Fitting | `lamb.fitting.rayleigh_lamb.rlFitDispersionData`, `lamb.fitting.mrlfe.mrlfeFitDispersionData`, `lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData` |
| Sweeps | `lamb.sweeps.runParametricSweep` |

Use MATLAB `help` on an entrypoint for its request, units, result, and validity
contract.

## Examples

Examples and studies are opt-in and are not added by `startup`:

```matlab
run('examples/rayleigh_lamb/basic/rlRunDefaultA0S0.m')
run('examples/mrlfe/basic/mrlfeRunDefault.m')
run('examples/acoustoelastic_iop_hgo/basic/aeRunAtlasBranch.m')
run('examples/rayleigh_lamb/fitting/rlFitDefaultA0.m')
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

The six runners form the complete maintained validation surface.
