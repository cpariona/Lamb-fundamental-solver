# Repository structure

This document describes the active repository layout for GUI-focused development. The current MATLAB implementation is organized around the clean Rayleigh-Lamb `rl*` API, the mRLFE model, and the author-neutral acoustoelastic IOP/HGO API.

## Active top-level areas

```text
app/                         MATLAB GUI entrypoints and UI helper files.
analysis/                    Generic analysis utilities plus model-specific analysis helpers.
docs/                        Active repository, API, validation, and workflow documentation.
examples/basic/              Basic Rayleigh-Lamb examples.
examples/validation/         Maintained validation and stress-test scripts.
examples/mrlfe/              Maintained mRLFE examples, sweeps, and diagnostics.
examples/acoustoelastic_iop_hgo/
                             Maintained acoustoelastic IOP/HGO examples, sweeps, and diagnostics.
models/rayleigh_lamb/        Clean Rayleigh-Lamb implementation using `rl*` functions.
models/mrlfe/                Modified Rayleigh-Lamb fluid-loaded model implementation.
models/acoustoelastic_iop_hgo/
                             Author-neutral acoustoelastic IOP/HGO implementation.
tests/                       Smoke and consistency tests.
references/                  Reference material used for development and validation context.
```

## Active MATLAB path and startup

`startup.m` prepares the active implementation, GUI, analysis, example, and test folders for use from the repository root. Maintained callers should use the documented public entrypoints.

Recommended setup sequence:

```matlab
clear functions
rehash toolboxcache
startup
```

## Model folders

### Rayleigh-Lamb base solver

```text
models/rayleigh_lamb/
├─ approximations/
├─ core/
├─ equations/
└─ tracking/
```

Maintained Rayleigh-Lamb implementation functions use the `rl*` API. See `docs/rayleigh_lamb_public_api.md` for the public function list and `docs/rayleigh_lamb_overview.md` for model context.

### mRLFE model

```text
models/mrlfe/
├─ core/
├─ solvers/
└─ options/
```

The high-level mRLFE entrypoint is:

```matlab
computeMRLFE
```

### Acoustoelastic IOP/HGO model

```text
models/acoustoelastic_iop_hgo/
├─ core/
├─ constitutive/
├─ solvers/
└─ options/
```

Recommended author-neutral entrypoints include:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticIOPHGODispersion
defaultAcoustoelasticIOPHGOOptions
```

GUI code, examples, diagnostics, tests, and analysis scripts should call the author-neutral acoustoelastic IOP/HGO API documented in `docs/acoustoelastic_iop_hgo_public_api.md`.

## Example folders

```text
examples/basic/
examples/validation/
examples/mrlfe/
├─ basic/
├─ sweeps/
└─ diagnostics/
examples/acoustoelastic_iop_hgo/
├─ basic/
├─ sweeps/
└─ diagnostics/
```

Maintained examples are intended to exercise active APIs only. Archived example material is not part of the active documentation set.

## Tests

Maintained tests are stored in:

```text
tests/run_all_smoke_tests.m
tests/mrlfe/
tests/acoustoelastic_iop_hgo/
```

Recommended smoke-test sequence after documentation or path-sensitive refactors:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```
