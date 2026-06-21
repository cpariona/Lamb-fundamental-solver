# mRLFE sweep refactor status

This note records the current mRLFE sweep-helper layer.

## Scope

The refactor keeps the numerical solver and branch-tracking logic unchanged. It only moves repeated sweep setup code out of public example scripts and into reusable helpers.

## Public sweep wrappers

The maintained mRLFE sweep wrappers remain:

```matlab
sweep_viscosity_A0Like_viscoelastic
sweep_viscosity_S0Like_viscoelastic
sweep_stiffness_A0Like_viscoelastic
sweep_stiffness_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

Each wrapper now delegates to:

```matlab
mrlfeRunSweepExample
```

## Helper layer

Reusable mRLFE sweep helpers live under:

```text
analysis/mrlfe/
```

Current helpers:

```matlab
mrlfeDefaultSweepParams
mrlfeDefaultSweepOptions
mrlfeMakeSweepSpec
mrlfeRunSweepExample
```

## Preserved behavior

The helper layer preserves the previous reference values:

```text
E = 475 kPa
thickness = 0.5 mm
nu = 0.4999
rho = 1070 kg/m^3
fluid density = 1000 kg/m^3
fluid sound speed = 1500 m/s
frequency range = 100 to 16000 Hz
frequency spacing = hybrid
robustness preset = Fast
```

The viscosity sweep uses:

```matlab
etaS = [0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50] Pa*s
```

The stiffness sweep uses:

```matlab
E = [50, 100, 300, 500, 1000, 1500] kPa
```

The thickness sweep uses:

```matlab
thickness = [0.3, 0.5, 0.7, 1.0] mm
```

## Validation commands

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup

sweep_viscosity_A0Like_viscoelastic
sweep_viscosity_S0Like_viscoelastic
sweep_stiffness_A0Like_viscoelastic
sweep_stiffness_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic

run_all_smoke_tests
```
