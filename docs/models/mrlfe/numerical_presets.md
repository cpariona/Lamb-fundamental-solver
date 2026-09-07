# mRLFE numerical frequency-grid presets

## Scope

The production mRLFE solver exposes four numerical presets:

| Preset | Internal step above 500 Hz | Role |
|---|---:|---|
| `fast` | 50 Hz | Reduced-cost production solving |
| `balanced` | 25 Hz | Intermediate production accuracy |
| `robust` | 20 Hz | Fine production accuracy |
| `dense` | 10 Hz | Dense/reference and diagnostic solving |

These steps control the internal tracking grid only. The public output remains evaluated on `request.frequency_Hz`.

## Grid policy

All production presets use the same hybrid frequency policy:

```matlab
lowFrequencyAnchors_Hz = [ ...
    10:10:100, ...
    125:25:250, ...
    300:50:500].';
```

The configured preset step is applied from 500 Hz to the requested upper bound. The exact requested lower and upper bounds are always included, and the final solve grid is finite, positive, unique, and strictly ascending.

The policy is identified as:

```text
fixedLowAnchorsConstantHighStep
```

## Resolution precedence

`lamb.models.mrlfe.core.mrlfeResolveSolveFrequencyGrid` applies:

1. `numerics.frequencySolveOverride_Hz`, when explicitly supplied for diagnostics;
2. the resolved numerical preset grid policy.

An override must cover the complete requested interval and is reported as `diagnosticOverride`. Production grids are reported as `numericalPreset`.

## Metadata

`problem.frequencyGrid` records source, point count, bounds, step statistics, preset name, configured step, low-frequency policy, and transition frequency.

## Validation basis

The presets were initially selected from a quick matrix against the 10 Hz dense reference. The controlling accepted viscous cases supported:

- `fast = 50 Hz` under the quick-matrix 10% tail target;
- `balanced = 25 Hz` under the 5% target;
- `robust = 20 Hz` under the 3% target.

The extended parameter matrix completed on 2026-07-14. Aggregate preset status was reported as failed because some dense-reference cases were already marginal and did not satisfy all matrix targets. Their reference quality included `low_valid_fraction` and `large_relative_jump`.

A targeted follow-up evaluated the cases responsible for those failures with 10 Hz references and 20/25 Hz candidates. It found:

- no accepted dense-reference solution that degraded under the candidate grids;
- small median and P95 differences over the common valid region in the usable cases;
- large pointwise differences confined to already invalid or marginal branch tails;
- grid-sensitive quality labels near the termination of marginal solutions.

Therefore the maintained interpretation is:

1. preset equivalence is blocking only when the dense reference is itself accepted;
2. marginal reference cases remain diagnostic and do not independently reject a preset;
3. the 50/25/20 Hz production presets remain approved;
4. the extended matrix is evidence of the solver's validity envelope, not evidence that every material/geometry combination has a trustworthy branch.

## FitTool objective grid

FitTool optimizer evaluations do not use the full numerical-preset grid. They use the separate `fitOptimized` policy:

```matlab
minimumPointCount = 12;
maximumPointCount = 40;
maximumStep_Hz = 250;
```

This policy preserves experimental frequencies and adds bounded continuation points. The explicit **Evaluate fitted curve** action switches back to `numericalPreset` and uses the selected Fast, Balanced, or Robust profile.

The lightweight characterization measured approximately 3.0x to 4.3x speedup for objective evaluations, with a worst observed relative phase-speed difference of 0.121% and no valid-mask differences in the tested cases.

## Contracts

- Main GUI, FitTool, and mRLFE sensitivity studies call the public solver route.
- `result.frequency_Hz` remains identical to `request.frequency_Hz`.
- Diagnostic frequency overrides remain available.
- `dense` remains the maintained reference preset.
- FitTool normalization does not automatically run a dense or preset solver evaluation.
- Full fitted curves are evaluated only on explicit user request.

## Tests and diagnostics

```matlab
run_extended_integration_tests
run_performance_and_benchmark_tests
```

For bounded manual diagnostic follow-up:

```matlab
run('studies/solver_diagnostics/mrlfe/investigate_mrlfe_grid_presets.m')
```

Do not add the extended full matrix to lightweight smoke runners.
