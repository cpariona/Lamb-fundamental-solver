# Rayleigh-Lamb physical migration audit

Before using this audit to plan any folder movement, apply the [Rayleigh-Lamb migration readiness checklist](rayleigh_lamb_migration_readiness_checklist.md) as the final gate.

## Current state

The `models/rayleigh_lamb/rl*` files contain the primary Rayleigh-Lamb implementation. The old top-level folders `core/`, `equations/`, `approximations/`, and `tracking/` remain in place as compatibility wrapper folders that preserve historical callable names while forwarding to the `rl*` layer.

Maintained call sites should prefer the `rl*` names when directly calling the Rayleigh-Lamb base solver. Compatibility smoke checks and minimal numerical regression fixtures exist so that old-name forwarding and representative A0/S0 behavior can be checked before any future physical migration.

## Files currently acting as primary implementation

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

## Files currently acting as compatibility wrappers

### core

- `core/buildFrequencyVector.m`
- `core/computeFundamentalLambModes.m`
- `core/computeGeometry.m`
- `core/computeMaterial.m`
- `core/defaultOptions.m`
- `core/defaultParams.m`
- `core/makeBranchSpec.m`
- `core/validateOptions.m`
- `core/validateParams.m`

### equations

- `equations/rayleighLambAResidual.m`
- `equations/rayleighLambSResidual.m`

### approximations

- `approximations/computeA0ThinPlateApproximation.m`
- `approximations/computeAnalyticalApproximations.m`
- `approximations/computeS0ExtensionalApproximation.m`

### tracking

- `tracking/solveFundamentalBranch.m`

## Maintained code dependency state

`tests/run_all_smoke_tests.m` now includes a lightweight maintained-code static audit that scans MATLAB files under `analysis/`, `app/`, `examples/`, and `tests/` for function-call uses of old top-level Rayleigh-Lamb names. The audit excludes compatibility wrappers, the primary `models/rayleigh_lamb/` implementation layer, archive/prototype material, `examples/archive/`, and the smoke-test file itself because it intentionally exercises old names for path and compatibility checks.


Maintained code should not directly depend on old top-level Rayleigh-Lamb names except where those names are intentionally exercised by compatibility tests or implemented inside compatibility wrapper files. Before any physical migration, this state must be verified with a repository search confirming that maintained code uses the `rl*` names and that any remaining old-name references are intentional compatibility coverage, wrapper implementations, documentation, or archived/prototype material.

## Startup/path considerations

MATLAB path behavior must be reviewed before removing or relocating the top-level `core/`, `equations/`, `approximations/`, or `tracking/` folders. Existing scripts may rely on `startup.m` or user startup workflows that add those top-level folders to the MATLAB path. Removing or moving the folders without a path transition plan could break path resolution even if the `rl*` implementation remains correct.

## Risks of physical migration

- breaking user scripts that call old top-level names
- breaking MATLAB path resolution
- introducing duplicate function names
- changing function precedence unexpectedly
- breaking archived/prototype scripts
- making rollback harder if multiple moves occur in one PR

## Preconditions before physical migration

- green `run_all_smoke_tests` from clean `main`
- compatibility wrapper smoke checks passing
- minimal A0/S0 regression fixtures passing
- repository search confirming maintained code uses `rl*` names
- explicit decision on whether legacy top-level folders remain permanently

## Recommended low-risk migration strategy

The next actual implementation PR, if any, should not delete compatibility wrappers.

Option A is to keep the top-level folders as permanent compatibility-wrapper folders. This is the safest next implementation strategy because it preserves old user-facing names, minimizes MATLAB path surprises, and allows maintained code to continue using the `rl*` implementation layer without forcing an immediate path or deprecation decision.

Option B is to move compatibility wrappers to a clearly named legacy layer, but only after startup/path behavior is explicitly redesigned and validated. This option carries more path-resolution and user-script risk, so it should not be the next physical migration step unless the project first decides how legacy paths will be supported.

## Explicitly forbidden changes for the next migration PR

- do not delete top-level compatibility wrappers
- do not remove old names from smoke tests
- do not remove compatibility smoke checks
- do not modify `startup.m` in the same PR as physical migration
- do not move archive/prototype files
- do not change numerical logic
- do not change public function signatures

## Rollback strategy

If a future migration breaks path resolution or tests, the rollback should restore these folders as compatibility-wrapper folders pointing to the `rl*` implementation layer:

```text
core/
equations/
approximations/
tracking/
```

Rollback should be small and mechanical: restore the wrapper files, restore any path assumptions needed for those wrapper folders, rerun compatibility smoke checks, and rerun the minimal A0/S0 regression fixtures.

## Open decisions

- whether top-level compatibility folders remain permanently
- whether a future `+package` folder structure is desirable
- whether `startup.m` should eventually stop adding legacy folders
- whether archive/prototype scripts should ever be migrated
- when old names should become formally deprecated
