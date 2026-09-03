# Execution Profile Surface Integration

## Summary

The centralized `executionProfile` infrastructure is integrated across the three
user-facing surfaces without changing equations, physical defaults, optimizer
options, or branch policies.

Visible surface defaults are:

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
| Rayleigh-Lamb | `Fast`, `Balanced`, `Robust` supported through `rlDefaultOptions` | all three profiles supported; default `Fast` | all three profiles supported; default `Fast` |
| AE IOP/HGO | all three profiles map to AE atlas density; default `Balanced` | all three profiles map to AE atlas density; default `Fast` | all three profiles map to AE atlas density; default `Fast` |
| mRLFE | all three profiles map directly to the matching public numerical preset; default `Balanced` | all three profiles map directly to the matching public numerical preset; default `Fast` | all three profiles map directly to the matching public numerical preset; default `Fast` |

AE profile mapping remains:

| Profile | `atlasNumYPoints` | `atlasTopNMinima` |
| --- | ---: | ---: |
| `Fast` | 300 | 12 |
| `Balanced` | 600 | 16 |
| `Robust` | 900 | 20 |

`models/acoustoelastic_iop_hgo/configuration/aeGetNumericalPreset.m` is the
single owner of these values. AE app resolvers normalize the visible profile
and delegate effective configuration to `aeResolveConfiguration`.

mRLFE profile mapping is:

| Execution profile | Public numerical preset |
| --- | --- |
| `Fast` | `fast` |
| `Balanced` | `balanced` |
| `Robust` | `robust` |

The maintained dependency path is:

```text
surface profile resolver
  -> thin surface request wrapper
  -> mrlfeBuildSolveRequest
  -> mrlfeSolve
```

The shared request builder owns physical aliases, scalar/frequency validation,
the selected numerical preset, adaptive selection, branch termination, and
disabled fallback. Adapters do not overwrite the preset after construction.

The model-specific profile resolvers and mRLFE surface metadata builder live in
`app/shared/`. Cross-surface normalization, accepted profile values, and
diagnostic formatting remain at the root of `app/`.

## Metadata

Adapters and normalized outputs preserve the execution-profile metadata contract:

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

For maintained RL, AE, and mRLFE profiles, `requestedExecutionProfile` and
`effectiveExecutionProfile` match. mRLFE reports
`profileSupportMode = "direct"`, the corresponding lowercase public numerical
preset, and no profile override.

Fields that are not applicable use the string scalar `""`. For example,
Rayleigh-Lamb has `internalAtlasPreset = ""`, and AE has
`internalSolverPreset = ""`. When `profileOverrideApplied = false`,
`profileOverrideReason` is `""`.

## Grid and Route Separation

Execution profile remains separate from route policy and fitting grid policy.
For mRLFE:

- Main GUI and SweepTool evaluate the selected public numerical preset directly.
- FitTool optimizer evaluations use `gridPolicy = "fitOptimized"` while retaining
  the selected public preset in metadata.
- Explicit requested fitted-curve evaluation uses
  `gridPolicy = "numericalPreset"`.
- A0Like uses `physicalTail`; S0Like uses `none`.
- fallback remains disabled.

Changing an execution profile must not silently change branch policy, optimizer
options, or fallback behavior.

## Overrides

The normal AE Fit path no longer forces atlas density to 300/12 after the user
selects `Balanced` or `Robust`. The selected profile controls atlas density in
synthetic data generation, fitting evaluation, and normalized fit metadata.

`atlasInitializationNumFrequencyPoints = 50` remains the model default used by
FitTool and is not an execution-profile override.

Legacy AE Fit requests that explicitly supply `atlasNumYPoints` and
`atlasTopNMinima` can still override profile-derived density. Metadata must
report the resulting override explicitly.

## Manual GUI Checklist

Main GUI:

- selector starts at `Balanced`;
- Rayleigh-Lamb reports requested/effective `Balanced`;
- AE reports requested/effective `Balanced`;
- mRLFE reports requested/effective `Balanced`, numerical preset `balanced`,
  direct support, and no profile override.

SweepTool:

- selector starts at `Fast` for RL, mRLFE, and AE;
- all three models expose `Fast`, `Balanced`, and `Robust`;
- mRLFE resolves each selection to the matching lowercase numerical preset;
- exported output preserves execution-profile metadata.

FitTool:

- selector starts at `Fast`;
- changing model restores that model's `Fast` default;
- AE `Balanced` and `Robust` use 600/16 and 900/20 atlas density;
- mRLFE preserves the selected profile while optimizer evaluations use the
  bounded `fitOptimized` grid;
- explicit fitted-curve evaluation uses the selected numerical preset grid.

## Tests

Surface integration coverage is grouped in:

```matlab
run_extended_integration_tests
```

It covers:

- defaults by surface;
- alias compatibility;
- direct profile metadata for RL, AE, and mRLFE;
- AE atlas density mapping;
- mRLFE public numerical preset mapping;
- legacy AE Fit atlas-density override metadata.

`run_quick_smoke_tests` includes lightweight surface contracts without turning the
smoke suite into a benchmark.

Performance benchmarks and full validation matrices remain separate diagnostic
entrypoints because they execute many numerical cases and are not appropriate as
routine smoke tests.

The reproducible cross-surface matrix is:

```matlab
matrix = validateExecutionProfileMatrix('WriteCsv', false);
run_extended_integration_tests
```

The bounded mRLFE profile contract is:

```matlab
[rows, summary] = benchmarkMRLFEExecutionProfiles( ...
    'Mode', "contract", 'RepeatCount', 1, 'WriteCsv', false);
```

Full benchmark mode is descriptive and manual. It has no hardware timing
threshold and writes CSV only when explicitly requested.

## Remaining Work

- Keep the full mRLFE descriptive benchmark outside routine smoke validation;
  the bounded structural contract is owned by execution-profile diagnostics.
- Add richer per-curve execution-profile metadata for multi-case sweep exports if
  downstream consumers need point-level auditability.
- Keep `robustness` as a compatibility alias until all external request
  producers use `executionProfile`.
- Complete manual GUI review using the checklist above when a release requires
  interactive evidence; automated surface and benchmark contracts remain the
  routine gates.
