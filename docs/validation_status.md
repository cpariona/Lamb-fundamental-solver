# Validation status

This document records the current validation entrypoints and the validation status expected before merging changes.

## General smoke tests

Run from the repository root:

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```

For focused groups:

```matlab
run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
```

## Focused fitting validation

Fitting validation is intentionally separate from smoke tests because it may be slower and checks synthetic parameter recovery rather than only API execution.

Run:

```matlab
run_fit_validation_tests
```

The fitting validation suite is documented in:

```text
docs/fitting/validation_suite.md
```

## Acoustoelastic IOP/HGO validation

The maintained acoustoelastic IOP/HGO smoke suite includes tests for the official `atlasA0` policy, fallback invalidation, and identity-A0 diagnostic policy.

Representative tests include:

```text
test_acoustoelastic_iop_hgo_atlasA0_smoke
test_acoustoelastic_iop_hgo_fallback_invalidation
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
```

`test_acoustoelastic_iop_hgo_fallback_invalidation` verifies that a fallback-selected atlas branch is preserved as diagnostic data but invalidated as official `Cp/validCp` output.

For API, branch-policy, and module documentation, see:

```text
docs/acoustoelastic_iop_hgo/active/public_api.md
docs/acoustoelastic_iop_hgo/active/branch_policy.md
docs/acoustoelastic_iop_hgo/README.md
docs/acoustoelastic_iop_hgo/documentation_index.md
docs/acoustoelastic_iop_hgo/active/main_gui_integration_closure.md
```

## Recommended validation command

From the repository root:

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

For documentation-only changes, it is sufficient to run the affected smoke groups and confirm there are no broken documentation links by grep/search.
