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
aeNormalizeBranchPolicy
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

## Sweep and analysis helpers

```matlab
aeRunSweep
aeSummarizeSweep
summarizeAcoustoelasticIOPHGOTrackingQuality
```

## Maintained tests

```matlab
test_acoustoelastic_iop_hgo_branch_policy_aliases
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
```

## Policy for callers

- GUI code should call author-neutral functions only.
- Maintained examples should use `acoustoelastic_iop_hgo` names only.
- Active tests should validate author-neutral names only.
- The maintained atlas A0 policy name is `"atlasA0"`.
- The legacy policy name `"strictA0"` remains accepted as an alias.
- Removed compatibility names are not part of the supported API.
