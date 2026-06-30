# Rayleigh-Lamb public API

## API status

The `rl*` functions under `models/rayleigh_lamb/` are the supported Rayleigh-Lamb implementation entrypoints. Historical old-name compatibility wrappers have been removed and are not part of the maintained public API.

For architecture, path behavior, validation, and GUI guidance, see [Rayleigh-Lamb solver overview](overview.md).

For the model-specific fitting workflow, see [Rayleigh-Lamb fitting workflow](fitting_workflow.md).

## Material-parameter convention

The maintained soft-material input model is:

```matlab
params.modelType = "ShearPoisson";
params.mu = ...;   % shear modulus [Pa]
params.nu = ...;   % Poisson ratio [-]
params.rho = ...;  % density [kg/m^3]
```

`rlComputeMaterial` derives `E`, `lambda`, `K`, `CT`, and `CL` through the shared material helpers in `models/materials/`.

The explicit Lamé route remains available for diagnostics and formulation checks:

```matlab
params.modelType = "LameParameters";
params.lambda = ...;
params.mu = ...;
params.rho = ...;
```

The previous `YoungPoissonFixedCL` route is no longer part of the maintained material contract.

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
| `models/materials/` | `elasticFromMuNu` | Build equivalent isotropic elastic parameters from `mu`, `nu`, and `rho`. |
| `models/materials/` | `elasticFromLame` | Build equivalent isotropic elastic parameters from Lamé constants and `rho`. |

## Recommended user-facing entrypoints

For new user-facing Rayleigh-Lamb code, start with these primary entrypoints:

- `rlDefaultParams`
- `rlDefaultOptions`
- `rlComputeFundamentalLambModes`
- `rlComputeAnalyticalApproximations`

These names should be used for maintained examples, documentation, application code, and analysis scripts that call the base Rayleigh-Lamb implementation directly.

## Fitting helpers

The maintained Rayleigh-Lamb fitting helpers live under:

```text
analysis/rayleigh_lamb/
```

Current fitting helpers:

```matlab
rlBuildFitProblem
rlEvaluateFitModel
rlFitDispersionData
```

`rlEvaluateFitModel` evaluates A0/S0 directly on a supplied fitting frequency grid. It does not use `rlBuildFrequencyVector`, which allows one-point frequency-speed fitting workflows.

Maintained synthetic validation covers A0 single-parameter recovery cases through `run_fit_validation_tests`:

```text
RL_A0_mu_exact
RL_A0_thickness_exact
RL_A0_mu_perturbed
```

## Maintained examples

Rayleigh-Lamb basic examples live under:

```text
examples/rayleigh_lamb/basic/
```

Current basic scripts:

```matlab
run_default_A0
run_default_A0_S0
```

Rayleigh-Lamb sweep examples live under:

```text
examples/rayleigh_lamb/sweeps/
```

Current sweep scripts:

```matlab
sweep_thickness_A0_elastic
sweep_thickness_S0_elastic
```

Rayleigh-Lamb validation scripts live under:

```text
examples/rayleigh_lamb/validation/
```

Current validation script:

```matlab
check_default_outputs
```

Rayleigh-Lamb fitting examples live under:

```text
examples/rayleigh_lamb/fitting/
```

Current fitting script:

```matlab
fit_default_A0
```

These scripts are user-facing examples or validation scripts built on the `rl*` API. They are not compatibility wrappers.

## Sweep helper

The maintained Rayleigh-Lamb thickness sweep wrappers delegate to:

```matlab
rlRunSweepExample
```

This helper lives under:

```text
analysis/rayleigh_lamb/
```

It is a workflow helper, not a replacement for the `rl*` solver API. Use it for maintained branch-specific sweep examples or for creating similar short examples.

## Internal/helper entrypoints

Residual, validation, geometry/material, frequency-vector, branch-spec, tracking, and fitting helpers are maintained but primarily support the higher-level entrypoints listed above. Direct calls to these helpers may be appropriate for focused diagnostics, tests, or advanced workflows.
