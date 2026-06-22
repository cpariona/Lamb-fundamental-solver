# Rayleigh-Lamb public API

## API status

The `rl*` functions under `models/rayleigh_lamb/` are the supported Rayleigh-Lamb implementation entrypoints. Historical old-name compatibility wrappers have been removed and are not part of the maintained public API.

For architecture, path behavior, validation, and GUI guidance, see [Rayleigh-Lamb solver overview](overview.md).

## Primary API table

| Folder | Primary function | Purpose |
| --- | --- | --- |
| `models/rayleigh_lamb/core/` | `rlDefaultParams` | Build the default Rayleigh-Lamb parameter structure. |
| `models/rayleigh_lamb/core/` | `rlDefaultOptions` | Build the default Rayleigh-Lamb solver options structure. |
| `models/rayleigh_lamb/core/` | `rlComputeFundamentalLambModes` | Compute the fundamental A0/S0 Rayleigh-Lamb modes and optional model outputs. |
| `models/rayleigh_lamb/core/` | `rlBuildFrequencyVector` | Construct the frequency vector used by the base solver workflow. |
| `models/rayleigh_lamb/core/` | `rlComputeMaterial` | Compute material quantities derived from Rayleigh-Lamb parameters. |
| `models/rayleigh_lamb/core/` | `rlComputeGeometry` | Compute geometry quantities derived from Rayleigh-Lamb parameters. |
| `models/rayleigh_lamb/core/` | `rlMakeBranchSpec` | Construct branch specifications for fundamental-mode tracking. |
| `models/rayleigh_lamb/core/` | `rlValidateParams` | Validate Rayleigh-Lamb parameter structures. |
| `models/rayleigh_lamb/core/` | `rlValidateOptions` | Validate Rayleigh-Lamb solver option structures. |
| `models/rayleigh_lamb/equations/` | `rlAResidual` | Evaluate the normalized antisymmetric Rayleigh-Lamb residual. |
| `models/rayleigh_lamb/equations/` | `rlSResidual` | Evaluate the normalized symmetric Rayleigh-Lamb residual. |
| `models/rayleigh_lamb/approximations/` | `rlComputeA0ThinPlateApproximation` | Compute the A0 thin-plate analytical approximation. |
| `models/rayleigh_lamb/approximations/` | `rlComputeS0ExtensionalApproximation` | Compute the S0 extensional analytical approximation. |
| `models/rayleigh_lamb/approximations/` | `rlComputeAnalyticalApproximations` | Compute the maintained set of analytical Rayleigh-Lamb approximations. |
| `models/rayleigh_lamb/tracking/` | `rlSolveFundamentalBranch` | Solve and track one fundamental Rayleigh-Lamb branch. |

## Recommended user-facing entrypoints

For new user-facing Rayleigh-Lamb code, start with these primary entrypoints:

- `rlDefaultParams`
- `rlDefaultOptions`
- `rlComputeFundamentalLambModes`
- `rlComputeAnalyticalApproximations`

These names should be used for maintained examples, documentation, application code, and analysis scripts that call the base Rayleigh-Lamb implementation directly.

## Maintained examples

Rayleigh-Lamb public/basic examples live under:

```text
examples/rayleigh_lamb/basic/
```

Current public/basic scripts:

```matlab
run_default_A0
run_default_A0_S0
sweep_thickness_A0_S0
```

Rayleigh-Lamb validation scripts live under:

```text
examples/rayleigh_lamb/validation/
```

Current validation script:

```matlab
check_default_outputs
```

These scripts are user-facing examples or validation scripts built on the `rl*` API. They are not compatibility wrappers.

## Sweep helper

The maintained Rayleigh-Lamb thickness sweep wrapper delegates to:

```matlab
rlRunThicknessSweepExample
```

This helper lives under:

```text
analysis/rayleigh_lamb/
```

It is a workflow helper, not a replacement for the `rl*` solver API. Use it for the maintained thickness sweep example or for creating similar short examples.

## Internal/helper entrypoints

Residual, validation, geometry/material, frequency-vector, branch-spec, and tracking helpers are maintained but primarily support the higher-level entrypoints listed above. Direct calls to these helpers may be appropriate for focused diagnostics, tests, or advanced workflows.
