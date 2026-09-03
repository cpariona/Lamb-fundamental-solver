# Rayleigh-Lamb public API

```matlab
params = rlDefaultParams;
opts = rlDefaultOptions;
result = rlComputeFundamentalLambModes(params, opts);
approx = rlComputeAnalyticalApproximations(params, result.frequency_Hz);
```

The solver owns fundamental A0/S0 computation only. mRLFE may request an RL
seed, but RL does not expose mRLFE flags or routes.

Maintained examples are:

```matlab
run_default_A0_S0
fit_default_A0
rl_sweep_thickness_A0
```

Reusable analysis uses `rlFitDispersionData` and `rlRunSweep`. Contract,
smoke, numerical, and fitting coverage is distributed across the six canonical
validation tiers.
