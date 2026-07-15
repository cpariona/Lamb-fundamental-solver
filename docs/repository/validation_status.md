# Validation status

This document records the maintained validation entrypoints and the validation status expected before merging changes.

## Public runner topology

Nine maintained public commands are compatibility wrappers: eight wrappers at
the root of `tests/` and the legacy-folder `run_fit_validation_tests` wrapper.
Each delegates through `runRepositoryTestRunner` to a same-named implementation
under `tests/runners/`. `run_main_gui_export_tests` is a maintained standalone
root runner, not a wrapper.

The wrapper commands are:

```matlab
run_acoustoelastic_smoke_tests
run_all_smoke_tests
run_core_smoke_tests
run_gui_smoke_tests
run_mrlfe_legacy_cleanup_tests
run_mrlfe_production_core_tests
run_mrlfe_public_contract_tests
run_mrlfe_smoke_tests
run_fit_validation_tests
```

## General smoke tests

Run from the repository root:

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```

Despite the historical command name, this aggregate currently reaches
contract, numerical-regression, synthetic-fitting, and characterization work.
Treat it as broad validation until measured runtime evidence supports a future
quick-versus-extended split.

Focused groups:

```matlab
run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
```

## Focused fitting validation

Fitting validation is intentionally separate from smoke tests because it may be slower and checks synthetic parameter recovery rather than only API execution.

```matlab
run_fit_validation_tests
```

The fitting validation suite is documented in:

```text
docs/workflows/fitting/validation_suite.md
```

## Maintained mRLFE validation

The maintained mRLFE architecture uses the public `mrlfeSolve` route. Atlas-specific production tests and runners were removed with the legacy routes.

Use these focused runners after changes to the public API, production core, GUI consumers, sweeps, fitting, tracking, termination, or cleanup contracts:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_neutral_production_helper_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_legacy_cleanup_tests
```

`run_mrlfe_legacy_cleanup_tests` verifies that removed route flags, historical production dependencies, and obsolete maintained entrypoints do not return. It is not an atlas solver validation suite and should not duplicate broad FitTool or GUI characterization already owned by their focused runners.

Exact Cp equivalence between consumers is required only when both routes use the same request and internal grid policy. FitTool optimization intentionally uses `fitOptimized`, while explicit requested-curve evaluation uses `numericalPreset`.

Dense and targeted grid diagnostics are documented in:

```text
examples/mrlfe/diagnostics/README.md
docs/validation/mrlfe_grid_presets.md
```

These diagnostics are not part of lightweight smoke suites because their runtime may be substantial.

`run_mrlfe_production_core_tests` is also mixed extended validation today: it
includes contracts and grid checks together with characterization and
performance evidence. Preserve that membership until the planned runner split.
The execution-profile validation matrix and benchmark/diagnostic runners are
maintained commands but are intentionally excluded from normal smoke
validation. `run_main_gui_export_tests` remains a focused standalone export
contract runner.

## Current mRLFE contract baseline

The `test/mrlfe-contract-baseline` branch realigns stale tests with the maintained implementation without changing production code.

Validated behavior includes:

- `fast`, `balanced`, `robust`, and `dense` are accepted public numerical presets;
- unsupported preset names still raise `mrlfe:InvalidNumericalPreset`;
- Main GUI applies Balanced directly as the `balanced` numerical preset;
- Main GUI status is derived from the returned public quality state rather than a fixed expected marginal case;
- FitTool/direct exact equality is asserted only on a shared internal solve grid;
- the legacy-cleanup runner remains focused and does not repeat FitTool solver work.

The user executed and reported passing:

```matlab
test_mrlfe_public_contract_validation
run_mrlfe_public_contract_tests
test_mrlfe_main_gui_result_contract
run_mrlfe_legacy_cleanup_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_smoke_tests
run_gui_smoke_tests
```

No pass is claimed for runners not executed on this branch. The extended grid matrix and broad fitting validation were not required because no production solver, grid, fitting, or GUI behavior changed.

## Test-baseline repair status

The three failures captured by the cleanup runtime audit have focused,
evidence-backed repairs documented in
`docs/repository/test_baseline_failure_diagnosis.md`:

- AE `identityA0` diagnostics are projected to the requested result grid while
  retaining the internal tracking grid for branch selection;
- the lightweight mRLFE fixture now names the maintained fast preset grid,
  branch policies, fallback state, quality state, and current public-solver
  values explicitly;
- the fast fitting regression asserts exact equivalence only for the same grid
  policy and reports fit-optimized versus numerical-preset differences as a
  diagnostic.

The three individual tests pass on MATLAB R2024b/PCWIN64. The focused
`run_acoustoelastic_smoke_tests`, `run_core_smoke_tests`, and
`run_mrlfe_fit_public_solver_tests` runners also pass. No runner membership or
public command changed.

## mRLFE grid-validation status

The production presets remain:

```text
fast     50 Hz
balanced 25 Hz
robust   20 Hz
dense    10 Hz reference
```

The full extended matrix completed on 2026-07-14. Its aggregate preset acceptance failed because several dense-reference cases were already marginal, with quality labels such as `low_valid_fraction` or `large_relative_jump`.

A targeted follow-up validation isolated those cases. No accepted dense-reference solution degraded under the candidate grids. Large pointwise differences were confined to already invalid or marginal branch tails. Therefore:

- accepted reference solutions remain the blocking basis for preset equivalence;
- marginal reference solutions remain diagnostic and do not independently reject a preset;
- no repeat of the full two-day matrix is required for documentation-only, test-contract-only, or FitTool-only changes;
- solver or grid-policy changes require focused tests first, followed by broader validation only when the affected cases justify it.

## Acoustoelastic IOP/HGO validation

The maintained acoustoelastic IOP/HGO smoke suite executes tests for the
official `atlasA0` policy and fallback invalidation. It verifies that the
standalone identity-A0 diagnostic contract is present but does not execute it;
that test remains without executable maintained-runner registration. This
atlas terminology belongs to the AE model and is separate from the removed
mRLFE legacy atlas routes.

Representative tests include:

```text
test_acoustoelastic_iop_hgo_atlasA0_smoke
test_acoustoelastic_iop_hgo_fallback_invalidation
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
```

For API, branch-policy, and module documentation, see:

```text
docs/models/acoustoelastic_iop_hgo/active/public_api.md
docs/models/acoustoelastic_iop_hgo/active/branch_policy.md
docs/models/acoustoelastic_iop_hgo/README.md
docs/models/acoustoelastic_iop_hgo/documentation_index.md
```

## Recommended validation command

For broad code changes:

```matlab
clear functions
rehash toolboxcache
startup

run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
run_fit_validation_tests
```

For mRLFE production-route changes, additionally run the focused public-contract and consumer runners listed above.

For localized mRLFE test-contract changes, run the directly affected tests and focused runners first, followed by `run_mrlfe_smoke_tests` and `run_gui_smoke_tests`. Do not automatically run expensive grid matrices or unrelated fitting-recovery suites.

For documentation-only changes, do not rerun expensive numerical matrices. Preserve existing paths and maintained runner names, search for broken references, and run only contract tests that explicitly inspect documentation or repository naming when applicable.

For startup/path policy changes:

```matlab
test_startup_path_policy
test_repository_root_utilities
run_core_smoke_tests
run_all_smoke_tests
```
