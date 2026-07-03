# Execution Profile Surface Integration

## Summary

This phase integrates the centralized `executionProfile` infrastructure into the
three user-facing surfaces without changing equations, physical defaults,
optimizer options, branch policies, or maintained mRLFE routes.

Visible surface defaults are now:

| Surface | Default execution profile |
| --- | --- |
| `LambFundamental_GUI` | `Balanced` |
| `SweepTool_GUI` | `Fast` |
| `FitTool_GUI` | `Fast` |

The historical `robustness` field remains a compatibility alias. New GUI-facing
code should prefer `executionProfile` in requests and metadata.

## Support Matrix

| Model | Main GUI | SweepTool | FitTool |
| --- | --- | --- | --- |
| Rayleigh-Lamb | `Fast`, `Balanced`, `Robust` fully supported through `rlDefaultOptions` | `Fast`, `Balanced`, `Robust` fully supported; default `Fast` | `Fast`, `Balanced`, `Robust` fully supported; default `Fast` |
| AE IOP/HGO | `Fast`, `Balanced`, `Robust` map to AE atlas density; default `Balanced` | `Fast`, `Balanced`, `Robust` exposed and mapped to AE atlas density; default `Fast` | `Fast`, `Balanced`, `Robust` mapped to AE atlas density; default `Fast` |
| mRLFE | requested profile recorded; maintained fast GUI atlas preset remains effective | requested profile recorded; maintained fast GUI sweep route remains effective; default `Fast` | requested profile recorded; `fast_fit_atlas` remains effective; default `Fast` |

AE profile mapping remains:

| Profile | `atlasNumYPoints` | `atlasTopNMinima` |
| --- | ---: | ---: |
| `Fast` | 300 | 12 |
| `Balanced` | 600 | 16 |
| `Robust` | 900 | 20 |

## Metadata

Adapters and normalized outputs preserve the existing metadata contract where
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
optimizerProfile
supportedExecutionProfiles
profileSupportMode
surfaceDefaultExecutionProfile
```

For fully supported RL and AE cases, `requestedExecutionProfile` and
`effectiveExecutionProfile` match. For mRLFE non-Fast requests, the requested
value is preserved and the effective value is reported as `Fast` with
`profileSupportMode = "mapped_to_fast"`.

## Overrides Removed

The normal FitTool AE path no longer forces atlas density to 300/12 after the
user selects `Balanced` or `Robust`. The selected execution profile now controls
atlas density in:

- synthetic data generation;
- fitting evaluation;
- normalized fit metadata.

`atlasInitializationNumFrequencyPoints = 50` remains a FitTool fitting-control
choice and is not treated as an execution-profile override.

## Overrides Preserved

The following behaviors are deliberate and remain explicit:

- mRLFE Main GUI keeps `fast_viscous`, `fast_zero_viscosity_adaptive`, or
  `elastic_reference` internal presets depending on the route.
- mRLFE SweepTool keeps the maintained GUI fast atlas route.
- mRLFE FitTool keeps `fast_fit_atlas`.
- Legacy AE Fit requests that explicitly supply `atlasNumYPoints` and
  `atlasTopNMinima` can still override profile-derived density. Metadata reports
  the resulting effective profile and a nonempty override reason.

## Route Policies

Execution profile remains separate from route policy. This phase does not
change:

- mRLFE `adaptivePhysicalTail`;
- mRLFE `delayedCut`;
- zero-viscosity adaptive atlas/fallback;
- viscous unified atlas;
- AE `atlasA0`;
- fallback policies.

Optimizer options also remain separate from solver and atlas profile selection.

## Manual GUI Checklist

Main GUI:

- selector starts at `Balanced`;
- Rayleigh-Lamb reports requested/effective `Balanced`;
- AE reports requested/effective `Balanced`;
- mRLFE reports requested `Balanced`, effective `Fast`, and the fast internal
  preset when the maintained fast atlas route is used.

SweepTool:

- selector starts at `Fast` for RL, mRLFE, and AE;
- AE selector includes `Robust`;
- AE `Robust` resolves to 900/20;
- exported output preserves execution profile metadata.

FitTool:

- selector starts at `Fast`;
- changing model restores that model's `Fast` default;
- Restore model defaults returns the selected model to `Fast`;
- AE `Balanced` and `Robust` change atlas density to 600/16 and 900/20;
- mRLFE reports `fast_fit_atlas` when fitting through the maintained atlas fit
  route.

## Tests

Surface integration coverage is grouped in:

```matlab
run_execution_profile_surface_tests
```

It covers:

- defaults by surface;
- alias compatibility;
- RL direct profile equivalence;
- AE atlas density mapping on Sweep/Fit paths;
- mRLFE mapped-to-Fast metadata;
- legacy AE Fit atlas-density override metadata.

`run_gui_smoke_tests` includes the fast surface integration contract without
turning the smoke suite into a benchmark.

## Regression Benchmark Smoke

The short regression benchmark is:

```matlab
run_execution_profile_regression_smoke('WriteCsv', false)
```

Representative run on the PR validation machine:

| Model | Case | Requested | Effective | Internal preset | Elapsed seconds | Valid fraction | Metadata OK |
| --- | --- | --- | --- | --- | ---: | ---: | --- |
| RL | A0 short | `Fast` | `Fast` | `Fast` | 0.366 | 1.00 | true |
| mRLFE | zero-viscosity adaptive atlas | `Robust` | `Fast` | `fast_fit_atlas` | 0.708 | 1.00 | true |
| AE | atlasA0 short | `Robust` | `Robust` | `ae_atlas_900x20` | 4.79 | 1.00 | true |
| AE Fit | atlasA0 robust short | `Robust` | `Robust` | `ae_atlas_900x20` | 35.0 | 1.00 | true |

These timings are descriptive only and are not enforced as hardware-dependent
thresholds.

## Remaining Work

- Add richer per-curve execution profile metadata for multi-case sweep exports
  if downstream consumers need point-level auditability.
- Add named optimizer profiles in a later phase.
- Decide whether to hide unsupported mRLFE non-Fast choices on selected
  surfaces or keep the current requested/effective metadata representation.
- Complete manual GUI review using the checklist above.
