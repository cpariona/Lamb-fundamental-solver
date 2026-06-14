# Acoustoelastic IOP/HGO post-rename architecture

For a concise final snapshot of maintained author-neutral names, legacy compatibility wrappers, intentional `Li2024` references, and deferred validation work, see [Acoustoelastic IOP/HGO final naming snapshot](acoustoelastic_final_naming_snapshot.md). For tag preparation, see the [Acoustoelastic IOP/HGO release-readiness checklist](acoustoelastic_release_readiness_checklist.md).

This document summarizes the maintained Acoustoelastic IOP/HGO naming structure after the author-neutral rename migration. It is an architecture and naming guide only; it does not define new numerical formulas, solver behavior, or validation requirements.

## Maintained author-neutral API layers

The current Acoustoelastic IOP/HGO API is organized as layered author-neutral names, with older `Li2024` names retained as compatibility wrappers:

- **Public/convenience layer**: user-facing entrypoints for routine branch solving, options construction, and examples.
- **IOP/HGO high-level atlas solver**: model-specific branch tracking for the Acoustoelastic IOP/HGO use case.
- **Generic atlas-branch solver**: Acoustoelastic atlas-branch machinery that is not tied to the public IOP/HGO convenience name.
- **Direct IOP/HGO dispersion solver**: model-specific dispersion implementation that prepares IOP/HGO constitutive inputs for the dispersion stack.
- **Mid-level dispersion solvers**: real-valued and complex-c Acoustoelastic dispersion solvers used below the high-level branch APIs.
- **Constitutive helpers**: IOP/HGO and acoustoelastic constitutive calculations used to prepare material coefficients and prestress quantities.
- **Core numerical helpers**: matrix assembly, residual/objective, determinant, and S-root helpers used by the dispersion solvers.

## Recommended user entrypoints

New user code should prefer the maintained author-neutral entrypoints:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticIOPHGODispersion
run_acoustoelastic_iop_hgo_atlas_branch
defaultAcoustoelasticIOPHGOOptions
```

`solveAcoustoelasticIOPHGOBranch` is the recommended public convenience entrypoint for routine branch solving. `defaultAcoustoelasticIOPHGOOptions` is the recommended options constructor. `run_acoustoelastic_iop_hgo_atlas_branch` is the maintained example script name for the atlas-branch workflow.

## Solver implementation layers

The maintained solver names form a top-down stack:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
```

At a high level, `solveAcoustoelasticIOPHGOBranch` is the public convenience wrapper around the IOP/HGO branch workflow. `solveAcoustoelasticIOPHGOAtlasBranch` is the high-level IOP/HGO atlas-branch solver used for that workflow. `solveAcoustoelasticAtlasBranch` provides the generic Acoustoelastic atlas-branch layer beneath the model-specific high-level entrypoint.

`solveAcoustoelasticIOPHGODispersion` is the direct IOP/HGO dispersion solver implementation. It connects the IOP/HGO constitutive layer to the mid-level Acoustoelastic dispersion solvers. `solveAcoustoelasticDispersion` and `solveAcoustoelasticComplexCDispersion` are the mid-level real-valued and complex-c Acoustoelastic dispersion solver names used by the solver stack.

## Constitutive helper layer

The maintained author-neutral constitutive helper names are:

```matlab
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
solveAcoustoelasticHGOStretch
```

These helpers prepare the Acoustoelastic IOP/HGO constitutive quantities consumed by the dispersion and branch solver layers.

## Core numerical helper layer

The maintained author-neutral core numerical helper names are:

```matlab
buildAcoustoelasticMatrix
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
computeAcoustoelasticSRoots
```

These helpers provide the matrix assembly, real residual objective, complex determinant objective, and S-root calculations used by the Acoustoelastic dispersion implementation.

## Legacy compatibility wrappers

Old `Li2024` function names remain callable and are intentionally preserved for backward compatibility. New code should prefer the author-neutral names unless it is explicitly testing compatibility or documenting legacy behavior.

Examples of preserved compatibility wrappers include:

```matlab
defaultLi2024AcoustoelasticOptions
solveDispersionIOPHGO_Li2024
solveDispersionIOPHGOAtlasBranch_Li2024
solveDispersionAtlasBranch_Li2024_Acoustoelastic
solveDispersion_Li2024_Acoustoelastic
solveDispersionComplexC_Li2024_Acoustoelastic
computeABGFromIOPHGO_Li2024
computeAlphaBetaGamma_Li2024
computePrestressSigma_Li2024
solveStretchHGO_Li2024
computeSRoots_Li2024
objective_Li2024_Acoustoelastic
objectiveComplexDet_Li2024_Acoustoelastic
buildMatrix_Li2024_Acoustoelastic
```

## What remains intentionally unchanged

The rename migration was intended to change names and API organization, not numerical behavior. Numerical algorithms were not intentionally changed during the rename migration.

The following were preserved during the rename work:

- matrix assembly;
- objective definitions;
- S-root helper behavior;
- constitutive relations;
- tolerances;
- branch policies;
- residual definitions;
- output structures.

Archive and prototype references remain historical. Literature and provenance references may still use `Li2024` when the label describes source lineage rather than the preferred maintained API name.

## Future cleanup candidates

Possible future cleanup items include:

- explicit wrapper numerical equivalence tests;
- a formal deprecation policy for legacy wrappers;
- an archive/prototype migration policy;
- possible Rayleigh-Lamb base package reorganization;
- public v1 API documentation.
