# Validation status

This document summarizes the maintained validation surface for the current repository. It intentionally tracks active tests and diagnostics only.

## Maintained test entrypoints

```text
tests/run_all_smoke_tests.m
tests/mrlfe/
tests/acoustoelastic_iop_hgo/
```

`tests/run_all_smoke_tests.m` is the top-level smoke-test entrypoint. It covers the current Rayleigh-Lamb `rl*` smoke/regression checks, maintained mRLFE smoke coverage, and maintained author-neutral acoustoelastic IOP/HGO tests.

## Rayleigh-Lamb validation coverage

Rayleigh-Lamb validation is maintained through the `rl*` smoke and regression checks inside `tests/run_all_smoke_tests.m`. These checks verify the clean Rayleigh-Lamb public path used by the base solver and downstream workflows.

For API details, see:

```text
docs/rayleigh_lamb/public_api.md
docs/rayleigh_lamb/overview.md
```

## mRLFE validation coverage

mRLFE validation is maintained under:

```text
tests/mrlfe/
```

The maintained mRLFE smoke coverage is included by `tests/run_all_smoke_tests.m`. Additional diagnostic context for tracker behavior is documented in:

```text
docs/mrlfe/tracker_diagnostic_summary.md
```

## Acoustoelastic IOP/HGO validation coverage

Acoustoelastic IOP/HGO validation is maintained under:

```text
tests/acoustoelastic_iop_hgo/
```

The maintained acoustoelastic tests exercise author-neutral IOP/HGO entrypoints and are included by `tests/run_all_smoke_tests.m`.

Current policy-sensitive tests include:

```text
test_acoustoelastic_iop_hgo_atlasA0_smoke
test_acoustoelastic_iop_hgo_fallback_invalidation
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
```

`test_acoustoelastic_iop_hgo_fallback_invalidation` verifies that a fallback-selected atlas branch is preserved as diagnostic data but invalidated as official `Cp/validCp` output.

For API, branch-policy, and module documentation, see:

```text
docs/acoustoelastic_iop_hgo/public_api.md
docs/acoustoelastic_iop_hgo/branch_policy.md
docs/acoustoelastic_iop_hgo/README.md
docs/acoustoelastic_iop_hgo/documentation_index.md
docs/acoustoelastic_iop_hgo/main_gui_integration_closure.md
```

## Recommended validation command

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```
