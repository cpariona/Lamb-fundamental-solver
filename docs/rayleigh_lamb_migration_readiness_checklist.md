# Rayleigh-Lamb migration readiness checklist


> **Current layout update:** The primary Rayleigh-Lamb implementation remains under `models/rayleigh_lamb/` in the `core/`, `equations/`, `approximations/`, and `tracking/` subfolders. The old callable compatibility-wrapper function names now physically live under `models/rayleigh_lamb/legacy/` with matching `core/`, `equations/`, `approximations/`, and `tracking/` subfolders. The old top-level `core/`, `equations/`, `approximations/`, and `tracking/` folders are no longer the Rayleigh-Lamb compatibility-wrapper location. `startup.m` adds the `models/` tree, so both primary `rl*` names and legacy old names remain callable through the updated path behavior.


## Purpose

This checklist is the final gate before any physical movement, deletion, or path restructuring involving the legacy Rayleigh-Lamb top-level folders:

```text
core/
equations/
approximations/
tracking/
```

The compatibility wrapper migration into `models/rayleigh_lamb/legacy/` is complete. Treat this document as the checklist for any future wrapper removal, deprecation, or additional path restructuring. For the stable post-wrapper compatibility checkpoint, see the [Rayleigh-Lamb compatibility snapshot](rayleigh_lamb_compatibility_snapshot.md).

## Current implementation state

- `rl*` functions under `models/rayleigh_lamb/` are the primary Rayleigh-Lamb implementation entrypoints.
- Legacy functions under `models/rayleigh_lamb/legacy/` are compatibility wrappers with explicit compatibility headers.
- Maintained code should use `rl*` names when it calls the Rayleigh-Lamb base implementation directly.
- Old names remain supported for existing scripts and downstream workflows, but they should not be used in new maintained code.

## Required green checks before migration

From a clean checkout, run the following MATLAB sequence before attempting any physical migration:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```

This validation must cover and pass at least the following Rayleigh-Lamb migration gates:

- old and new path checks
- compatibility wrapper smoke checks
- minimal A0/S0 numerical regression fixtures
- maintained-code old-name audit

## Required repository searches before migration

Before migration, run a repository search for old top-level Rayleigh-Lamb call patterns, for example:

```bash
rg -n "\b(defaultParams|defaultOptions|computeFundamentalLambModes|buildFrequencyVector|computeMaterial|computeGeometry|makeBranchSpec|validateParams|validateOptions|rayleighLambAResidual|rayleighLambSResidual|computeA0ThinPlateApproximation|computeS0ExtensionalApproximation|computeAnalyticalApproximations|solveFundamentalBranch)\s*\(" --glob "*.m"
```

Allowed matches should be limited to:

- compatibility wrappers
- `run_all_smoke_tests.m` compatibility/audit sections
- archive/prototype or explicitly legacy files

Any maintained-code match outside these allowed contexts is a migration blocker until it is either converted to the `rl*` API or documented as an intentional legacy exception.

## Required documentation before migration

Before migration, review and keep consistent the current Rayleigh-Lamb API and migration documentation:

- [Rayleigh-Lamb public API](rayleigh_lamb_public_api.md)
- [Rayleigh-Lamb legacy wrapper policy](rayleigh_lamb_legacy_wrapper_policy.md)
- [Rayleigh-Lamb physical migration audit](rayleigh_lamb_physical_migration_audit.md)

The public API table should still identify the primary `rl*` names and legacy compatibility names. The wrapper policy should still describe how old names are supported. The physical migration audit should still capture the risk, rollback, and startup/path considerations for any proposed folder movement.

## Migration strategy recommendation

Recommended strategy: keep `models/rayleigh_lamb/legacy/` as the permanent compatibility-wrapper layer for now.

This preserves old user scripts and downstream workflows, keeps the primary implementation under `models/rayleigh_lamb/`, and documents `models/rayleigh_lamb/legacy/` as the compatibility layer. `startup.m` path behavior should remain synchronized with that layout.

## Explicit no-go conditions

Do not attempt physical migration if any of the following are true:

- `run_all_smoke_tests` fails
- maintained-code audit finds old-name calls outside allowed contexts
- compatibility wrapper smoke checks fail
- minimal A0/S0 regression fixtures fail
- startup/path behavior is not understood
- archive/prototype migration is mixed into the same PR
- a proposed PR deletes compatibility wrappers

## Suggested tag before migration

Create a migration-readiness tag only after the required validation is green and the repository searches show no unexpected maintained-code old-name usage:

```text
v0.7.0-rayleigh-lamb-migration-ready
```

## Suggested next implementation PR

Any next implementation PR should be limited to explicitly scoped compatibility cleanup. It should not delete compatibility wrappers, change numerical behavior, alter public signatures, or mix archive/prototype migration into the same change.
