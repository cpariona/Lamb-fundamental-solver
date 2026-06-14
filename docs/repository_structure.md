# Repository structure

This document describes the active folder structure after the acoustoelastic IOP/HGO compatibility-layer cleanup and the mRLFE refactor.

## Active MATLAB path

`startup.m` adds active implementation, analysis, example, and test folders to the MATLAB path. Maintained acoustoelastic callers should use author-neutral `Acoustoelastic` / `AcoustoelasticIOPHGO` names only.

## Model folders

### Acoustoelastic IOP/HGO model

```text
models/acoustoelastic_iop_hgo/
├─ core/
├─ constitutive/
├─ solvers/
└─ options/
```

Recommended author-neutral entrypoints:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticIOPHGODispersion
defaultAcoustoelasticIOPHGOOptions
```

The old author-specific compatibility wrappers have been removed and are not maintained entrypoints. GUI code should call the author-neutral API only.

### mRLFE model

```text
models/mrlfe/
├─ core/
├─ solvers/
└─ options/
```

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

Maintained examples and diagnostics use `acoustoelastic_iop_hgo` names only.

```matlab
run_acoustoelastic_iop_hgo_atlas_branch
diagnose_acoustoelastic_iop_hgo_branch_policy
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

## Tests

Maintained smoke and consistency tests are stored in:

```text
tests/acoustoelastic_iop_hgo/
tests/mrlfe/
```

Recommended acoustoelastic tests:

```matlab
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
```

Recommended manual test sequence after refactors:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```
