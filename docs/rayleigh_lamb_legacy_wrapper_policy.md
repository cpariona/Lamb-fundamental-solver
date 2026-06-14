# Rayleigh-Lamb legacy wrapper policy

## Current API state

The `models/rayleigh_lamb/rl*` functions are the primary Rayleigh-Lamb implementation entrypoints. For the public API table mapping primary `rl*` names to old top-level compatibility names, see [Rayleigh-Lamb public API](rayleigh_lamb_public_api.md). Maintained examples, GUI/app call sites, analysis scripts, and mRLFE examples/tests should prefer the `rl*` names when they need to call the base Rayleigh-Lamb implementation directly.

The old top-level functions in `core/`, `equations/`, `approximations/`, and `tracking/` remain available as compatibility wrappers. These files preserve the historical callable names while forwarding to the maintained `rl*` implementation layer.

This policy is documentation-only. It does not authorize removing files, changing startup path behavior, changing numerical behavior, or migrating physical files.

For the physical migration risk assessment and staged plan for these wrapper folders, see the [Rayleigh-Lamb physical migration audit](rayleigh_lamb_physical_migration_audit.md). Before any physical movement, deletion, or path restructuring, apply the [Rayleigh-Lamb migration readiness checklist](rayleigh_lamb_migration_readiness_checklist.md).

## Compatibility wrapper purpose

The old top-level Rayleigh-Lamb names exist to avoid breaking existing scripts, external notebooks, and downstream workflows that still call the historical API. They provide a stable transition layer while maintained repository code adopts the `rl*` implementation entrypoints.

Compatibility wrappers should stay simple and should not become a second implementation. Their purpose is forwarding, not independent algorithm development.

## Maintained primary API

The maintained primary Rayleigh-Lamb implementation entrypoints are the `rl*` files under `models/rayleigh_lamb/`, grouped by folder below.

### `models/rayleigh_lamb/core/`

- `rlBuildFrequencyVector`
- `rlComputeFundamentalLambModes`
- `rlComputeGeometry`
- `rlComputeMaterial`
- `rlDefaultOptions`
- `rlDefaultParams`
- `rlMakeBranchSpec`
- `rlValidateOptions`
- `rlValidateParams`

### `models/rayleigh_lamb/equations/`

- `rlAResidual`
- `rlSResidual`

### `models/rayleigh_lamb/approximations/`

- `rlComputeA0ThinPlateApproximation`
- `rlComputeAnalyticalApproximations`
- `rlComputeS0ExtensionalApproximation`

### `models/rayleigh_lamb/tracking/`

- `rlSolveFundamentalBranch`

## What must not be removed yet

Until the deprecation and migration prerequisites below are satisfied:

- Do not delete old top-level Rayleigh-Lamb files from `core/`, `equations/`, `approximations/`, or `tracking/`.
- Do not remove old top-level Rayleigh-Lamb names from path checks.
- Do not remove compatibility smoke checks.
- Do not change startup path behavior unless a separate migration PR handles that path transition explicitly.

## Deprecation prerequisites

The old top-level Rayleigh-Lamb names may not be formally deprecated until all of the following exist:

- A documented public API table that identifies maintained `rl*` names, legacy wrapper names, and intended caller guidance.
- At least one tagged release that includes the compatibility wrappers.
- Numerical regression tests for representative A0/S0 cases.
- Clear user-facing migration notes that explain how to replace old top-level calls with `rl*` calls.

## Physical migration prerequisites

No physical Rayleigh-Lamb file migration, removal, or folder cleanup should be attempted until all of the following are true:

- `run_all_smoke_tests` is green from a clean checkout.
- Compatibility wrappers are confirmed to exist and forward to the maintained `rl*` implementation layer.
- Maintained code has no direct old-name calls outside allowed compatibility wrappers.
- There is an explicit decision on whether `core/`, `equations/`, `approximations/`, and `tracking/` remain as legacy folders or become thin wrapper-only folders.

## Test requirements before migration

The smoke suite includes a maintained-code old-name audit that guards against accidental calls to legacy Rayleigh-Lamb names in maintained MATLAB code. Old names are expected only in compatibility wrappers, compatibility smoke checks, documentation, archive/prototype content, or other explicitly allowed legacy contexts.


Before any future migration, the validation plan should include:

- Path checks for both old top-level names and new `rl*` names.
- Compatibility smoke checks that compare selected old-vs-new forwarding behavior.
- At least one numerical regression fixture for representative A0/S0 behavior after the future migration; the current smoke suite already includes minimal representative A0/S0 fixtures using the primary `rl*` API.
- No heavy sweeps in smoke tests; expensive dispersion sweeps should remain outside lightweight smoke coverage.

## Recommended future migration sequence

1. Finalize documentation and compatibility policy.
2. Add numerical regression fixtures for representative Rayleigh-Lamb cases.
3. Add a migration audit ensuring maintained code uses `rl*`.
4. Decide whether to keep top-level folders as legacy wrapper folders.
5. Only then consider physical folder migration.

## Deferred decisions

- Whether top-level `core/`, `equations/`, `approximations/`, and `tracking/` remain permanently.
- Whether to introduce `+package` folders.
- Whether to publish a v1 API table.
- When to formally deprecate old top-level names.
- Whether archive/prototype files should ever be migrated.
