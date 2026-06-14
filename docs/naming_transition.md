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

### Acoustoelastic objective helpers

Author-neutral objective helper implementations now exist:

```matlab
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
```

`objectiveAcoustoelasticResidual` is the author-neutral real-valued Acoustoelastic residual objective helper. `objectiveAcoustoelasticComplexDeterminant` is the author-neutral complex determinant objective helper.

Compatibility functions still available as wrappers:

```matlab
objective_Li2024_Acoustoelastic
objectiveComplexDet_Li2024_Acoustoelastic
```

No objective, residual, or determinant logic was intentionally changed during this rename; the compatibility wrappers forward to the author-neutral implementations.

### Acoustoelastic matrix builder

Author-neutral Acoustoelastic matrix-builder helper:

```matlab
buildAcoustoelasticMatrix
```

Compatibility function still available as a wrapper:

```matlab
buildMatrix_Li2024_Acoustoelastic
```

No matrix assembly logic, matrix entries, determinant logic, or physical equations were intentionally changed during this rename; the compatibility wrapper forwards to the author-neutral implementation.

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

### Acoustoelastic S-roots helper

Author-neutral Acoustoelastic S-roots helper implementation:

```matlab
computeAcoustoelasticSRoots
```

Compatibility function still available as a wrapper:

```matlab
computeSRoots_Li2024
```

No root logic was intentionally changed during this rename; the compatibility wrapper forwards to the author-neutral implementation.

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


## Legacy reference audit policy

Author-neutral Acoustoelastic IOP/HGO names are the maintained API names for new code. The `Li2024`-named functions remain available as compatibility wrappers and should stay callable until the project adopts a documented deprecation policy. New code should not call `Li2024` names except when explicitly testing backward compatibility or documenting legacy behavior.

Remaining `Li2024` references are preserved intentionally when they fall into one of these categories:

- Compatibility wrappers, compatibility scripts, and compatibility tests whose purpose is to keep old user-facing names callable.
- Archive, prototype, example, diagnostic, and sweep files that preserve historical development context, output names, or comparison workflows; these are historical and should not be renamed in this phase.
- Paper, literature, and provenance notes where the author label identifies model lineage or source material rather than the maintained API.

When documentation lists both names, list the author-neutral name first and mark the `Li2024` name as compatibility-only.

## Smoke-test coverage

`run_all_smoke_tests` now includes a path-level compatibility section for the preserved `Li2024` wrapper names in addition to the maintained author-neutral Acoustoelastic IOP/HGO path checks. These checks only verify that names are resolvable with `which`; they do not execute numerical wrappers, solve dispersion curves, or validate numerical equivalence. Numerical equivalence testing is intentionally deferred to a separate future validation phase.

## Current policy

For now, do not delete the original Li2024-named MATLAB functions. `defaultLi2024AcoustoelasticOptions`, `solveDispersionIOPHGO_Li2024`, `solveDispersionIOPHGOAtlasBranch_Li2024`, `solveDispersion_Li2024_Acoustoelastic`, `solveDispersionComplexC_Li2024_Acoustoelastic`, `computeABGFromIOPHGO_Li2024`, `computeAlphaBetaGamma_Li2024`, `computePrestressSigma_Li2024`, `solveStretchHGO_Li2024`, `computeSRoots_Li2024`, and `buildMatrix_Li2024_Acoustoelastic` remain compatibility wrappers while the public API moves to author-neutral names.

Future cleanup can rename internal functions in a dedicated pull request, but MATLAB file names and function names must be changed consistently.

## Recommended validation

After naming-related changes, run:

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```
