# Rayleigh-Lamb compatibility snapshot


> **Current layout update:** The primary Rayleigh-Lamb implementation remains under `models/rayleigh_lamb/` in the `core/`, `equations/`, `approximations/`, and `tracking/` subfolders. The old callable compatibility-wrapper function names now physically live under `models/rayleigh_lamb/legacy/` with matching `core/`, `equations/`, `approximations/`, and `tracking/` subfolders. The old top-level `core/`, `equations/`, `approximations/`, and `tracking/` folders are no longer the Rayleigh-Lamb compatibility-wrapper location. `startup.m` adds the `models/` tree, so both primary `rl*` names and legacy old names remain callable through the updated path behavior.


## Snapshot purpose

This document captures the stable post-wrapper, post-compatibility state of the Rayleigh-Lamb base solver before any physical migration of legacy folders. It is intended as a documentation-only checkpoint for the current API, wrapper, test, and migration-readiness state.

## Current primary implementation

Primary implementation files live under:

```text
models/rayleigh_lamb/
```

They are grouped as follows.

### core

- `models/rayleigh_lamb/core/rlBuildFrequencyVector.m`
- `models/rayleigh_lamb/core/rlComputeFundamentalLambModes.m`
- `models/rayleigh_lamb/core/rlComputeGeometry.m`
- `models/rayleigh_lamb/core/rlComputeMaterial.m`
- `models/rayleigh_lamb/core/rlDefaultOptions.m`
- `models/rayleigh_lamb/core/rlDefaultParams.m`
- `models/rayleigh_lamb/core/rlMakeBranchSpec.m`
- `models/rayleigh_lamb/core/rlValidateOptions.m`
- `models/rayleigh_lamb/core/rlValidateParams.m`

### equations

- `models/rayleigh_lamb/equations/rlAResidual.m`
- `models/rayleigh_lamb/equations/rlSResidual.m`

### approximations

- `models/rayleigh_lamb/approximations/rlComputeA0ThinPlateApproximation.m`
- `models/rayleigh_lamb/approximations/rlComputeAnalyticalApproximations.m`
- `models/rayleigh_lamb/approximations/rlComputeS0ExtensionalApproximation.m`

### tracking

- `models/rayleigh_lamb/tracking/rlSolveFundamentalBranch.m`

## Current compatibility layer

Legacy files under `models/rayleigh_lamb/legacy/core/`, `models/rayleigh_lamb/legacy/equations/`, `models/rayleigh_lamb/legacy/approximations/`, and `models/rayleigh_lamb/legacy/tracking/` remain available. These legacy names forward to the primary `rl*` implementation files and include explicit compatibility headers that identify the corresponding primary entrypoint.

These compatibility wrappers should not be removed yet. They preserve existing scripts, notebooks, and downstream workflows while maintained repository code uses the primary `rl*` names.

## Maintained call-site state

Maintained code should call `rl*` names, not old legacy names. Old top-level names are intentionally reserved for compatibility wrappers, compatibility checks, documentation, and explicitly legacy or archived contexts.

## Test coverage state

The current compatibility-ready state is covered by:

- path checks for old and new names
- compatibility wrapper forwarding smoke checks
- minimal A0/S0 numerical regression fixtures
- maintained-code old-name static audit

## Documentation state

The compatibility snapshot is supported by the existing Rayleigh-Lamb documentation set:

- [Rayleigh-Lamb public API](rayleigh_lamb_public_api.md)
- [Rayleigh-Lamb legacy wrapper policy](rayleigh_lamb_legacy_wrapper_policy.md)
- [Rayleigh-Lamb physical migration audit](rayleigh_lamb_physical_migration_audit.md)
- [Rayleigh-Lamb migration readiness checklist](rayleigh_lamb_migration_readiness_checklist.md)

## Safe user guidance

New user-facing code should use these primary `rl*` entrypoints:

- `rlDefaultParams`
- `rlDefaultOptions`
- `rlComputeFundamentalLambModes`
- `rlComputeAnalyticalApproximations`

Old names remain available for existing scripts, notebooks, and downstream workflows, but they should not be used in new maintained code.

## Migration status

Physical migration of Rayleigh-Lamb compatibility wrappers has now been performed. Option A remains recommended: keep the `models/rayleigh_lamb/legacy/` folders as compatibility-wrapper folders for now.

This keeps MATLAB path behavior stable, avoids breaking old user code, and preserves a clear separation between the primary implementation layer and legacy callable names.

## Recommended tag

```text
v0.7.0-rayleigh-lamb-compatibility-ready
```

## Next recommended work

- Create the tag after `run_all_smoke_tests` passes on clean `main`.
- Avoid physical migration unless there is a strong need.
- If migration is attempted, keep old wrappers and do not modify `startup.m` in the same PR.
