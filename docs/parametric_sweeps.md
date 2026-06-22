# Parametric sweeps

This document summarizes the maintained parametric sweep workflow for the Lamb Fundamental Solver.

The sweep tools are intended for quick sensitivity studies of Rayleigh-Lamb and mRLFE branches. They reuse the same backend as the GUI where applicable and export plotted curves plus quantitative validity summaries.

## Sweep script locations

Maintained mRLFE sweep wrappers live under:

```text
examples/mrlfe/sweeps/
```

Maintained mRLFE sweep scripts:

```text
examples/mrlfe/sweeps/sweep_viscosity_A0Like_viscoelastic.m
examples/mrlfe/sweeps/sweep_viscosity_S0Like_viscoelastic.m
examples/mrlfe/sweeps/sweep_stiffness_A0Like_viscoelastic.m
examples/mrlfe/sweeps/sweep_stiffness_S0Like_viscoelastic.m
examples/mrlfe/sweeps/sweep_thickness_A0Like_viscoelastic.m
examples/mrlfe/sweeps/sweep_thickness_S0Like_viscoelastic.m
```

The maintained Rayleigh-Lamb thickness sweep wrapper lives under:

```text
examples/rayleigh_lamb/basic/sweep_thickness_A0_S0.m
```

The Rayleigh-Lamb manual validation script lives under:

```text
examples/rayleigh_lamb/validation/check_default_outputs.m
```

Because `startup.m` adds maintained example folders recursively, these scripts can be called directly by function/script name after running `startup`.

## Core sweep utilities

The generic sweep functions are located in `analysis/`:

```matlab
analysis/runParametricSweep
analysis/plotParametricSweepCp
analysis/summarizeParametricSweepBranch
```

### `runParametricSweep`

Runs the solver repeatedly while changing one scalar parameter.

The swept parameter can be either:

1. a field in `params`, for example `E` or `thickness`; or
2. a field in `options.mrlfeParams`, for example `etaS`.

Minimal pattern:

```matlab
sweepSpec = struct();
sweepSpec.parameter = "etaS";
sweepSpec.values = [0, 0.01, 0.05, 0.10];
sweepSpec.label = "etaS";
sweepSpec.units = "Pa*s";
sweepSpec.displayScale = 1;

sweepResults = runParametricSweep(params, options, sweepSpec);
```

### `plotParametricSweepCp`

Plots `Cp(f)` for one model/branch pair extracted from the sweep results.

Examples:

```matlab
plotParametricSweepCp(sweepResults, "mRLFEHanViscoRealK", "A0Like", ...
    "Title", "Viscoelastic A0-like Cp sensitivity to etaS", ...
    "ShowLastValidPoint", true);

plotParametricSweepCp(sweepResults, "RayleighLamb", "A0", ...
    "Title", "Rayleigh-Lamb A0 thickness sweep");
```

The option `ShowLastValidPoint` marks the last valid `Cp` point on each curve. This is useful for conservative real-k branches because curves may terminate before the requested `fmax`.

### `summarizeParametricSweepBranch`

Creates a table summarizing branch validity and range for each sweep case.

Examples:

```matlab
sweepSummary = summarizeParametricSweepBranch(sweepResults, ...
    "mRLFEHanViscoRealK", "A0Like");

a0Summary = summarizeParametricSweepBranch(sweepResults, ...
    "RayleighLamb", "A0");
```

The summary table includes:

```text
CaseIndex
ParameterValue
DisplayValue
ValidCpPoints
TotalPoints
FirstValidFrequency_Hz
LastValidFrequency_Hz
MaxValidFrequency_Hz
BranchFmax_Hz
ReachedFmax
MinCp_mps
MaxCp_mps
FirstValidCp_mps
LastValidCp_mps
ElapsedSeconds
```

## mRLFE sweep helper layer

The public mRLFE sweep scripts are short wrappers. Shared setup lives in:

```text
analysis/mrlfe/
```

Current helper layer:

```matlab
mrlfeDefaultSweepParams
mrlfeDefaultSweepOptions
mrlfeMakeSweepSpec
mrlfeRunSweepExample
```

Use the wrappers for normal execution:

```matlab
sweep_viscosity_A0Like_viscoelastic
sweep_viscosity_S0Like_viscoelastic
sweep_stiffness_A0Like_viscoelastic
sweep_stiffness_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

Use the helper only when creating or adapting a maintained sweep:

```matlab
[sweepResults, sweepSummary] = mrlfeRunSweepExample( ...
    "viscosity", "A0Like", "AssignToBase", true);
```

The helper layer centralizes reference parameters, solver options, sweep values, plotting, summaries, and workspace-output names. It does not change the mRLFE solver, equations, or branch-tracking logic.

## Rayleigh-Lamb sweep helper layer

The maintained Rayleigh-Lamb thickness sweep wrapper is:

```matlab
sweep_thickness_A0_S0
```

It delegates to:

```matlab
rlRunThicknessSweepExample
```

The helper lives under:

```text
analysis/rayleigh_lamb/
```

It computes A0 and S0 on the preserved thickness grid:

```matlab
thickness = [0.1 0.2 0.3 0.4 0.5] mm
```

and assigns these workspace outputs when called through the public wrapper:

```matlab
RayleighLambThicknessSweepResults
RayleighLambThicknessSweepA0Summary
RayleighLambThicknessSweepS0Summary
```

## Maintained mRLFE sweep scripts

Run all scripts from the repository root after `startup`.

### Shear viscosity sweeps

```matlab
sweep_viscosity_A0Like_viscoelastic
sweep_viscosity_S0Like_viscoelastic
```

These sweep:

```matlab
etaS = [0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50] Pa*s
```

Fixed reference settings:

```text
E = 475 kPa
thickness = 0.5 mm
nu = 0.4999
rho = 1070 kg/m^3
fluidDensity = 1000 kg/m^3
fluidSoundSpeed = 1500 m/s
frequency range = 100 to 16000 Hz
frequency spacing = hybrid
robustness preset = Fast
```

Workspace outputs:

```matlab
ViscositySweepResults
ViscositySweepSummary
ViscositySweepS0LikeResults
ViscositySweepS0LikeSummary
```

### Stiffness sweeps

```matlab
sweep_stiffness_A0Like_viscoelastic
sweep_stiffness_S0Like_viscoelastic
```

These sweep:

```matlab
E = [50, 100, 300, 500, 1000, 1500] kPa
```

Fixed reference settings:

```text
etaS = 0.05 Pa*s
thickness = 0.5 mm
nu = 0.4999
rho = 1070 kg/m^3
fluidDensity = 1000 kg/m^3
fluidSoundSpeed = 1500 m/s
frequency range = 100 to 16000 Hz
frequency spacing = hybrid
robustness preset = Fast
```

Workspace outputs:

```matlab
StiffnessSweepA0LikeResults
StiffnessSweepA0LikeSummary
StiffnessSweepS0LikeResults
StiffnessSweepS0LikeSummary
```

### Thickness sweeps

```matlab
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

These sweep:

```matlab
thickness = [0.3, 0.5, 0.7, 1.0] mm
```

Fixed reference settings:

```text
E = 475 kPa
etaS = 0.05 Pa*s
nu = 0.4999
rho = 1070 kg/m^3
fluidDensity = 1000 kg/m^3
fluidSoundSpeed = 1500 m/s
frequency range = 100 to 16000 Hz
frequency spacing = hybrid
robustness preset = Fast
```

Workspace outputs:

```matlab
ThicknessSweepA0LikeResults
ThicknessSweepA0LikeSummary
ThicknessSweepS0LikeResults
ThicknessSweepS0LikeSummary
```

## Interpreting sweep plots and summaries

### Valid curves

The plotted curves use the branch validity mask. Invalid points are replaced by `NaN`, so curves may terminate before `fmax`.

For Han viscoelastic real-k branches, this is expected behavior. It means the conservative modal-local tracker did not find a valid real-k local minimum satisfying the branch constraints beyond that point.

### Last valid point marker

When `ShowLastValidPoint` is enabled, each curve includes a circular marker at the last valid `Cp` point.

Interpretation:

```text
Marker at fmax:
    The branch reached the requested maximum frequency.

Marker before fmax:
    The branch was cut before fmax. Use the summary table to read the exact maximum valid frequency.
```

### `ReachedFmax`

The summary table column `ReachedFmax` is `true` when the maximum valid frequency reaches the branch frequency maximum.

Use it to compare sweep cases quantitatively instead of relying only on the plot.

### Conservative branch cuts

For `mRLFEHanViscoRealK`, a branch cut should not be interpreted as a plotting error. The real-k viscoelastic path is intentionally conservative:

1. it does not extrapolate from the seed;
2. it does not jump to the global low-Cp valley;
3. it stops when the modal-local real-k minimum is not reliable.

## Creating a new sweep

A new one-parameter mRLFE sweep should usually add or update metadata in:

```matlab
mrlfeMakeSweepSpec
```

and expose a short wrapper under:

```text
examples/mrlfe/sweeps/
```

A new Rayleigh-Lamb sweep should keep the public script under:

```text
examples/rayleigh_lamb/basic/
```

and move reusable setup into:

```text
analysis/rayleigh_lamb/
```
