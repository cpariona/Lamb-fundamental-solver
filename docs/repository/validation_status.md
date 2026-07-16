# Validation status

This document records the maintained validation entrypoints and the validation status expected before merging changes.

## Repository naming Phase 3 status

The 2026-07-15 naming phase directly renamed the maintained mRLFE default
example and targeted-grid validation, four substantive AE diagnostics, two
mRLFE model internals, three mRLFE route-integrity tests, their public/canonical
runner pair, and one execution-profile contract test. No old-name wrapper was
added. The redundant task-oriented execution-profile aggregate was removed
because it owned no tests and only repeated canonical runners.

The naming guardrail verifies tracked filename/function agreement, maintained
example terms, model/app prefixes, documented entrypoint definitions, the nine
intentional public runner-wrapper duplicates, and absence of every Phase 3 old
name. The deterministic inventory now records 106 tests, 42 runner
implementations, 9 public wrappers, 3 helpers, 222 edges, and 106 canonical
owners, with zero unowned, multiply owned, manual-only, overlapping, or cyclic
tests/runners.

Routine quick contract, quick smoke, numerical regression, focused mRLFE, AE,
GUI, execution-profile integration, fitting validation, and
`run_all_smoke_tests` passed on MATLAB R2024b/PCWIN64. mRLFE production
characterization reported zero maximum absolute and relative Cp difference;
the renamed internal defaults and both residual methods matched the saved
pre-rename baseline exactly. Code Analyzer finished with 0 findings across 57
changed or renamed MATLAB files after 17 behavior-neutral initial findings were
resolved. Extended integration was not executed because names and references
changed without changing model dispatch, fitting evaluators, numerical policy,
or canonical test ownership.

## Repository structure Phase 2 status

The 2026-07-15 layer-ownership correction moved `aeRunSweep` from the AE model
solver folder to `analysis/acoustoelastic_iop_hgo/`, grouped six cross-model
sweep helpers under `analysis/sweeps/`, moved four model-specific profile and
surface-metadata adapters under `app/adapters/`, moved `createFittingTab` under
`app/fitting/`, and moved the interactive AE grid-sweep UI under `app/sweep/`.
No command name or public interface changed, and no compatibility wrapper was
added.

The moved `aeRunSweep` produced bit-for-bit identical requested grids, Cp,
valid masks, reliability structures, and summary tables on the bounded parity
case. Startup/path tests, focused AE and GUI suites, quick contract, quick
smoke, numerical regression, and `run_all_smoke_tests` passed. Code Analyzer
finished at 0 findings across 18 changed or moved MATLAB files.

Test ownership regenerated at 105 tests and 209 edges with zero unowned tests,
multiple canonical owners, sibling direct overlaps, manual-only tests, or
cycles. The three additional edges are direct calls from new path-location
contracts to `testRepositoryRoot`; runner membership and canonical owners did
not change. Extended integration was not executed because no dispatch,
fitting-orchestration, solver, grid, or numerical-policy boundary changed.

## Repository cleanup Phase 1 status

The 2026-07-15 deletion phase passed startup/path checks, all three routine
gates, focused mRLFE public/production/smoke gates, focused AE quick/full smoke,
and `run_all_smoke_tests`. The mRLFE production characterization reported zero
Cp difference.

Test ownership regenerated at 105 tests and 206 edges with zero unowned tests,
multiple canonical owners, sibling direct overlaps, manual-only tests, or
cycles. Relative Markdown links were 0 broken before and after. Code Analyzer
reported one stale suppression before cleanup and 0 findings after the fix
across 10 modified MATLAB files.

Extended integration was not run because the deleted files had no extended-
owned coverage. Full fitting validation was not run separately because no
fitting helper or fitting behavior changed; GUI and AE fitting contracts passed
through focused and aggregate smoke coverage.

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
run_mrlfe_route_integrity_tests
run_mrlfe_production_core_tests
run_mrlfe_public_contract_tests
run_mrlfe_smoke_tests
run_fit_validation_tests
```

## Tiered validation

Run from the repository root:

```matlab
clear functions
rehash toolboxcache
startup

run_quick_contract_tests
run_quick_smoke_tests
```

`run_quick_smoke_tests` is the recommended routine developer command. Static
ownership shows 14 tests reachable from quick contracts and 47 tests reachable
from quick smoke. Known multi-minute characterization, performance evidence,
the 36-case matrix, and the stale benchmark are excluded.

Use the explicit non-quick tiers when scope requires them:

```matlab
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

The historical `run_all_smoke_tests` command remains broad for compatibility;
it now reaches 55 tests through focused owners and is not the routine quick
gate.

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

Use these focused runners after changes to the public API, production core, GUI consumers, sweeps, fitting, tracking, termination, or route-integrity contracts:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_neutral_production_helper_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_route_integrity_tests
```

`run_mrlfe_route_integrity_tests` verifies that removed route flags, historical production dependencies, and obsolete maintained entrypoints do not return. It is not an atlas solver validation suite and should not duplicate broad FitTool or GUI characterization already owned by their focused runners.

Exact Cp equivalence between consumers is required only when both routes use the same request and internal grid policy. FitTool optimization intentionally uses `fitOptimized`, while explicit requested-curve evaluation uses `numericalPreset`.

Dense and targeted grid diagnostics are documented in:

```text
examples/mrlfe/diagnostics/README.md
docs/validation/mrlfe_grid_presets.md
```

These diagnostics are not part of lightweight smoke suites because their runtime may be substantial.

`run_mrlfe_production_core_tests` preserves its historical eight-test coverage
as an aggregate of contract, characterization, and performance owners. Use
`run_mrlfe_production_core_contract_tests` for the focused six-test numerical
contract set.
The execution-profile validation matrix remains extended. The bounded direct-
profile benchmark contract is owned by diagnostics; full descriptive benchmark
mode remains manual and is excluded from quick, smoke, and numerical tiers.
`run_main_gui_export_tests` remains a focused standalone export-contract
runner.

## Current mRLFE contract baseline

The `test/mrlfe-contract-baseline` branch realigns stale tests with the maintained implementation without changing production code.

Validated behavior includes:

- `fast`, `balanced`, `robust`, and `dense` are accepted public numerical presets;
- unsupported preset names still raise `mrlfe:InvalidNumericalPreset`;
- Main GUI applies Balanced directly as the `balanced` numerical preset;
- Main GUI status is derived from the returned public quality state rather than a fixed expected marginal case;
- FitTool/direct exact equality is asserted only on a shared internal solve grid;
- the route-integrity runner remains focused and does not repeat FitTool solver work.

The user executed and reported passing:

```matlab
test_mrlfe_public_contract_validation
run_mrlfe_public_contract_tests
test_mrlfe_main_gui_result_contract
run_mrlfe_route_integrity_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_smoke_tests
run_gui_smoke_tests
```

No pass is claimed for runners not executed on this branch. The extended grid matrix and broad fitting validation were not required because no production solver, grid, fitting, or GUI behavior changed.

## Test-baseline repair status

The three failures captured by the cleanup runtime audit received focused,
evidence-backed repairs; the detailed diagnosis remains in Git history:

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

`run_ae_quick_tests` owns lightweight AE contracts, including the short
entrypoint and identity-A0 diagnostic-policy tests. Solver-grid, fallback,
atlas smoke, and synthetic fitting regressions are owned by
`run_ae_extended_tests`. The historical `run_acoustoelastic_smoke_tests`
command aggregates both owners and reaches 12 tests. This atlas terminology
belongs to the AE model and is separate from the removed mRLFE legacy atlas
routes.

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

For routine code changes:

```matlab
clear functions
rehash toolboxcache
startup

run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
```

Add focused extended owners when the changed surface requires them. Do not run
the complete extended aggregate solely for closure when its multi-minute
matrix and characterization cases are unrelated.

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
