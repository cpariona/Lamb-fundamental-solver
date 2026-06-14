# Rayleigh-Lamb wrapper layer release checklist

## Purpose

This checklist records the documentation-only release criteria for the Rayleigh-Lamb wrapper layer and maintained call-site adoption milestone. The tag should only be created after the required validation below passes locally in MATLAB from a clean `main`.

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

- `models/rayleigh_lamb/` contains organized `rl*` wrappers.
- Wrappers forward to existing top-level implementation files.
- Original implementation folders remain in place:
  - `core/`
  - `equations/`
  - `approximations/`
  - `tracking/`

## Call-site adoption state

- Maintained call sites now prefer `rl*` wrapper names where direct substitutions were low risk.
- Original top-level functions remain callable.
- Archive/prototype paths were intentionally not changed.

## Compatibility state

- Old top-level Rayleigh-Lamb functions remain available.
- `run_all_smoke_tests` includes path-level checks for both current base functions and organized wrapper functions.
- These checks are path-only, not numerical equivalence tests.

## Deferred work not required for this tag

- physical file migration into models/rayleigh_lamb/
- numerical regression fixtures
- formal deprecation policy for top-level base functions
- archive/prototype migration
- package-folder strategy using +package folders
- public v1 API documentation

## Suggested tag name

```text
v0.5.0-rayleigh-lamb-wrapper-layer
```
