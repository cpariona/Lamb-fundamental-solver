# Rayleigh-Lamb wrapper layer release checklist

## Purpose

This checklist records the documentation-only release criteria for the Rayleigh-Lamb `rl*` implementation handoff and maintained call-site adoption milestone. For the public `rl*` API table and old-name mapping, see [Rayleigh-Lamb public API](rayleigh_lamb_public_api.md). For the ongoing maintenance, deprecation, and physical-migration rules for old top-level wrappers, see [Rayleigh-Lamb legacy wrapper policy](rayleigh_lamb_legacy_wrapper_policy.md). The tag should only be created after the required validation below passes locally in MATLAB from a clean `main`.

Before any future physical migration of the legacy wrapper folders, consult the [Rayleigh-Lamb physical migration audit](rayleigh_lamb_physical_migration_audit.md) and apply the [Rayleigh-Lamb migration readiness checklist](rayleigh_lamb_migration_readiness_checklist.md).

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
- `run_all_smoke_tests` also includes lightweight compatibility smoke checks that compare selected safe old-vs-new helper outputs to verify forwarding behavior.
- Minimal Rayleigh-Lamb numerical regression smoke fixtures now exercise representative A0/S0 outputs through the primary `rl*` API without full dispersion sweeps, plotting, file I/O, or generated fixtures.

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
