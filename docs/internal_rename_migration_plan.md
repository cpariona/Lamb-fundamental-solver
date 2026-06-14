# Internal rename migration plan

For the concise current-state summary after the Acoustoelastic IOP/HGO author-neutral rename migration, see [Acoustoelastic IOP/HGO post-rename architecture](acoustoelastic_post_rename_architecture.md).

This is a conservative implementation plan only. It does not perform the migration. Each implementation phase must preserve a passing MATLAB validation sequence:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```

## Guardrails

- Keep `mRLFE` as a model name.
- Preserve author-neutral public Acoustoelastic IOP/HGO entrypoints:
  - `solveAcoustoelasticIOPHGOBranch`
  - `defaultAcoustoelasticIOPHGOOptions`
  - `run_acoustoelastic_iop_hgo_atlas_branch`
  - `diagnose_acoustoelastic_iop_hgo_branch_policy`
  - `test_acoustoelastic_iop_hgo_constitutive_identity`
  - `test_acoustoelastic_iop_hgo_strictA0_smoke`
- Preserve backward-compatible wrappers for existing `Li2024`-named public functions for at least one release.
- Do not delete archive/prototype files.
- MATLAB primary function names must match their file names, so every implementation rename needs a same-named function in the new file and, when required, a same-named wrapper in the old file.
- Avoid one large mixed PR; separate docs, tests, acoustoelastic internals, examples/diagnostics, and Rayleigh-Lamb folder moves.

## 1. Files that can be safely renamed soon

These are low-to-medium risk because author-neutral replacements already exist or because they are examples/diagnostics rather than core solver math. Still, each rename should preserve a compatibility wrapper when the old name may be called by users or tests.

### Acoustoelastic examples and diagnostics

- `examples/acoustoelastic_iop_hgo/basic/run_li2024_IOP_HGO_A0_atlas_branch.m` -> keep old wrapper, prefer `run_acoustoelastic_iop_hgo_atlas_branch`.
- `examples/acoustoelastic_iop_hgo/basic/run_li2024_IOP_HGO_A0_backward.m` -> proposed `run_acoustoelastic_iop_hgo_A0_backward.m`.
- `examples/acoustoelastic_iop_hgo/basic/run_li2024_IOP_HGO_A0_complexC.m` -> proposed `run_acoustoelastic_iop_hgo_A0_complexC.m`.
- `examples/acoustoelastic_iop_hgo/basic/run_li2024_direct_alpha_beta_gamma.m` -> proposed `run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma.m`.
- `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_atlas_branch_policy.m` -> keep old wrapper, prefer `diagnose_acoustoelastic_iop_hgo_branch_policy`.
- `examples/acoustoelastic_iop_hgo/diagnostics/compare_li2024_tracking_strategies_IOP_HGO.m` -> proposed `compare_acoustoelastic_iop_hgo_tracking_strategies.m`.
- `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_IOP_grid_convergence.m` -> proposed `diagnose_acoustoelastic_iop_hgo_grid_convergence.m`.
- `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_dimensionless_A1.m` -> proposed `diagnose_acoustoelastic_iop_hgo_dimensionless_A1.m`.
- `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_low_frequency_modal_atlas.m` -> proposed `diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m`.
- `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_matrix_variants.m` -> proposed `diagnose_acoustoelastic_iop_hgo_matrix_variants.m`.
- `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_modal_atlas.m` -> proposed `diagnose_acoustoelastic_iop_hgo_modal_atlas.m`.
- `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_li2024_residual_landscape.m` -> proposed `diagnose_acoustoelastic_iop_hgo_residual_landscape.m`.
- `examples/acoustoelastic_iop_hgo/diagnostics/track_li2024_raw_branch1_candidate.m` -> proposed `track_acoustoelastic_iop_hgo_raw_branch1_candidate.m`.
- `examples/acoustoelastic_iop_hgo/sweeps/sweep_li2024_IOP_HGO_A0_backward.m` -> proposed `sweep_acoustoelastic_iop_hgo_A0_backward.m`.


Implementation note: author-neutral Acoustoelastic IOP/HGO example, diagnostic, and sweep entrypoints now exist for the `Li2024`-named scripts listed in this section, and the old `Li2024`-named scripts remain as compatibility wrappers.

### Analysis helper

- `analysis/summarizeLi2024TrackingQuality.m` -> `analysis/acoustoelastic_iop_hgo/summarizeAcoustoelasticIOPHGOTrackingQuality.m`, with `summarizeLi2024TrackingQuality.m` kept as a compatibility wrapper while callers migrate. The author-neutral Acoustoelastic IOP/HGO analysis helper now exists.

## 2. Files that should remain as compatibility wrappers

For at least one release, keep these names callable:

- `models/acoustoelastic_iop_hgo/options/defaultAcoustoelasticIOPHGOOptions.m` is now the author-neutral options implementation.
- `models/acoustoelastic_iop_hgo/options/defaultLi2024AcoustoelasticOptions.m` remains a wrapper to `defaultAcoustoelasticIOPHGOOptions`.
- `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticIOPHGOAtlasBranch.m` remains the author-neutral high-level IOP/HGO atlas-branch solver.
- `models/acoustoelastic_iop_hgo/solvers/solveDispersionIOPHGOAtlasBranch_Li2024.m` remains a wrapper to `solveAcoustoelasticIOPHGOAtlasBranch`.
- `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticIOPHGODispersion.m` is now the author-neutral direct IOP/HGO dispersion solver implementation.
- `models/acoustoelastic_iop_hgo/solvers/solveDispersionIOPHGO_Li2024.m` remains a wrapper to `solveAcoustoelasticIOPHGODispersion`.
- `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticAtlasBranch.m` is now the author-neutral generic Acoustoelastic atlas-branch solver.
- `models/acoustoelastic_iop_hgo/solvers/solveDispersionAtlasBranch_Li2024_Acoustoelastic.m` remains a compatibility wrapper to `solveAcoustoelasticAtlasBranch`.
- `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticComplexCDispersion.m` is now the author-neutral complex-c Acoustoelastic dispersion solver. `models/acoustoelastic_iop_hgo/solvers/solveDispersionComplexC_Li2024_Acoustoelastic.m` remains a compatibility wrapper.
- `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticDispersion.m` is now the author-neutral mid-level Acoustoelastic dispersion solver. `models/acoustoelastic_iop_hgo/solvers/solveDispersion_Li2024_Acoustoelastic.m` remains a compatibility wrapper.
- `models/acoustoelastic_iop_hgo/core/computeAcoustoelasticSRoots.m` is now the author-neutral Acoustoelastic S-roots helper; `models/acoustoelastic_iop_hgo/core/computeSRoots_Li2024.m` remains a compatibility wrapper. No root logic was intentionally changed during this rename.
- Remaining `models/acoustoelastic_iop_hgo/core/*_Li2024*.m` and `models/acoustoelastic_iop_hgo/constitutive/*_Li2024*.m` -> wrappers only after equivalent author-neutral internals are introduced and tests cover the call graph.
- Legacy examples, diagnostics, sweeps, and tests listed in section 1 when they may be documented or user-facing.

## 3. Files that should move to archive

Do not delete these. They are already in the right archive location and should remain out of the routine MATLAB path unless a later documentation-only PR says otherwise:

- `examples/archive/diagnose_mrlfe_a0_candidates.m`
- `examples/archive/diagnose_mrlfe_a0_visco_residual.m`
- `examples/archive/diagnose_mrlfe_elastic_soft_range_candidates.m`
- `examples/archive/diagnose_mrlfe_etaS1_local_candidates.m`
- `examples/archive/diagnose_mrlfe_etaS1_transition.m`
- `examples/archive/diagnose_mrlfe_s0_visco_residual.m`
- `examples/archive/prototype_mrlfe_a0_multicandidate_tracker.m`
- `examples/archive/prototype_mrlfe_han_visco_a0_multicandidate_tracker.m`
- `examples/archive/run_mrlfe_complexk_prototype.m`
- `examples/archive/stress_test_mrlfe_parameter_space.m`
- `examples/archive/sweep_mrlfe_viscosity.m`

No additional maintained files should move to archive until a separate PR demonstrates that they are unused or superseded.

## 4. Rayleigh-Lamb physics structure recommendation

The current `core/`, `equations/`, `approximations/`, and `tracking/` folders contain the base Rayleigh-Lamb solver. A clearer future structure would be:

```text
models/rayleigh_lamb/core/
models/rayleigh_lamb/equations/
models/rayleigh_lamb/approximations/
models/rayleigh_lamb/options/
models/rayleigh_lamb/solvers/
models/rayleigh_lamb/tracking/
```

Recommended mapping:

- `core/buildFrequencyVector.m` -> `models/rayleigh_lamb/core/buildFrequencyVector.m`
- `core/computeGeometry.m` -> `models/rayleigh_lamb/core/computeGeometry.m`
- `core/computeMaterial.m` -> `models/rayleigh_lamb/core/computeMaterial.m`
- `core/makeBranchSpec.m` -> `models/rayleigh_lamb/core/makeBranchSpec.m`
- `core/defaultOptions.m` -> `models/rayleigh_lamb/options/defaultOptions.m`
- `core/defaultParams.m` -> `models/rayleigh_lamb/options/defaultParams.m`
- `core/validateOptions.m` -> `models/rayleigh_lamb/options/validateOptions.m`
- `core/validateParams.m` -> `models/rayleigh_lamb/options/validateParams.m`
- `core/computeFundamentalLambModes.m` -> `models/rayleigh_lamb/solvers/computeFundamentalLambModes.m`
- `equations/rayleighLambAResidual.m` -> `models/rayleigh_lamb/equations/rayleighLambAResidual.m`
- `equations/rayleighLambSResidual.m` -> `models/rayleigh_lamb/equations/rayleighLambSResidual.m`
- `approximations/computeA0ThinPlateApproximation.m` -> `models/rayleigh_lamb/approximations/computeA0ThinPlateApproximation.m`
- `approximations/computeAnalyticalApproximations.m` -> `models/rayleigh_lamb/approximations/computeAnalyticalApproximations.m`
- `approximations/computeS0ExtensionalApproximation.m` -> `models/rayleigh_lamb/approximations/computeS0ExtensionalApproximation.m`
- `tracking/solveFundamentalBranch.m` -> `models/rayleigh_lamb/tracking/solveFundamentalBranch.m`

Because these functions are broadly used and `startup.m` path behavior is central, this move should happen only after acoustoelastic internal naming is stabilized and after wrapper/path tests exist.

## 5. Files that should remain where they are

- All GUI files in `app/` and `runApp.m`.
- `startup.m` until a dedicated path-layout PR.
- All `models/mrlfe/**` files; `mRLFE` is the model name and should not be renamed.
- Author-neutral acoustoelastic public entrypoints:
  - `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticIOPHGOBranch.m` (recommended public convenience entrypoint)
  - `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticIOPHGOAtlasBranch.m` (author-neutral high-level IOP/HGO atlas-branch solver)
  - `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticAtlasBranch.m` (author-neutral generic Acoustoelastic atlas-branch solver)
  - `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticIOPHGODispersion.m` (author-neutral direct IOP/HGO dispersion solver implementation)
  - `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticDispersion.m` (author-neutral mid-level Acoustoelastic dispersion solver)
  - `models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticComplexCDispersion.m` (author-neutral complex-c Acoustoelastic dispersion solver)
  - `models/acoustoelastic_iop_hgo/options/defaultAcoustoelasticIOPHGOOptions.m` (author-neutral options implementation)
  - `examples/acoustoelastic_iop_hgo/basic/run_acoustoelastic_iop_hgo_atlas_branch.m`
  - `examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_branch_policy.m`
  - `tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_constitutive_identity.m`
  - `tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_strictA0_smoke.m`
- Generic analysis helpers without legacy naming:
  - `analysis/plotParametricSweepCp.m`
  - `analysis/runParametricSweep.m`
  - `analysis/summarizeParametricSweepBranch.m`
- Maintained base examples in `examples/basic/`.
- Maintained validation scripts in `examples/validation/`.
- `tests/run_all_smoke_tests.m` and current smoke-test folders.

## 6. High-risk files that should not be touched until more tests exist

- `models/acoustoelastic_iop_hgo/core/buildAcoustoelasticMatrix.m` (author-neutral Acoustoelastic matrix-builder helper; `buildMatrix_Li2024_Acoustoelastic.m` remains a compatibility wrapper)
- `models/acoustoelastic_iop_hgo/core/computeSRoots_Li2024.m` (compatibility wrapper for `computeAcoustoelasticSRoots`)
- `models/acoustoelastic_iop_hgo/core/objectiveAcoustoelasticComplexDeterminant.m` (author-neutral complex determinant objective helper; `objectiveComplexDet_Li2024_Acoustoelastic.m` remains a compatibility wrapper)
- `models/acoustoelastic_iop_hgo/core/objectiveAcoustoelasticResidual.m` (author-neutral real-valued residual objective helper; `objective_Li2024_Acoustoelastic.m` remains a compatibility wrapper)
- `models/acoustoelastic_iop_hgo/constitutive/computeAcoustoelasticABGFromIOPHGO.m` (author-neutral implementation; `computeABGFromIOPHGO_Li2024.m` remains a compatibility wrapper)
- `models/acoustoelastic_iop_hgo/constitutive/computeAcoustoelasticAlphaBetaGamma.m` (author-neutral implementation; `computeAlphaBetaGamma_Li2024.m` remains a compatibility wrapper)
- `models/acoustoelastic_iop_hgo/constitutive/computeAcoustoelasticPrestressSigma.m` (author-neutral implementation; `computePrestressSigma_Li2024.m` remains a compatibility wrapper)
- `models/acoustoelastic_iop_hgo/constitutive/solveAcoustoelasticHGOStretch.m` (author-neutral implementation; `solveStretchHGO_Li2024.m` remains a compatibility wrapper)
- `core/computeFundamentalLambModes.m`
- `core/defaultOptions.m`
- `core/defaultParams.m`
- `tracking/solveFundamentalBranch.m`
- `tests/run_all_smoke_tests.m`
- GUI files in `app/`
- `startup.m`

The author-neutral Acoustoelastic matrix-builder helper is now `buildAcoustoelasticMatrix`. The old `buildMatrix_Li2024_Acoustoelastic` name remains as a compatibility wrapper. No matrix assembly logic, matrix entries, determinant logic, or physical equations were intentionally changed during this rename.

The author-neutral Acoustoelastic objective helper names now exist: `objectiveAcoustoelasticResidual` is the real-valued residual objective helper, and `objectiveAcoustoelasticComplexDeterminant` is the complex determinant objective helper. The old `objective_Li2024_Acoustoelastic` and `objectiveComplexDet_Li2024_Acoustoelastic` names remain as compatibility wrappers. No objective, residual, or determinant logic was intentionally changed during this rename.

The author-neutral Acoustoelastic IOP/HGO constitutive helper names now exist, the old `Li2024` helper names remain as compatibility wrappers, and no constitutive logic was intentionally changed during the helper rename.

Before touching these, add targeted tests that compare old and new function outputs on fixed small cases, including edge cases for `strictA0`, complex-c solving, constitutive identity, and GUI-independent default parameter construction.


## Smoke-test compatibility status

`run_all_smoke_tests` now verifies both maintained author-neutral Acoustoelastic IOP/HGO names and preserved `Li2024` legacy wrapper names are resolvable on the MATLAB path. This is a path-level compatibility check only, implemented with `which`; it does not execute the legacy numerical wrappers, solve dispersion curves, or run heavy diagnostics. Numerical equivalence testing remains intentionally deferred to a separate future validation phase.

## Legacy Li2024 reference audit status

This audit keeps the migration documentation-only. Author-neutral Acoustoelastic IOP/HGO names are the maintained names for new code, while `Li2024`-named functions remain callable as compatibility wrappers. Remaining `Li2024` references in compatibility wrappers are intentional. Remaining references in archive, prototype, example, diagnostic, sweep, generated-output, and paper/provenance contexts are historical and should not be renamed in this phase. New implementation code should avoid `Li2024` calls unless the code is explicitly exercising backward compatibility.

Checklist before a future public v1-style API cleanup:

- Keep legacy wrappers until a documented deprecation policy exists.
- Do not rename archive/prototype scripts without a separate archive migration.
- Do not rename literature/provenance references.
- Consider a future explicit compatibility test suite for wrappers.
- Consider a future Rayleigh-Lamb base package reorganization separately.

## 7. Suggested PR phases

### PR 1: audit documents only

- Add `docs/architecture_audit.md` and `docs/internal_rename_migration_plan.md`.
- No MATLAB source changes.
- Validation: run lightweight repository checks; MATLAB smoke validation is optional only if MATLAB is available.

### PR 2: add rename safety tests

- Add tests that call both author-neutral and legacy acoustoelastic entrypoints and compare representative outputs.
- Do not rename implementation files yet.
- Run the required MATLAB sequence.

### PR 3: low-risk acoustoelastic example and diagnostic wrappers

- Introduce author-neutral files for examples/diagnostics listed in section 1.
- Convert old `Li2024`-named example/diagnostic files to wrappers.
- Preserve all documented public entrypoints.
- Run the required MATLAB sequence plus one or two renamed diagnostics manually.

### PR 4: analysis helper rename

- Add `analysis/acoustoelastic_iop_hgo/summarizeAcoustoelasticIOPHGOTrackingQuality.m` author-neutral analysis helper.
- Keep `analysis/summarizeLi2024TrackingQuality.m` as a compatibility wrapper.
- Update only documentation and callers that are already under acoustoelastic diagnostics, if any.
- Run the required MATLAB sequence.

### PR 5: acoustoelastic option and solver compatibility layer

- Keep `defaultLi2024AcoustoelasticOptions` as a wrapper if it is not already purely a wrapper.
- Add author-neutral internal solver names one at a time, starting with the highest-level legacy solver wrappers.
- Avoid changing matrix/constitutive internals in the same PR.
- Run the required MATLAB sequence and targeted old/new output comparisons.

### PR 6: acoustoelastic core/constitutive internal rename

- Rename one cluster at a time: first constitutive helpers, then objective/root helpers, then matrix assembly.
- Keep all old `Li2024` files as wrappers.
- Add equivalence tests before each cluster.
- Run the required MATLAB sequence after each cluster, not just at the end.

### PR 7: Rayleigh-Lamb folder structure preparation

- Add tests that verify base examples, GUI-independent defaults, and `computeFundamentalLambModes` path resolution after `startup`.
- Do not move files yet.
- Document the intended `models/rayleigh_lamb/` path behavior.

### PR 8: Rayleigh-Lamb folder move

- Move base physics files from `core/`, `equations/`, `approximations/`, and `tracking/` into `models/rayleigh_lamb/` subfolders.
- Preserve wrappers in old locations for at least one release.
- Update `startup.m` only in this dedicated PR.
- Run the required MATLAB sequence, base examples, mRLFE smoke, and acoustoelastic smoke.

## Recommended next PR

The safest first implementation PR after this audit is **PR 2: add rename safety tests**. It should add focused equivalence tests for author-neutral and `Li2024`-named acoustoelastic entrypoints without renaming implementation files. This creates a safety net before changing MATLAB function names, wrappers, or path layout.