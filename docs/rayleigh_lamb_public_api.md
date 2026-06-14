# Rayleigh-Lamb public API

## API status

The `rl*` functions under `models/rayleigh_lamb/` are the primary Rayleigh-Lamb implementation entrypoints.

The old top-level functions under `core/`, `equations/`, `approximations/`, and `tracking/` remain supported as compatibility wrappers that preserve the historical callable names while forwarding to the primary `rl*` implementation layer.

No top-level compatibility function is formally deprecated yet unless explicitly documented elsewhere.

For the documentation-only audit governing future physical movement, removal, or retention of the legacy wrapper folders, see the [Rayleigh-Lamb physical migration audit](rayleigh_lamb_physical_migration_audit.md). For the final gate before any such migration, see the [Rayleigh-Lamb migration readiness checklist](rayleigh_lamb_migration_readiness_checklist.md).

## Primary API table

| Folder | Primary function | Purpose | Legacy compatibility name |
| --- | --- | --- | --- |
| `models/rayleigh_lamb/core/` | `rlDefaultParams` | Build the default Rayleigh-Lamb parameter structure. | `defaultParams` |
| `models/rayleigh_lamb/core/` | `rlDefaultOptions` | Build the default Rayleigh-Lamb solver options structure. | `defaultOptions` |
| `models/rayleigh_lamb/core/` | `rlComputeFundamentalLambModes` | Compute the fundamental A0/S0 Rayleigh-Lamb modes and optional model outputs. | `computeFundamentalLambModes` |
| `models/rayleigh_lamb/core/` | `rlBuildFrequencyVector` | Construct the frequency vector used by the base solver workflow. | `buildFrequencyVector` |
| `models/rayleigh_lamb/core/` | `rlComputeMaterial` | Compute material quantities derived from Rayleigh-Lamb parameters. | `computeMaterial` |
| `models/rayleigh_lamb/core/` | `rlComputeGeometry` | Compute geometry quantities derived from Rayleigh-Lamb parameters. | `computeGeometry` |
| `models/rayleigh_lamb/core/` | `rlMakeBranchSpec` | Construct branch specifications for fundamental-mode tracking. | `makeBranchSpec` |
| `models/rayleigh_lamb/core/` | `rlValidateParams` | Validate Rayleigh-Lamb parameter structures. | `validateParams` |
| `models/rayleigh_lamb/core/` | `rlValidateOptions` | Validate Rayleigh-Lamb solver option structures. | `validateOptions` |
| `models/rayleigh_lamb/equations/` | `rlAResidual` | Evaluate the normalized antisymmetric Rayleigh-Lamb residual. | `rayleighLambAResidual` |
| `models/rayleigh_lamb/equations/` | `rlSResidual` | Evaluate the normalized symmetric Rayleigh-Lamb residual. | `rayleighLambSResidual` |
| `models/rayleigh_lamb/approximations/` | `rlComputeA0ThinPlateApproximation` | Compute the A0 thin-plate analytical approximation. | `computeA0ThinPlateApproximation` |
| `models/rayleigh_lamb/approximations/` | `rlComputeS0ExtensionalApproximation` | Compute the S0 extensional analytical approximation. | `computeS0ExtensionalApproximation` |
| `models/rayleigh_lamb/approximations/` | `rlComputeAnalyticalApproximations` | Compute the maintained set of analytical Rayleigh-Lamb approximations. | `computeAnalyticalApproximations` |
| `models/rayleigh_lamb/tracking/` | `rlSolveFundamentalBranch` | Solve and track one fundamental Rayleigh-Lamb branch. | `solveFundamentalBranch` |

## Compatibility API table

| Legacy folder | Legacy function | Primary replacement | Status |
| --- | --- | --- | --- |
| `core/` | `defaultParams` | `rlDefaultParams` | Compatibility wrapper; not formally deprecated. |
| `core/` | `defaultOptions` | `rlDefaultOptions` | Compatibility wrapper; not formally deprecated. |
| `core/` | `computeFundamentalLambModes` | `rlComputeFundamentalLambModes` | Compatibility wrapper; not formally deprecated. |
| `core/` | `buildFrequencyVector` | `rlBuildFrequencyVector` | Compatibility wrapper; not formally deprecated. |
| `core/` | `computeMaterial` | `rlComputeMaterial` | Compatibility wrapper; not formally deprecated. |
| `core/` | `computeGeometry` | `rlComputeGeometry` | Compatibility wrapper; not formally deprecated. |
| `core/` | `makeBranchSpec` | `rlMakeBranchSpec` | Compatibility wrapper; not formally deprecated. |
| `core/` | `validateParams` | `rlValidateParams` | Compatibility wrapper; not formally deprecated. |
| `core/` | `validateOptions` | `rlValidateOptions` | Compatibility wrapper; not formally deprecated. |
| `equations/` | `rayleighLambAResidual` | `rlAResidual` | Compatibility wrapper; not formally deprecated. |
| `equations/` | `rayleighLambSResidual` | `rlSResidual` | Compatibility wrapper; not formally deprecated. |
| `approximations/` | `computeA0ThinPlateApproximation` | `rlComputeA0ThinPlateApproximation` | Compatibility wrapper; not formally deprecated. |
| `approximations/` | `computeS0ExtensionalApproximation` | `rlComputeS0ExtensionalApproximation` | Compatibility wrapper; not formally deprecated. |
| `approximations/` | `computeAnalyticalApproximations` | `rlComputeAnalyticalApproximations` | Compatibility wrapper; not formally deprecated. |
| `tracking/` | `solveFundamentalBranch` | `rlSolveFundamentalBranch` | Compatibility wrapper; not formally deprecated. |

## Recommended user-facing entrypoints

For new user-facing Rayleigh-Lamb code, start with these primary `rl*` entrypoints:

- `rlDefaultParams`
- `rlDefaultOptions`
- `rlComputeFundamentalLambModes`
- `rlComputeAnalyticalApproximations`

These names should be preferred for maintained examples, documentation, application code, and analysis scripts that need to call the base Rayleigh-Lamb implementation directly.

## Internal/helper entrypoints

Residual, validation, geometry/material, frequency-vector, branch-spec, and tracking helpers are maintained but primarily support the higher-level entrypoints listed above.

Direct calls to these helpers may be appropriate for focused diagnostics, tests, or advanced workflows, but routine users should generally start from `rlDefaultParams`, `rlDefaultOptions`, `rlComputeFundamentalLambModes`, and `rlComputeAnalyticalApproximations`.

## Deprecated or not-yet-deprecated names

A lightweight static audit in `tests/run_all_smoke_tests.m` checks maintained MATLAB code for old-name function-call patterns and helps keep new maintained call sites on the primary `rl*` API. The audit deliberately does not make the legacy wrappers deprecated; it only prevents accidental maintained-code usage outside compatibility or legacy contexts.


The old top-level names are compatibility wrappers and should not be used in new maintained code, but they remain available for existing scripts and downstream workflows.

These compatibility names are not formally deprecated unless a separate policy, release note, or migration document explicitly marks a specific function as deprecated.

## Notes for future migration

Physical file migration is deferred until compatibility policy requirements are satisfied and the existing minimal A0/S0 numerical regression smoke fixtures are considered sufficient for the migration scope.

Future migration work should preserve compatibility wrappers, avoid changing numerical behavior unintentionally, and keep public API guidance synchronized with this table and the legacy wrapper policy.
