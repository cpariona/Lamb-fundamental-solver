# Acoustoelastic IOP/HGO final naming snapshot

## Purpose

This document records the post-migration naming state of the Acoustoelastic IOP/HGO model after the author-neutral naming migration. It is a documentation snapshot only: it does not introduce numerical changes, new APIs, source moves, or validation requirements.

Use this snapshot as the concise reference for which Acoustoelastic IOP/HGO names are maintained for new code, which legacy `Li2024` names remain callable as compatibility wrappers, and which remaining `Li2024` references are intentional.

## Maintained author-neutral names

### Public/options

```text
defaultAcoustoelasticIOPHGOOptions
solveAcoustoelasticIOPHGOBranch
run_acoustoelastic_iop_hgo_atlas_branch
diagnose_acoustoelastic_iop_hgo_branch_policy
summarizeAcoustoelasticIOPHGOTrackingQuality
```

### High-level and solver layer

```text
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticAtlasBranch
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
```

### Constitutive layer

```text
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
solveAcoustoelasticHGOStretch
```

### Core numerical layer

```text
buildAcoustoelasticMatrix
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
computeAcoustoelasticSRoots
```

## Legacy compatibility wrapper names

### Options/solver wrappers

```text
defaultLi2024AcoustoelasticOptions
solveDispersionIOPHGO_Li2024
solveDispersionIOPHGOAtlasBranch_Li2024
solveDispersionAtlasBranch_Li2024_Acoustoelastic
solveDispersion_Li2024_Acoustoelastic
solveDispersionComplexC_Li2024_Acoustoelastic
```

### Constitutive wrappers

```text
computeABGFromIOPHGO_Li2024
computeAlphaBetaGamma_Li2024
computePrestressSigma_Li2024
solveStretchHGO_Li2024
```

### Core wrappers

```text
buildMatrix_Li2024_Acoustoelastic
objective_Li2024_Acoustoelastic
objectiveComplexDet_Li2024_Acoustoelastic
computeSRoots_Li2024
```

## Remaining intentional Li2024 references

Remaining `Li2024` references are allowed when they are:

- compatibility wrapper names;
- backward-compatibility smoke checks;
- archive/prototype/historical files;
- paper/literature/provenance references.

These preserved references should not be treated as the preferred maintained API for new work. They document compatibility, historical lineage, or provenance rather than the primary naming policy.

## Path smoke-test coverage

`run_all_smoke_tests` verifies that both maintained author-neutral names and preserved legacy wrapper names are resolvable on the MATLAB path.

These smoke checks are path-level checks only. They confirm that the expected names can be found with MATLAB path lookup, but they are not numerical-equivalence tests, wrapper execution tests, dispersion-curve validation, or heavy diagnostic runs.

## Deferred validation work

- explicit numerical equivalence tests for compatibility wrappers;
- dedicated wrapper deprecation policy;
- archive/prototype migration policy;
- Rayleigh-Lamb base package reorganization;
- public v1 API documentation;
- optional release tag after stable smoke-test pass.

## Recommended policy for new code

- New scripts should use author-neutral names.
- Legacy wrappers should remain callable.
- Legacy names should only be used when checking backward compatibility or reproducing historical workflows.
- Avoid introducing new public APIs with author names unless they represent citation/provenance only.
