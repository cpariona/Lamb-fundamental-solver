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
docs/workflows/fitting/validation_suite.md
```

## Focused mRLFE atlas validation

The mRLFE atlas contract suite is separate from the broader mRLFE smoke suite because it checks branch-policy routing, direct-visco atlas compatibility, adaptive continuation, delayed modal cuts, and the high-level A0 policy selector.

Run after changes to mRLFE atlas solvers, branch policies, or atlas diagnostics:

```matlab
tests/run_mrlfe_legacy_cleanup_tests
```

For dense numerical evidence, use the primary diagnostics documented in:

```text
examples/mrlfe/diagnostics/README.md
docs/models/mrlfe/atlas_policy_notes.md
```

Dense diagnostics are not a replacement for contract tests and should not be added to lightweight smoke suites unless they are explicitly bounded in runtime.

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
docs/models/acoustoelastic_iop_hgo/active/public_api.md
docs/models/acoustoelastic_iop_hgo/active/branch_policy.md
docs/models/acoustoelastic_iop_hgo/README.md
docs/models/acoustoelastic_iop_hgo/documentation_index.md
docs/models/acoustoelastic_iop_hgo/archive/main_gui_integration_closure.md
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

`run_core_smoke_tests` includes `test_lightweight_numerical_regression`, a lightweight Rayleigh-Lamb, mRLFE, and AE IOP/HGO snapshot suite that does not write generated outputs.

For mRLFE atlas-specific changes, additionally run:

```matlab
tests/run_mrlfe_legacy_cleanup_tests
```

For documentation-only changes, it is sufficient to run the affected smoke groups and confirm there are no broken documentation links by grep/search.

For startup/path policy changes, run:

```matlab
test_startup_path_policy
test_repository_root_utilities
run_core_smoke_tests
run_all_smoke_tests
```

For shared output-folder helper changes, run:

```matlab
test_model_output_folder_helpers
run_core_smoke_tests
```
