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

`mrlfeResolveSolveFrequencyGrid` applies the following precedence:

1. `numerics.frequencySolveOverride_Hz`, when explicitly supplied for diagnostics;
2. the resolved numerical preset grid policy.

An override must cover the complete requested interval and is reported as `diagnosticOverride`. Production grids are reported as `numericalPreset`.

## Metadata

`problem.frequencyGrid` retains the established fields:

- `source`
- `pointCount`
- `fmin_Hz`
- `fmax_Hz`
- `minStep_Hz`
- `medianStep_Hz`
- `maxStep_Hz`

and adds:

- `presetName`
- `configuredStep_Hz`
- `lowFrequencyPolicy`
- `transitionFrequency_Hz`

## Validation basis

The selected production steps were obtained from the quick validation matrix using:

- a 10 Hz dense reference;
- candidate steps of 20, 25, 30, 40, 50, 75, and 100 Hz;
- elastic and viscous cases;
- requested upper bounds of 16 and 32 kHz;
- accepted-tail comparison based on formal termination when available, otherwise the accepted last-valid frequency before `fmax`.

The controlling accepted viscous case selected:

- `fast = 50 Hz` under a 10% tail-error target;
- `balanced = 25 Hz` under a 5% tail-error target;
- `robust = 20 Hz` under a 3% tail-error target.

The extended parameter matrix remains a non-blocking validation task. Therefore these values are production defaults supported by the completed quick matrix, not a claim of global optimality over every possible material and geometry combination.

## Contracts

The implementation preserves these contracts:

- Main GUI, SweepTool, and FitTool continue to call the same public solver route.
- `result.frequency_Hz` remains identical to `request.frequency_Hz`.
- The exact diagnostic override remains available.
- `dense` remains the maintained reference preset.
- Tracker and robust-start implementations are unchanged by this grid-policy update.

## Tests

Run:

```matlab
clear; clc;
startup
run_mrlfe_production_core_tests
```

The suite includes:

- `test_mrlfe_production_core_presets`
- `test_mrlfe_numerical_preset_grids`
- `test_mrlfe_solve_frequency_override`

The dedicated grid test verifies the four configured steps, low-frequency anchors, requested bounds, strict ordering, override precedence, unsupported-name rejection, and preservation of the public output grid.
