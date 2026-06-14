# Naming transition guide

This document records the current naming transition for the acoustoelastic IOP/HGO implementation.

## Goal

Use model-based names for public entrypoints instead of author-based names, while preserving backward compatibility during the transition.

The mRLFE name is preserved because it identifies the model family used in this repository.

## Recommended names for routine use

### Acoustoelastic IOP/HGO solver

Recommended public convenience entrypoint:

```matlab
solveAcoustoelasticIOPHGOBranch
```

Author-neutral high-level IOP/HGO atlas-branch solver used by the convenience entrypoint:

```matlab
solveAcoustoelasticIOPHGOAtlasBranch
```

Author-neutral generic Acoustoelastic atlas-branch solver:

```matlab
solveAcoustoelasticAtlasBranch
```

Author-neutral direct IOP/HGO dispersion solver implementation:

```matlab
solveAcoustoelasticIOPHGODispersion
```

Author-neutral mid-level Acoustoelastic dispersion solvers:

```matlab
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
```

Compatibility functions still available as wrappers:

```matlab
solveDispersionIOPHGO_Li2024
solveDispersionIOPHGOAtlasBranch_Li2024
solveDispersionAtlasBranch_Li2024_Acoustoelastic
solveDispersion_Li2024_Acoustoelastic
solveDispersionComplexC_Li2024_Acoustoelastic
```

### Acoustoelastic IOP/HGO options

Author-neutral options implementation:

```matlab
defaultAcoustoelasticIOPHGOOptions
```

Compatibility function still available as a wrapper:

```matlab
defaultLi2024AcoustoelasticOptions
```

### Acoustoelastic IOP/HGO constitutive helpers

Author-neutral constitutive helper implementations now exist:

```matlab
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
solveAcoustoelasticHGOStretch
```

Compatibility functions still available as wrappers:

```matlab
computeABGFromIOPHGO_Li2024
computeAlphaBetaGamma_Li2024
computePrestressSigma_Li2024
solveStretchHGO_Li2024
```

No constitutive logic was intentionally changed during this rename; the compatibility wrappers forward to the author-neutral implementations.

### Acoustoelastic IOP/HGO example

```matlab
run_acoustoelastic_iop_hgo_atlas_branch
```

Compatibility script still available:

```matlab
run_li2024_IOP_HGO_A0_atlas_branch
```

### Acoustoelastic IOP/HGO diagnostic

```matlab
diagnose_acoustoelastic_iop_hgo_branch_policy
```

Compatibility script still available:

```matlab
diagnose_li2024_atlas_branch_policy
```

### Acoustoelastic IOP/HGO tests

```matlab
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
```

Compatibility tests still available:

```matlab
test_li2024_constitutive_identity
test_li2024_strictA0_smoke
```

## Folder names

Recommended active folders:

```text
models/acoustoelastic_iop_hgo/
examples/acoustoelastic_iop_hgo/
tests/acoustoelastic_iop_hgo/
```

The old folder names are no longer part of the maintained structure:

```text
models/li2024_acoustoelastic/
examples/li2024/
tests/li2024/
```

## Current policy

For now, do not delete the original Li2024-named MATLAB functions. `defaultLi2024AcoustoelasticOptions`, `solveDispersionIOPHGO_Li2024`, `solveDispersionIOPHGOAtlasBranch_Li2024`, `solveDispersion_Li2024_Acoustoelastic`, `solveDispersionComplexC_Li2024_Acoustoelastic`, `computeABGFromIOPHGO_Li2024`, `computeAlphaBetaGamma_Li2024`, `computePrestressSigma_Li2024`, and `solveStretchHGO_Li2024` remain compatibility wrappers while the public API moves to author-neutral names.

Future cleanup can rename internal functions in a dedicated pull request, but MATLAB file names and function names must be changed consistently.

## Recommended validation

After naming-related changes, run:

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```
