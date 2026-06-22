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

These folders contain the active Rayleigh-Lamb implementation and shared isotropic elastic-material helpers. The material input contract is now `ShearPoisson` for soft-material workflows and `LameParameters` for explicit Lamé diagnostics.

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
sweep_thickness_A0_elastic
sweep_thickness_S0_elastic
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

The old top-level example folders were removed. Rayleigh-Lamb examples should remain grouped by model under `examples/rayleigh_lamb/`.

## Sweep helper layer

The maintained thickness sweep entrypoints are branch-specific:

```matlab
sweep_thickness_A0_elastic
sweep_thickness_S0_elastic
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
plotParametricSweepCp
summarizeParametricSweepBranch
```

This keeps the public sweep examples short while aligning Rayleigh-Lamb sweep naming and outputs with the maintained mRLFE and AE examples.

## Startup/path behavior

`startup.m` adds the repository root, the `models/` tree, the `analysis/` tree, and the maintained model-specific example folders so the primary `rl*` API, Rayleigh-Lamb helpers, and Rayleigh-Lamb examples resolve from any maintained script or test. It does not add old top-level Rayleigh-Lamb folders, and there is no legacy Rayleigh-Lamb compatibility folder to add.

## Tests and validation

`tests/run_all_smoke_tests.m` validates the modern Rayleigh-Lamb API by checking that the primary `rl*` entrypoints, shared material helpers, and sweep helpers are on the MATLAB path, then running minimal A0/S0 numerical regression fixtures. The same smoke suite continues to include non-Rayleigh-Lamb mRLFE and Acoustoelastic IOP/HGO smoke coverage.

Recommended local validation from the repository root:

```matlab
clear functions
rehash toolboxcache
startup
sweep_thickness_A0_elastic
sweep_thickness_S0_elastic
check_default_outputs
run_all_smoke_tests
```

## GUI development guidance

GUI and app code should expose `mu`, `nu`, `rho`, and full thickness `2h` as primary soft-material inputs. Derived fields such as `E`, `lambda_Lame`, `K`, `CT`, and `CL` should be displayed but not treated as primary inputs in the maintained soft-material route.

## Removed legacy compatibility layer

The old Rayleigh-Lamb compatibility layer has been removed. Historical old-name wrappers are no longer maintained as supported API. Maintained MATLAB code should use the modern `rl*` names only.
