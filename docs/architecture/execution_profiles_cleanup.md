# Execution Profile Cleanup

## Scope

This document closes the execution-profile migration started by the audit and
implemented across the GUI surfaces. It records residual `robustness` usage,
compatibility policy, metadata conventions, and future deprecation guidance.

Historical audit documents remain historical evidence. The active contract is
defined by this document and by:

```text
docs/architecture/execution_profiles_surface_integration.md
```

## Canonical Contract

The canonical app-level field is:

```matlab
executionProfile
```

The historical alias remains supported:

```matlab
robustness
```

Compatibility rules:

1. If only `executionProfile` is present, it is used.
2. If only `robustness` is present, it is canonicalized to `executionProfile`.
3. If both are present and equivalent, the request is accepted.
4. If both are present and contradictory, the request errors.
5. Input is case-insensitive.
6. Output is canonical: `Fast`, `Balanced`, or `Robust`.

No runtime deprecation warning is emitted for normal alias usage in this phase.

## Residual `robustness` Classification

| Category | Locations | Decision |
| --- | --- | --- |
| Public historical API | `rlDefaultOptions(robustness)`, `aeDefaultSweepOptions(robustness)`, stored `options.robustness` compatibility fields | Preserve. These entrypoints are documented and used by examples/tests. |
| GUI legacy fields | `createAdvancedTab`, `createFittingTab`, `SweepTool_GUI` control handles named `robustness` | Preserve handle names to avoid large GUI refactors; visible labels use execution profile wording. |
| Request compatibility | `guiBuildFitRequest`, `guiBuildSweepRequest`, model adapters setting `controls.robustness` | Preserve through `guiNormalizeControlExecutionProfile`; canonical field is also populated. |
| Tests | compatibility, resolver, surface, fitting, sweep, and model tests using `robustness` | Preserve as explicit backward-compatibility coverage. |
| Historical documents | audit and dependency-map documents | Preserve as historical state. Do not rewrite to look current. |
| Active documents | README, SweepTool usage, fitting architecture, surface integration | Updated to name `executionProfile` as canonical and `robustness` as alias. |
| Diagnostics/examples | archived mRLFE diagnostics and benchmark scripts | Preserve unless converting a maintained example would improve clarity without changing behavior. |
| Different meaning | prose such as statistical or optimizer robustness | Leave unchanged; not an execution-profile alias. |

## Duplication Removed

- Canonical profile list is centralized in `guiExecutionProfileValues`.
- Fit and sweep request builders share `guiNormalizeControlExecutionProfile`.
- AE SweepTool atlas density controls are resolved through
  `aeResolveExecutionProfile` instead of repeating the 300/12, 600/16, 900/20
  mapping in the GUI.
- Resolvers and registries use the shared canonical profile list for supported
  profiles.

## Metadata Convention

Execution-profile metadata keeps this minimum contract where profile context is
available:

```matlab
requestedExecutionProfile
effectiveExecutionProfile
executionProfileSource
internalSolverPreset
internalAtlasPreset
profileOverrideApplied
profileOverrideReason
routePolicy
supportedExecutionProfiles
profileSupportMode
surfaceDefaultExecutionProfile
```

Fields that are not applicable use `""`. If `profileOverrideApplied` is false,
`profileOverrideReason` is `""`. Model-specific diagnostic fields outside
`metadata.executionProfile` may retain their established values.

## Defaults Preserved

| Surface | Default |
| --- | --- |
| `LambFundamental_GUI` | `Balanced` |
| `SweepTool_GUI` | `Fast` |
| `FitTool_GUI` | `Fast` |

Model profile behavior remains:

- Rayleigh-Lamb delegates to `rlDefaultOptions`.
- AE IOP/HGO maps `Fast/Balanced/Robust` to 300/12, 600/16, and 900/20.
- mRLFE preserves `fast_viscous`, `fast_zero_viscosity_adaptive`, and
  `fast_fit_atlas`; non-Fast requests are reported as effective `Fast` when the
  maintained fast route is used.

## Future Alias Retirement Plan

Do not remove `robustness` yet. A future deprecation should proceed in this
order:

1. Re-run the residual inventory and include external scripts/examples.
2. Keep one compatibility release where both fields are accepted.
3. Optionally add a non-repeating warning only at high-level app boundaries.
4. Remove the alias only after maintained examples and downstream calls use
   `executionProfile`.

## Manual Checklist

Main GUI:

- default selector is `Balanced`;
- RL and AE report requested/effective `Balanced`;
- mRLFE reports requested `Balanced`, effective `Fast`, and a traceable override.

SweepTool:

- default selector is `Fast`;
- AE exposes `Fast`, `Balanced`, and `Robust`;
- exported output keeps execution-profile metadata.

FitTool:

- default selector is `Fast`;
- Restore model defaults returns to `Fast`;
- AE changes atlas density across 300/12, 600/16, and 900/20;
- mRLFE reports `fast_fit_atlas`.

Compatibility:

- old scripts using `controls.robustness` still run;
- new scripts using `controls.executionProfile` run;
- contradictory fields fail clearly.
