# Execution Profile Diagnostics Validation

This document defines the active diagnostic contract for execution profiles in
the GUI surfaces after the end-to-end hardening pass.

Historical migration documents remain under `docs/architecture/`. This file is
the current user-facing interpretation guide for diagnostics.

## Common Contract

Diagnostics distinguish three levels:

| Level | Meaning |
| --- | --- |
| Control value | The value shown or entered in the GUI control. |
| Requested execution profile | The canonical value after resolving `executionProfile` and the legacy `robustness` alias. |
| Effective execution profile | The profile actually applied by the maintained backend path. |

The shared formatter is:

```matlab
guiFormatExecutionProfileDiagnostics
```

It is presentation-only. It does not resolve profiles and does not run solvers.

The standard sections are:

```text
Execution profile
  surface:
  model:
  control value:
  requested:
  effective:
  source:
  support mode:
  override applied:
  override reason:

Internal configuration
  solver preset:
  atlas preset:
  route policy:
  actual route:
  effective numerical settings:

Result
  visible branch:
  valid points:
  elapsed time:
  fallback:
```

Internal non-applicable metadata fields continue to use the empty string `""`.
Human-readable diagnostics display those as `not applicable`.

## Rayleigh-Lamb

Rayleigh-Lamb diagnostics expose profile-dependent settings including:

- `gridPointsInitial`;
- `gridPointsTracking`;
- `jumpTol`;
- `searchFactors`;
- `mrlfeGridPoints`;
- `mrlfeComplexMaxIter`;
- `mrlfeComplexMaxFunEvals`.

This makes Fast, Balanced, and Robust visibly distinguishable without dumping
the full options structure.

Expected profile behavior:

| Requested | Effective | Route policy |
| --- | --- | --- |
| `Fast` | `Fast` | `direct` |
| `Balanced` | `Balanced` | `direct` |
| `Robust` | `Robust` | `direct` |

## AE IOP/HGO

AE diagnostics expose atlas settings directly:

| Requested | Effective | Atlas preset | Atlas points/minima | Route policy |
| --- | --- | --- | --- | --- |
| `Fast` | `Fast` | `ae_atlas_300x12` | `300 / 12` | `atlasA0` |
| `Balanced` | `Balanced` | `ae_atlas_600x16` | `600 / 16` | `atlasA0` |
| `Robust` | `Robust` | `ae_atlas_900x20` | `900 / 20` | `atlasA0` |

The diagnostics are intended to make the effective atlas resolution visible
without requiring the user to infer it from elapsed time.

The physical defaults remain unchanged:

```text
rho = 1060 kg/m^3
rhoF = 1000 kg/m^3
fluidBulkModulus = 2.2 GPa
R = 7.8 mm
thickness = 0.55 mm
IOP = 15 mmHg
mu = 64 kPa
k1 = 50 kPa
k2 = 200
```

## mRLFE

mRLFE diagnostics show direct requested/effective behavior:

```text
requested: Balanced
effective: Balanced
support mode: direct
solver preset: balanced
override applied: false
```

Fast, Balanced, and Robust map to the public `fast`, `balanced`, and `robust`
presets on Main, Sweep, and Fit surfaces. Fit objective evaluations retain the
selected preset metadata while using the bounded `fitOptimized` grid.

The diagnostic contract also reports:

- actual route;
- A0 policy;
- `etaS`;
- fallback;
- elapsed time;
- valid points.

The profile must not change route policy, fallback, or branch termination.

## Surface Differences

### Main GUI

The `Show diagnostics` action reports the common contract plus material and
geometry fields. The former ambiguous wording in the control/options section
has been replaced by:

```text
control execution profile:
normalized requested profile:
control profile source:
```

### SweepTool

After each sweep, the status area reports:

- number of sweep cases;
- valid cases;
- requested/effective profile;
- support mode;
- internal preset;
- route policy or actual route where available;
- elapsed time;
- AE atlas settings;
- mRLFE mapping/fallback details.

The same metadata remains in `SweepToolOutput` and `SweepToolNormalized`.

### FitTool

After synthetic generation, FitTool reports synthetic profile diagnostics.

After fitting, FitTool reports:

- fit elapsed time;
- fitted-curve elapsed time;
- requested/effective profile;
- internal atlas/solver preset;
- route;
- valid points;
- AE atlas settings;
- mRLFE requested/effective public preset and engine, with no hidden profile override.

The fitted curve also preserves:

```matlab
FitToolLastOutput.normalized.fullCurve.executionProfile
```

## Validation

Run:

```matlab
clear; clc; close all;
startup
run_execution_profile_diagnostics_tests
```

This covers:

- common format fields;
- unambiguous requested/effective/control wording;
- RL effective settings;
- AE atlas settings;
- mRLFE direct-profile presentation;
- the bounded structural mRLFE benchmark contract.
