# Maintained entrypoints

For a documentation-only audit and future migration plan for the base Rayleigh-Lamb solver, see [Rayleigh-Lamb base solver reorganization plan](rayleigh_lamb_base_reorganization_plan.md).

For a concise layer-by-layer summary of the post-migration Acoustoelastic IOP/HGO API structure, see [Acoustoelastic IOP/HGO post-rename architecture](acoustoelastic_post_rename_architecture.md). For the final naming snapshot of maintained names, compatibility wrappers, and intentional legacy references, see [Acoustoelastic IOP/HGO final naming snapshot](acoustoelastic_final_naming_snapshot.md).

This document lists the maintained solver, example, diagnostic, and test entrypoints after the Acoustoelastic IOP/HGO and mRLFE refactors.

## Setup

From the repository root, always run:

```matlab
clear functions
rehash toolboxcache
startup
```

## Acoustoelastic IOP/HGO model

Recommended author-neutral entrypoints for routine use:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
buildAcoustoelasticMatrix
defaultAcoustoelasticIOPHGOOptions
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
computeAcoustoelasticSRoots
solveAcoustoelasticHGOStretch
run_acoustoelastic_iop_hgo_atlas_branch
diagnose_acoustoelastic_iop_hgo_branch_policy
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
```

`objectiveAcoustoelasticResidual` is now the author-neutral real-valued Acoustoelastic residual objective helper. `objective_Li2024_Acoustoelastic` remains available as a compatibility wrapper. `objectiveAcoustoelasticComplexDeterminant` is now the author-neutral complex determinant objective helper. `objectiveComplexDet_Li2024_Acoustoelastic` remains available as a compatibility wrapper. No objective, residual, or determinant logic was intentionally changed during this rename.

`buildAcoustoelasticMatrix` is now the author-neutral Acoustoelastic matrix-builder helper. `buildMatrix_Li2024_Acoustoelastic` remains available as a compatibility wrapper. No matrix assembly logic, matrix entries, determinant logic, or physical equations were intentionally changed during this rename.

Author-neutral Acoustoelastic IOP/HGO constitutive helper names now exist: `computeAcoustoelasticABGFromIOPHGO`, `computeAcoustoelasticAlphaBetaGamma`, `computeAcoustoelasticPrestressSigma`, and `solveAcoustoelasticHGOStretch`. The older `Li2024` constitutive helper names remain available as compatibility wrappers, and no constitutive logic was intentionally changed during this rename.

`computeAcoustoelasticSRoots` is now the author-neutral Acoustoelastic S-roots helper. `computeSRoots_Li2024` remains available as a compatibility wrapper, and no root logic was intentionally changed during this rename.

Author-neutral Acoustoelastic IOP/HGO example, diagnostic, and sweep entrypoints now exist for the maintained `examples/acoustoelastic_iop_hgo/` tree. The older `Li2024`-named example, diagnostic, and sweep scripts remain available as compatibility wrappers during the naming transition.


`solveAcoustoelasticIOPHGOBranch` remains the recommended public convenience entrypoint. `solveAcoustoelasticIOPHGOAtlasBranch` remains the author-neutral high-level IOP/HGO atlas-branch solver used by that convenience entrypoint. `solveAcoustoelasticAtlasBranch` is now the author-neutral generic Acoustoelastic atlas-branch solver. `solveAcoustoelasticIOPHGODispersion` is now the author-neutral direct IOP/HGO dispersion solver implementation. `solveAcoustoelasticDispersion` is now the author-neutral mid-level Acoustoelastic dispersion solver. `solveAcoustoelasticComplexCDispersion` is now the author-neutral complex-c Acoustoelastic dispersion solver. `defaultAcoustoelasticIOPHGOOptions` is now the author-neutral options implementation. `solveDispersionIOPHGO_Li2024`, `solveDispersionIOPHGOAtlasBranch_Li2024`, `solveDispersionAtlasBranch_Li2024_Acoustoelastic`, `solveDispersion_Li2024_Acoustoelastic`, `solveDispersionComplexC_Li2024_Acoustoelastic`, and `defaultLi2024AcoustoelasticOptions` remain compatibility wrappers.

The author-neutral Acoustoelastic IOP/HGO tracking-quality analysis helper is now available as `summarizeAcoustoelasticIOPHGOTrackingQuality`; the older `summarizeLi2024TrackingQuality` helper remains available as a compatibility wrapper.

```matlab
run_acoustoelastic_iop_hgo_A0_backward
run_acoustoelastic_iop_hgo_A0_complexC
run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma
compare_acoustoelastic_iop_hgo_tracking_strategies
diagnose_acoustoelastic_iop_hgo_grid_convergence
diagnose_acoustoelastic_iop_hgo_dimensionless_A1
diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas
diagnose_acoustoelastic_iop_hgo_matrix_variants
diagnose_acoustoelastic_iop_hgo_modal_atlas
diagnose_acoustoelastic_iop_hgo_residual_landscape
track_acoustoelastic_iop_hgo_raw_branch1_candidate
sweep_acoustoelastic_iop_hgo_A0_backward
```

Compatibility/development entrypoints still available during the naming transition:

```matlab
solveDispersionIOPHGO_Li2024
solveDispersionIOPHGOAtlasBranch_Li2024
defaultLi2024AcoustoelasticOptions
computeABGFromIOPHGO_Li2024
computeAlphaBetaGamma_Li2024
computePrestressSigma_Li2024
solveStretchHGO_Li2024
objective_Li2024_Acoustoelastic
objectiveComplexDet_Li2024_Acoustoelastic
buildMatrix_Li2024_Acoustoelastic
run_li2024_IOP_HGO_A0_atlas_branch
diagnose_li2024_atlas_branch_policy
test_li2024_constitutive_identity
test_li2024_strictA0_smoke
```

Main model folders:

```text
models/acoustoelastic_iop_hgo/core/
models/acoustoelastic_iop_hgo/constitutive/
models/acoustoelastic_iop_hgo/solvers/
models/acoustoelastic_iop_hgo/options/
```

Maintained examples:

```text
examples/acoustoelastic_iop_hgo/basic/
examples/acoustoelastic_iop_hgo/sweeps/
examples/acoustoelastic_iop_hgo/diagnostics/
```

Maintained tests:

```text
tests/acoustoelastic_iop_hgo/
```


## Li2024 legacy reference audit

Author-neutral names in the recommended lists above are the maintained names for new code. The `Li2024`-named functions and scripts listed under compatibility/development entrypoints remain callable only as backward-compatibility wrappers during the naming transition. New code should avoid calling `Li2024` names unless it is explicitly testing backward compatibility or comparing legacy behavior.

Remaining `Li2024` references are intentional in these categories:

- Compatibility wrappers and compatibility tests that preserve old callable names.
- Archive, prototype, example, diagnostic, and sweep files whose names, generated output labels, or historical scripts still document earlier development phases; these should not be renamed in this documentation-only audit.
- Paper, literature, and provenance notes where `Li2024` describes lineage rather than a preferred API name.

Do not treat those preserved references as primary entrypoints. Prefer the author-neutral Acoustoelastic IOP/HGO APIs for routine use.

## mRLFE model

Main high-level function:

```matlab
computeMRLFE
```

Main model folders:

```text
models/mrlfe/core/
models/mrlfe/solvers/
models/mrlfe/options/
```

Maintained examples:

```text
examples/mrlfe/basic/
examples/mrlfe/sweeps/
examples/mrlfe/diagnostics/
```

Useful examples:

```matlab
run_mrlfe_prototype
compare_mrlfe_elastic_vs_han_visco_cp
sweep_mrlfe_shear_viscosity_phase_velocity
```

Useful diagnostics:

```matlab
diagnose_mrlfe_han_visco_validity_breakdown
diagnose_mrlfe_han_visco_residual_landscape
compare_mrlfe_tracker_vs_condition_peaks
```

Maintained test:

```matlab
test_mrlfe_smoke
```

## Smoke-test compatibility scope

`run_all_smoke_tests` also includes Rayleigh-Lamb base solver path smoke checks for the current functions under `core/`, `equations/`, `approximations/`, and `tracking/`. These checks use `which` only; they do not call the functions numerically or solve dispersion curves.

`run_all_smoke_tests` now verifies that both the maintained author-neutral Acoustoelastic IOP/HGO names and the preserved `Li2024` legacy wrapper names are resolvable on the MATLAB path. The legacy-wrapper portion is a path-level compatibility check only: it uses `which` and intentionally does not execute the wrappers, compare numerical outputs, solve dispersion curves, or run heavy diagnostics. Numerical equivalence testing between legacy wrappers and author-neutral implementations is intentionally deferred to a separate future validation phase.

## Full manual test sequence

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```

## Path check sequence

```matlab
which solveAcoustoelasticIOPHGOBranch
which solveAcoustoelasticIOPHGOAtlasBranch
which solveAcoustoelasticIOPHGODispersion
which solveAcoustoelasticDispersion
which solveAcoustoelasticComplexCDispersion
which defaultAcoustoelasticIOPHGOOptions
which buildAcoustoelasticMatrix
which computeAcoustoelasticABGFromIOPHGO
which computeAcoustoelasticAlphaBetaGamma
which computeAcoustoelasticPrestressSigma
which computeAcoustoelasticSRoots
which solveAcoustoelasticHGOStretch
which run_acoustoelastic_iop_hgo_atlas_branch
which diagnose_acoustoelastic_iop_hgo_branch_policy
which test_acoustoelastic_iop_hgo_constitutive_identity
which test_acoustoelastic_iop_hgo_strictA0_smoke
which computeMRLFE
which defaultMRLFEParams
which summarizeAcoustoelasticIOPHGOTrackingQuality
which diagnose_mrlfe_han_visco_residual_landscape
```

Expected folders:

```text
models/acoustoelastic_iop_hgo/solvers/
models/acoustoelastic_iop_hgo/options/
examples/acoustoelastic_iop_hgo/basic/
examples/acoustoelastic_iop_hgo/diagnostics/
tests/acoustoelastic_iop_hgo/
models/mrlfe/solvers/
models/mrlfe/options/
examples/mrlfe/diagnostics/
```

## Naming transition

The current naming transition is documented in:

```text
docs/naming_transition.md
```
