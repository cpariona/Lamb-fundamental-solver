# Validation status

This document records the maintained validation entrypoints and the validation status expected before merging changes.

## General smoke tests

Run from the repository root:

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```

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

`run_mrlfe_legacy_cleanup_tests` verifies that removed route flags, historical production dependencies, and obsolete maintained entrypoints do not return. It is not an atlas solver validation suite.

Dense and targeted grid diagnostics are documented in:

```text
examples/mrlfe/diagnostics/README.md
docs/validation/mrlfe_grid_presets.md
```

These diagnostics are not part of lightweight smoke suites because their runtime may be substantial.

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
- no repeat of the full two-day matrix is required for documentation-only or FitTool-only changes;
- solver or grid-policy changes require focused tests first, followed by broader validation only when the affected cases justify it.

## Acoustoelastic IOP/HGO validation

The maintained acoustoelastic IOP/HGO smoke suite includes tests for the official `atlasA0` policy, fallback invalidation, and identity-A0 diagnostic policy. This atlas terminology belongs to the AE model and is separate from the removed mRLFE legacy atlas routes.

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

For documentation-only changes, do not rerun expensive numerical matrices. Preserve existing paths and maintained runner names, search for broken references, and run only contract tests that explicitly inspect documentation or repository naming when applicable.

For startup/path policy changes:

```matlab
test_startup_path_policy
test_repository_root_utilities
run_core_smoke_tests
run_all_smoke_tests
```
