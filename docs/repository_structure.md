# Repository structure

This document describes the active folder structure after the Acoustoelastic IOP/HGO and mRLFE refactors.

## Active MATLAB path

`startup.m` adds the following active folders to the MATLAB path:

```text
app/
core/
equations/
approximations/
tracking/
models/
analysis/
examples/acoustoelastic_iop_hgo/
examples/mrlfe/
examples/validation/
tests/
```

Legacy folders such as `examples/basic`, `examples/diagnostics`, and `examples/sweeps` are no longer part of the default MATLAB path.

## Model folders

### Acoustoelastic IOP/HGO model

```text
models/acoustoelastic_iop_hgo/
├─ core/
├─ constitutive/
├─ solvers/
└─ options/
```

Use this model for IOP/HGO acoustoelastic dispersion studies.

Recommended high-level solver:

```matlab
solveDispersionIOPHGOAtlasBranch_Li2024
```

The current default branch policy is `strictA0`. See:

```text
docs/acoustoelastic_iop_hgo_branch_policy.md
```

### mRLFE model

```text
models/mrlfe/
├─ core/
├─ solvers/
└─ options/
```

Use this model for modified Rayleigh-Lamb fluid-loaded elastic and Han-style viscoelastic real-k calculations.

Recommended high-level function:

```matlab
computeMRLFE
```

## Example folders

### Acoustoelastic IOP/HGO examples

```text
examples/acoustoelastic_iop_hgo/
├─ basic/
├─ sweeps/
└─ diagnostics/
```

### mRLFE examples

```text
examples/mrlfe/
├─ basic/
├─ sweeps/
└─ diagnostics/
```

### Validation examples

```text
examples/validation/
```

This folder contains maintained validation and stress-test scripts.

### Archive

```text
examples/archive/
```

This folder contains historical prototypes and development diagnostics. It is intentionally not added to the MATLAB path by `startup.m`.

## Tests

Maintained smoke and consistency tests are stored in:

```text
tests/acoustoelastic_iop_hgo/
tests/mrlfe/
```

Recommended manual test sequence after refactors:

```matlab
clear functions
rehash toolboxcache
startup

test_li2024_constitutive_identity
test_li2024_strictA0_smoke
test_mrlfe_smoke
```

## Refactor policy

For future cleanup:

1. Move files first.
2. Confirm MATLAB resolves the new paths with `which`.
3. Run the smoke tests.
4. Only then remove legacy locations.
5. Prefer small commits over large mixed renames and deletions.
