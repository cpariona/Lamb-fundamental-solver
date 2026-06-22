# Rayleigh-Lamb sweep helper status

This note records the current Rayleigh-Lamb sweep-helper layer.

## Scope

The Rayleigh-Lamb solver remains on the maintained `rl*` API. This sweep cleanup does not change Rayleigh-Lamb equations, branch tracking, tolerances, or core output structures. It only aligns the public sweep example with the AE and mRLFE example structure.

## Public sweep wrapper

The maintained thickness sweep entrypoint is:

```matlab
sweep_thickness_A0_S0
```

It lives under:

```text
examples/rayleigh_lamb/basic/
```

The validation script remains under:

```text
examples/rayleigh_lamb/validation/check_default_outputs.m
```

## Helper layer

The public thickness sweep wrapper delegates to:

```matlab
rlRunThicknessSweepExample
```

Reusable Rayleigh-Lamb sweep helpers live under:

```text
analysis/rayleigh_lamb/
```

Current helpers:

```matlab
rlDefaultSweepParams
rlDefaultSweepOptions
rlMakeSweepSpec
rlRunThicknessSweepExample
rlOutputFolder
rlWriteSweepOutputs
rlSaveExampleFigure
```

They reuse the generic sweep utilities:

```matlab
runParametricSweep
plotParametricSweepCp
summarizeParametricSweepBranch
```

## Current maintained sweep

The maintained Rayleigh-Lamb sweep varies full thickness:

```matlab
2h = [0.3, 0.4, 0.5, 0.6, 0.7] mm
```

with fixed elastic reference:

```text
mu = 75 kPa
E = 3*mu = 225 kPa
nu = 0.4999
rho = 1070 kg/m^3
CL = 1500 m/s
fmin = 100 Hz
fmax = 16000 Hz
frequencySpacing = hybrid
robustness preset = Balanced
```

The helper computes both `A0` and `S0`:

```matlab
options.computeA0 = true;
options.computeS0 = true;
```

## Outputs

Data/workspace outputs are written under:

```text
Results/rayleigh_lamb/thickness_sweep/
```

Figures are written next to the script under:

```text
examples/rayleigh_lamb/basic/figures/thickness_sweep/
```

Each branch figure is saved as both `.fig` and `.png`.

## Validation commands

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup

sweep_thickness_A0_S0
check_default_outputs
run_all_smoke_tests
```
