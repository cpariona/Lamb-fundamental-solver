# Rayleigh-Lamb solver overview

## Current architecture

The Rayleigh-Lamb solver is maintained as a modern `rl*` API under `models/rayleigh_lamb/`. The primary implementation is organized by responsibility: core workflow helpers, residual equations, analytical approximations, and branch tracking. New maintained code should call the `rl*` functions directly.

## Primary implementation layout

```text
models/rayleigh_lamb/core/
models/rayleigh_lamb/equations/
models/rayleigh_lamb/approximations/
models/rayleigh_lamb/tracking/
```

These folders contain the active Rayleigh-Lamb implementation. This cleanup did not change numerical algorithms, equations, tolerances, tracking behavior, output structures, or public `rl*` signatures.

## Public API

Use `docs/rayleigh_lamb_public_api.md` as the detailed API reference. The main user-facing entrypoints are:

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

Current scripts:

```matlab
run_default_A0
run_default_A0_S0
sweep_thickness_A0_S0
check_default_outputs
```

The old top-level example folders were removed. Rayleigh-Lamb examples should remain grouped by model under `examples/rayleigh_lamb/`.

## Startup/path behavior

`startup.m` adds the repository root, the `models/` tree, and the maintained model-specific example folders so the primary `rl*` API and Rayleigh-Lamb examples resolve from any maintained script or test. It does not add old top-level Rayleigh-Lamb folders, and there is no legacy Rayleigh-Lamb compatibility folder to add.

## Tests and validation

`tests/run_all_smoke_tests.m` validates the modern Rayleigh-Lamb API by checking that the primary `rl*` entrypoints are on the MATLAB path and by running minimal A0/S0 numerical regression fixtures. The same smoke suite continues to include non-Rayleigh-Lamb mRLFE and Acoustoelastic IOP/HGO smoke coverage.

Recommended local validation from the repository root:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```

## GUI development guidance

GUI and app code should depend on the `rl*` API only. Prefer high-level calls to `rlDefaultParams`, `rlDefaultOptions`, and `rlComputeFundamentalLambModes` for user-facing workflows. Keep UI code separated from solver internals where possible, and avoid adding compatibility aliases for removed historical names.

## Removed legacy compatibility layer

The old Rayleigh-Lamb compatibility layer has been removed. Historical old-name wrappers are no longer maintained as supported API. Maintained MATLAB code should use the modern `rl*` names only.
