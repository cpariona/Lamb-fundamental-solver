# Rayleigh-Lamb solver overview

## Current architecture

The Rayleigh-Lamb solver is maintained as a modern `rl*` API under `models/rayleigh_lamb/`. The primary implementation is organized by responsibility: core workflow helpers, residual equations, analytical approximations, and branch tracking. New maintained code should call the `rl*` functions directly.

## Primary implementation layout

```text
models/rayleigh_lamb/core/
models/rayleigh_lamb/equations/
models/rayleigh_lamb/approximations/
models/rayleigh_lamb/tracking/
models/materials/
```

These folders contain the active Rayleigh-Lamb implementation and shared isotropic elastic-material helpers. The material input contract is now `ShearPoisson` for soft-material workflows and `LameParameters` for explicit Lame diagnostics.

## Material inputs

Maintained Rayleigh-Lamb and mRLFE workflows should use:

```matlab
params.modelType = "ShearPoisson";
params.mu = ...;
params.nu = ...;
params.rho = ...;
```

The solver derives:

```text
E
lambda_Lame
K
CT
CL
```

through `elasticFromMuNu`. The explicit `LameParameters` model remains available for formulation checks. The previous `YoungPoissonFixedCL` strategy is no longer part of the maintained route.

## Public API

Use `public_api.md` as the detailed API reference. The main user-facing entrypoints are:

```matlab
rlDefaultParams
rlDefaultOptions
rlComputeFundamentalLambModes
rlComputeAnalyticalApproximations
```

Advanced workflows and tests may also call the lower-level `rl*` helpers documented in the public API reference.

The RL core owns only Rayleigh-Lamb A0/S0 calculation. Its defaults and compute
path do not expose mRLFE flags and do not invoke mRLFE. The intentional
cross-model dependency points in the opposite direction: mRLFE may request an
RL seed through `mrlfeBuildSeed`.

## Examples

Maintained Rayleigh-Lamb examples and validation scripts live under:

```text
examples/rayleigh_lamb/
```

Current basic scripts:

```matlab
run_default_A0
run_default_A0_S0
```

Basic scripts live under:

```text
examples/rayleigh_lamb/basic/
```

and are reserved for minimal default runs without parametric sweeps.

Current sweep scripts:

```matlab
rl_sweep_thickness_A0
rl_sweep_thickness_S0
```

Sweep scripts live under:

```text
examples/rayleigh_lamb/sweeps/
```

Current validation script:

```matlab
check_default_outputs
```

The validation script lives under:

```text
examples/rayleigh_lamb/validation/
```

Current fitting example:

```matlab
fit_default_A0
```

The fitting example lives under:

```text
examples/rayleigh_lamb/fitting/
```

The old top-level example folders were removed. Rayleigh-Lamb examples should remain grouped by model under `examples/rayleigh_lamb/`.

## Sweep helper layer

The maintained thickness sweep entrypoints are branch-specific:

```matlab
rl_sweep_thickness_A0
rl_sweep_thickness_S0
```

They delegate reusable setup to:

```matlab
rlRunSweepExample
```

The helper lives under:

```text
analysis/rayleigh_lamb/
```

It reuses the generic parametric sweep utilities:

```matlab
runParametricSweep
buildParametricSweepPlotData
plotParametricSweepCp
plotSweepCpFigure
summarizeParametricSweepBranch
```

These cross-model utilities are grouped under `analysis/sweeps/`; their MATLAB
command names remain unchanged because startup adds `analysis/` recursively.

This keeps the public sweep examples short while aligning Rayleigh-Lamb sweep naming and outputs with the maintained mRLFE and AE examples. The plotting path preserves Alternative B: `buildParametricSweepPlotData` handles Rayleigh-Lamb result extraction and fixed-parameter formatting, while `plotSweepCpFigure` only renders the neutral curves, main axes, and external information panel.

## Startup/path behavior

`startup.m` adds the repository root, the `models/` tree, the `analysis/` tree, and the maintained model-specific example folders so the primary `rl*` API, Rayleigh-Lamb helpers, and Rayleigh-Lamb examples resolve from any maintained script or test. It does not add old top-level Rayleigh-Lamb folders, and there is no legacy Rayleigh-Lamb compatibility folder to add.

## Tests and validation

`run_core_smoke_tests` validates the modern Rayleigh-Lamb API by checking that the primary `rl*` entrypoints, shared material helpers, fitting helpers, and sweep helpers are on the MATLAB path, then running minimal A0/S0 numerical regression fixtures and the maintained Rayleigh-Lamb synthetic fitting smoke test.

`run_fit_validation_tests` runs the focused synthetic fitting validation suite, including Rayleigh-Lamb A0 single-parameter recovery cases for `mu` and `thickness`.

`run_all_smoke_tests` runs the complete smoke suite across core, GUI, AE IOP/HGO, mRLFE smoke, and mRLFE atlas groups.

Recommended local validation from the repository root after Rayleigh-Lamb documentation or helper changes:

```matlab
clear; clc; close all;
startup
run_core_smoke_tests
run_fit_validation_tests
```

For a complete repository-level check, run:

```matlab
run_all_smoke_tests
```

## GUI development guidance

GUI and app code should expose `mu`, `nu`, `rho`, and full thickness `2h` as primary soft-material inputs. Derived fields such as `E`, `lambda_Lame`, `K`, `CT`, and `CL` should be displayed but not treated as primary inputs in the maintained soft-material route.

## Removed legacy compatibility layer

The old Rayleigh-Lamb compatibility layer has been removed. Historical old-name wrappers are no longer maintained as supported API. Maintained MATLAB code should use the modern `rl*` names only.
