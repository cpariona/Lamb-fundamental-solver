# Rayleigh-Lamb sweep helper status

This note records the current Rayleigh-Lamb sweep-helper layer.

## Scope

The Rayleigh-Lamb solver remains on the maintained `rl*` API. This sweep cleanup does not change Rayleigh-Lamb equations, branch tracking, tolerances, or output structures.

## Public sweep wrapper

The maintained thickness sweep entrypoint remains:

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

The thickness sweep wrapper now delegates to:

```matlab
rlRunThicknessSweepExample
```

The helper lives under:

```text
analysis/rayleigh_lamb/
```

It reuses the generic sweep utilities:

```matlab
runParametricSweep
plotParametricSweepCp
summarizeParametricSweepBranch
```

## Preserved behavior

The helper preserves the previous thickness sweep values:

```matlab
thickness = [0.1 0.2 0.3 0.4 0.5] mm
```

It computes A0 and S0 with:

```matlab
params = rlDefaultParams();
options = rlDefaultOptions("Balanced");
options.computeA0 = true;
options.computeS0 = true;
```

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
