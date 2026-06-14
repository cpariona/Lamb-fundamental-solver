# Rayleigh-Lamb legacy wrapper policy


> **Current layout update:** The primary Rayleigh-Lamb implementation remains under `models/rayleigh_lamb/` in the `core/`, `equations/`, `approximations/`, and `tracking/` subfolders. The old callable compatibility-wrapper function names now physically live under `models/rayleigh_lamb/legacy/` with matching `core/`, `equations/`, `approximations/`, and `tracking/` subfolders. The old top-level `core/`, `equations/`, `approximations/`, and `tracking/` folders are no longer the Rayleigh-Lamb compatibility-wrapper location. `startup.m` adds the `models/` tree, so both primary `rl*` names and legacy old names remain callable through the updated path behavior.


## Current API state

The `models/rayleigh_lamb/rl*` functions are the primary Rayleigh-Lamb implementation entrypoints. For the public API table mapping primary `rl*` names to old top-level compatibility names, see [Rayleigh-Lamb public API](rayleigh_lamb_public_api.md). Maintained examples, GUI/app call sites, analysis scripts, and mRLFE examples/tests should prefer the `rl*` names when they need to call the base Rayleigh-Lamb implementation directly.

The old function names in `models/rayleigh_lamb/legacy/core/`, `models/rayleigh_lamb/legacy/equations/`, `models/rayleigh_lamb/legacy/approximations/`, and `models/rayleigh_lamb/legacy/tracking/` remain available as compatibility wrappers. These files preserve the historical callable names while forwarding to the maintained `rl*` implementation layer. The legacy wrapper files now include explicit compatibility headers that identify the corresponding primary `rl*` function, direct new maintained code to call that `rl*` entrypoint, and explain that the wrapper remains for old scripts and notebooks.

This policy records the compatibility contract after physical wrapper migration. It does not authorize changing numerical behavior, removing legacy callable names, or altering public function signatures.

For the physical migration risk assessment and staged plan for these wrapper folders, see the [Rayleigh-Lamb physical migration audit](rayleigh_lamb_physical_migration_audit.md). Before any physical movement, deletion, or path restructuring, apply the [Rayleigh-Lamb migration readiness checklist](rayleigh_lamb_migration_readiness_checklist.md). For the stable post-wrapper compatibility checkpoint, see the [Rayleigh-Lamb compatibility snapshot](rayleigh_lamb_compatibility_snapshot.md).

## Compatibility wrapper purpose

The old Rayleigh-Lamb names exist to avoid breaking existing scripts, external notebooks, and downstream workflows that still call the historical API. They provide a stable transition layer while maintained repository code adopts the `rl*` implementation entrypoints.

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

- Do not delete Rayleigh-Lamb legacy wrapper files from `models/rayleigh_lamb/legacy/`.
- Do not remove old Rayleigh-Lamb names from path checks.
- Do not remove compatibility smoke checks.
- Keep startup path behavior synchronized with the legacy wrapper location under `models/rayleigh_lamb/legacy/`.

## Deprecation prerequisites

The old top-level Rayleigh-Lamb names may not be formally deprecated until all of the following exist:

- A documented public API table that identifies maintained `rl*` names, legacy wrapper names, and intended caller guidance.
- At least one tagged release that includes the compatibility wrappers.
- Numerical regression tests for representative A0/S0 cases.
- Clear user-facing migration notes that explain how to replace old top-level calls with `rl*` calls.

## Physical migration prerequisites

Any future Rayleigh-Lamb legacy-wrapper removal or further folder cleanup should wait until all of the following are true:

- `run_all_smoke_tests` is green from a clean checkout.
- Compatibility wrappers are confirmed to exist and forward to the maintained `rl*` implementation layer.
- Maintained code has no direct old-name calls outside allowed compatibility wrappers.
- There is an explicit decision on whether `models/rayleigh_lamb/legacy/` remains a permanent compatibility layer.

## Test requirements before migration

The smoke suite includes a maintained-code old-name audit that guards against accidental calls to legacy Rayleigh-Lamb names in maintained MATLAB code. Old names are expected only in compatibility wrappers, compatibility smoke checks, documentation, archive/prototype content, or other explicitly allowed legacy contexts.


Before any future legacy-wrapper removal or path transition, the validation plan should include:

- Path checks for both old legacy names and new `rl*` names.
- Compatibility smoke checks that compare selected old-vs-new forwarding behavior.
- At least one numerical regression fixture for representative A0/S0 behavior after the future migration; the current smoke suite already includes minimal representative A0/S0 fixtures using the primary `rl*` API.
- No heavy sweeps in smoke tests; expensive dispersion sweeps should remain outside lightweight smoke coverage.

## Recommended future migration sequence

1. Finalize documentation and compatibility policy.
2. Add numerical regression fixtures for representative Rayleigh-Lamb cases.
3. Add a migration audit ensuring maintained code uses `rl*`.
4. Keep `models/rayleigh_lamb/legacy/` as the physical compatibility-wrapper layer unless a separate deprecation/removal PR changes policy.
5. Only then consider any further legacy-wrapper removal or path transition.

## Deferred decisions

- Whether `models/rayleigh_lamb/legacy/` remains permanently.
- Whether to introduce `+package` folders.
- Whether to publish a v1 API table.
- When to formally deprecate old top-level names.
- Whether archive/prototype files should ever be migrated.
