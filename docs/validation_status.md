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
docs/rayleigh_lamb_public_api.md
docs/rayleigh_lamb_overview.md
```

## mRLFE validation coverage

mRLFE validation is maintained under:

```text
tests/mrlfe/
```

The maintained mRLFE smoke coverage is included by `tests/run_all_smoke_tests.m`. Additional diagnostic context for tracker behavior is documented in:

```text
docs/mrlfe_tracker_diagnostic_summary.md
```

## Acoustoelastic IOP/HGO validation coverage

Acoustoelastic IOP/HGO validation is maintained under:

```text
tests/acoustoelastic_iop_hgo/
```

The maintained acoustoelastic tests exercise author-neutral IOP/HGO entrypoints and are included by `tests/run_all_smoke_tests.m`.

For API and branch-policy details, see:

```text
docs/acoustoelastic_iop_hgo_public_api.md
docs/acoustoelastic_iop_hgo_overview.md
docs/acoustoelastic_iop_hgo_branch_policy.md
```

## Recommended validation command

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```
