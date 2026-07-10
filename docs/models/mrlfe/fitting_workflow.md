# mRLFE fitting workflow

This document records the maintained mRLFE dispersion fitting workflow after
all maintained consumers migrated to the public production API.

## Maintained Chain

```text
FitTool_GUI
  -> guiFitMRLFESolver
  -> mrlfeFitDispersionData
  -> mrlfeEvaluateFitModel
  -> mrlfeBuildFitSolveRequest
  -> mrlfeSolve
```

There is one maintained physical evaluation route. `mrlfeEvaluateFitModel`
builds a public request and calls `mrlfeSolve`; it does not contain a legacy
opt-out route. `mrlfeEvaluateAtlasFitModel` has been removed.

## Supported Fitting Cases

```text
branch: A0Like or S0Like
free parameter: mu, thickness, or etaS
fixed parameters: remaining elastic/geometric parameters, rho, nu, fluid parameters
```

For `mu` and `thickness` fits, `etaS` may be fixed. In `FitTool_GUI`, this
value is exposed as `Fixed etaS [Pa*s]` when `etaS` is not the free parameter.

## Data Contract

The fitting workflow uses the shared experimental data contract:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Only `frequency_Hz` and `Cp_mps` are required.

## Public Request Mapping

`mrlfeBuildFitSolveRequest` maps fitting parameters to the public SI request
contract:

```matlab
request.branch
request.frequency_Hz
request.material
request.geometry
request.fluid
request.numerics.preset = "fast"
request.selection.strategy = "adaptive"
request.termination.policy
request.fallback.policy = "none"
```

A0Like uses `physicalTail` termination. S0Like uses `none`. No fallback is
applied.

## Metadata

The fitting raw result retains the public model result under:

```matlab
rawResult.modelResult
```

Compatibility fields kept for FitTool and full-curve diagnostics include branch
identity, requested frequencies, Cp values, valid mask, raw branch diagnostics,
route path metadata, preset metadata, and fit performance defaults. Effective
engine names are neutral:

```text
etaS = 0  -> elastic_adaptive
etaS > 0  -> viscoelastic_adaptive
```

The maintained fitting preset is public `fast`. Historical names such as
`fast_fit_atlas` and old atlas route names are not reported as maintained
metadata.

## Fitted Curves

Objective evaluations, automatic full-curve diagnostics, and explicit requested
fitted-curve evaluations all use the same public solver route with the final
fitted parameters. The optimizer, bounds, fixed-parameter handling, weighting,
and residual/objective definition remain owned by `mrlfeFitDispersionData`.
