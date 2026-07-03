# Execution Profile End-to-End Validation

This document records the final validation and hardening pass for the
`executionProfile` migration across `LambFundamental_GUI`, `SweepTool_GUI`,
and `FitTool_GUI`.

The historical audit and migration documents remain under
`docs/architecture/`. This document describes the current validation contract
after PRs #99-#102 and the final hardening pass.

## Scope

Validated surfaces:

- `LambFundamental_GUI` headless adapters;
- `SweepTool_GUI` request builder, dispatcher, adapters, and normalized output;
- `FitTool_GUI` request builder, fitting adapters, normalized output, and fitted
  curve metadata.

Validated model scenarios:

- Rayleigh-Lamb `A0`;
- mRLFE `A0Like`, `etaS = 0`;
- mRLFE `A0Like`, `etaS > 0`;
- AE IOP/HGO `atlasA0`.

Validated profiles:

- `Fast`;
- `Balanced`;
- `Robust`.

## Reproducible Matrix

Run:

```matlab
clear; clc; close all;
startup
matrix = validateExecutionProfileMatrix('WriteCsv', false);
```

The matrix includes these columns:

| Column | Meaning |
| --- | --- |
| `Surface` | Main GUI, SweepTool, or FitTool headless workflow. |
| `Model` | Rayleigh-Lamb, mRLFE, or AE IOP/HGO. |
| `Scenario` | Branch and mRLFE viscosity scenario. |
| `RequestedProfile` | Canonical requested execution profile. |
| `EffectiveProfile` | Profile that was actually applied. |
| `SupportMode` | `fully_supported` or `mapped_to_fast`. |
| `InternalSolverPreset` | Solver preset, or `""` when not applicable. |
| `InternalAtlasPreset` | Atlas preset, or `""` when not applicable. |
| `RoutePolicy` | Physical route or branch policy, separate from profile. |
| `ProfileOverrideApplied` | True when requested/effective differ. |
| `ProfileOverrideReason` | Stable reason; empty string when no override exists. |
| `ExecutionProfileSource` | Source recorded by normalization. |
| `ResultValidity` | Metadata contract and override contract passed. |
| `NumericalOutputAvailable` | At least one finite positive Cp value was produced. |
| `ExportMetadataAvailable` | Metadata survives in exportable app output. |
| `SyntheticFittingApplicability` | FitTool synthetic/fit/fitted-curve coverage. |
| `Notes` | Route and numerical-difference notes. |
| `ElapsedSeconds` | Informational timing, no hardware threshold. |

The matrix is also covered by:

```matlab
run_execution_profile_end_to_end_tests
```

## Validated Behavior

### Rayleigh-Lamb

Rayleigh-Lamb is fully supported for all three profiles across Main, SweepTool,
and FitTool:

| Requested | Effective | Internal solver preset | Route policy |
| --- | --- | --- | --- |
| `Fast` | `Fast` | `Fast` | `direct` |
| `Balanced` | `Balanced` | `Balanced` | `direct` |
| `Robust` | `Robust` | `Robust` | `direct` |

The validated paths delegate to `rlDefaultOptions(profile)` and do not alter
solver values.

### AE IOP/HGO

AE IOP/HGO is fully supported for all three profiles across Main, SweepTool,
and FitTool:

| Requested | Effective | Atlas preset | Route policy |
| --- | --- | --- | --- |
| `Fast` | `Fast` | `ae_atlas_300x12` | `atlasA0` |
| `Balanced` | `Balanced` | `ae_atlas_600x16` | `atlasA0` |
| `Robust` | `Robust` | `ae_atlas_900x20` | `atlasA0` |

The final validation confirms that FitTool no longer silently collapses
Balanced or Robust to 300/12 unless explicit legacy atlas-density controls are
provided by the caller.

### mRLFE

mRLFE intentionally remains mapped to maintained fast atlas routes:

| Surface | Scenario | Requested | Effective | Internal atlas preset | Route |
| --- | --- | --- | --- | --- | --- |
| Main | `etaS = 0` | `Fast` | `Fast` | `fast_zero_viscosity_adaptive` | `zero_viscosity_adaptive_atlas` or fallback |
| Main | `etaS > 0` | `Fast` | `Fast` | `fast_viscous` | `viscous_unified_atlas` |
| SweepTool | `etaS = 0` | non-Fast | `Fast` | `fast_zero_viscosity_adaptive` | `adaptivePhysicalTail` route policy |
| SweepTool | `etaS > 0` | non-Fast | `Fast` | `fast_viscous` | `adaptivePhysicalTail` route policy |
| FitTool | any mRLFE fit scenario | non-Fast | `Fast` | `fast_fit_atlas` | actual atlas evaluation path |

Non-Fast mRLFE requests are not errors. They are explicit mapped cases with:

- `profileSupportMode = "mapped_to_fast"`;
- `profileOverrideApplied = true`;
- a stable nonempty `profileOverrideReason`.

No new dense mRLFE profiles, routes, or fallbacks were introduced.

## Bugs Found and Corrected

### mRLFE Sweep alias conflict

Reproducible case:

```matlab
guiRunSweep(guiBuildSweepRequest("mrlfe", ...
    'branchName', "A0Like", ...
    'sweepField', "mu", ...
    'sweepValuesDisplay', 75, ...
    'displayScale', 1e3, ...
    'controls', struct('executionProfile', "Balanced", 'etaS', 0)))
```

Observed before hardening:

- the mRLFE sweep resolver kept `executionProfile = "Balanced"` but passed
  `robustness = "Fast"` into the main adapter;
- the shared normalizer correctly rejected the contradictory aliases before
  running the solver.

Fix:

- `mrlfeResolveExecutionProfile` now preserves `robustness` as the requested
  compatibility alias and records the effective Fast behavior in metadata.

Numerical effect:

- no route, equation, atlas preset, or solver tolerance was changed.

### Main Rayleigh-Lamb metadata completion

Observed before hardening:

- Main Rayleigh-Lamb adapter metadata did not include the final support fields:
  `supportedExecutionProfiles`, `profileSupportMode`, and
  `surfaceDefaultExecutionProfile`.

Fix:

- `guiRunRayleighLambModel` now records the same minimum metadata contract used
  by the other surfaces.

Numerical effect:

- no Rayleigh-Lamb options or output values were changed.

### FitTool fitted-curve metadata survival

Observed before hardening:

- `fitOutput.executionProfile` and `fitOutput.normalized.executionProfile`
  existed, but `fitOutput.normalized.fullCurve` did not preserve the same
  metadata.

Fix:

- the RL, mRLFE, and AE FitTool adapters now attach the same execution-profile
  metadata to `normalized.fullCurve.executionProfile`.

Numerical effect:

- fitted curve generation is unchanged; only metadata is copied.

## Numerical Comparisons

The end-to-end runner uses short deterministic cases and compares fitted values
against the synthetic values used to construct the request. The latest run
reported finite numerical outputs for every matrix row.

Representative maximum absolute fit-minus-synthetic differences from the
validated run:

| Case | Max absolute difference |
| --- | ---: |
| RL Fit A0 Fast/Balanced | about `0.276 m/s` |
| RL Fit A0 Robust | about `0.276 m/s` |
| mRLFE Fit `etaS = 0` | about `0.039 m/s` |
| mRLFE Fit `etaS > 0` | about `0.042 m/s` |
| AE Fit Fast | about `0.011 m/s` |
| AE Fit Balanced | about `0.008 m/s` |
| AE Fit Robust | about `0.015 m/s` |

These short fits intentionally use very small optimizer budgets. They validate
route/profile consistency and metadata survival, not parameter-recovery
quality.

## Export and Metadata

Validated metadata locations:

- Main adapter result: `result.metadata.executionProfile`;
- Sweep output: `sweepOutput.executionProfile`;
- Sweep normalized export object:
  `sweepOutput.normalized.metadata.executionProfile`;
- Fit output: `fitOutput.executionProfile`;
- Fit normalized output: `fitOutput.normalized.executionProfile`;
- Fitted curve: `fitOutput.normalized.fullCurve.executionProfile`.

The convention for non-applicable fields remains the empty string `""`.

## Benchmark Smoke

Use the maintained short benchmark:

```matlab
clear; clc; close all;
startup
run_execution_profile_regression_smoke
```

The benchmark reports elapsed time, valid fraction, requested/effective
profile, and metadata status for representative RL, mRLFE, AE, and AE Fit
cases. It has no hardware-dependent pass/fail timing threshold.

## Current Limitations

- The validation is headless; it does not prove visual widget layout or manual
  click behavior.
- mRLFE Balanced and Robust remain mapped to Fast by design.
- FitTool tests use short optimizer budgets to keep validation practical.
- Full physical validation and experimental parameter recovery remain covered
  by the fitting validation suite, not by this execution-profile matrix.

## Maintained Runners

Minimum final validation:

```matlab
clear; clc; close all;
startup
run_execution_profile_infrastructure_tests
run_execution_profile_surface_tests
run_execution_profile_cleanup_tests
run_execution_profile_end_to_end_tests
run_gui_smoke_tests
run_mrlfe_fit_atlas_tests
run_acoustoelastic_smoke_tests
run_execution_profile_regression_smoke
```
