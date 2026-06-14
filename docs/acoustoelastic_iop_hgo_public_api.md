# Acoustoelastic IOP/HGO public API

The supported acoustoelastic IOP/HGO API is author-neutral. Maintained code, examples, tests, GUI callbacks, and analysis scripts should call the `Acoustoelastic` / `AcoustoelasticIOPHGO` entrypoints listed below.

The former author-specific compatibility layer has been removed. Do not add new compatibility wrappers or call removed author-specific names from active MATLAB code.

## Primary entrypoints

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
```

## Options

```matlab
defaultAcoustoelasticIOPHGOOptions
```

## Constitutive helpers

```matlab
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
solveAcoustoelasticHGOStretch
```

## Matrix, roots, and objectives

```matlab
buildAcoustoelasticMatrix
computeAcoustoelasticSRoots
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
```

## Analysis helper

```matlab
summarizeAcoustoelasticIOPHGOTrackingQuality
```

## Maintained tests

```matlab
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
```

## Policy for callers

- GUI code should call author-neutral functions only.
- Maintained examples should use `acoustoelastic_iop_hgo` names only.
- Active tests should validate author-neutral names only.
- Removed compatibility names are not part of the supported API.
