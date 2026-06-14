# Rayleigh-Lamb wrapper layer release checklist

## Purpose

This checklist records the documentation-only release criteria for the Rayleigh-Lamb `rl*` implementation handoff and maintained call-site adoption milestone. The tag should only be created after the required validation below passes locally in MATLAB from a clean `main`.

## Required local validation before tagging

Run the following sequence locally in MATLAB from a clean `main` checkout before creating the tag:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```

Do not create the tag until this validation passes.

## Wrapper layer state

- `models/rayleigh_lamb/` contains the primary `rl*` Rayleigh-Lamb implementation entrypoints.
- Old top-level Rayleigh-Lamb function names are retained as compatibility wrappers that forward to the `rl*` implementations.
- Original top-level folders remain in place and files have not yet been physically removed:
  - `core/`
  - `equations/`
  - `approximations/`
  - `tracking/`

## Call-site adoption state

- Maintained call sites now prefer `rl*` wrapper names where direct substitutions were low risk.
- Original top-level functions remain callable as compatibility wrappers.
- Archive/prototype paths were intentionally not changed and migration remains deferred.
- Numerical behavior is intended to remain unchanged.

## Compatibility state

- Old top-level Rayleigh-Lamb functions remain available as compatibility wrappers.
- `run_all_smoke_tests` includes path-level checks for both old top-level compatibility wrappers and primary `rl*` functions.
- These checks are path-only, not numerical equivalence tests.

## Deferred work not required for this tag

- physical removal of old top-level files
- numerical regression fixtures
- formal deprecation policy for top-level base functions
- archive/prototype migration
- package-folder strategy using +package folders
- public v1 API documentation

## Suggested tag name

```text
v0.5.0-rayleigh-lamb-wrapper-layer
```
