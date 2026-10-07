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

### Production material support

Rayleigh-Lamb production supports `0.49 <= effective nu < 0.5`, including
effective Poisson ratio derived from Lamé parameters; the default is `0.4999`.
Material values are never clipped or substituted. Values below this interval
are outside the production-qualified RL domain, not physically impossible
materials. Generic elasticity utilities retain their broader mathematical
domain. Maintained mRLFE execution inherits this interval because its seed uses
the public RL solver; mRLFE retains its own physical dependence on `nu`.

Numerical qualification covers the maintained operational fundamental-mode
regime tested by this repository, not a mathematical proof for arbitrary
`Omega -> infinity`.

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
clear functions;
startup;
addpath(fullfile(pwd, "tests", "runners"), "-end");
summary = run_regression_tests;
```

See [architecture](docs/repository/final_architecture.md) for ownership and
[validation](docs/repository/validation_status.md) for the gate contract.
