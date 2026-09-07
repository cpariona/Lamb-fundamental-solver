# Rayleigh-Lamb public API

```matlab
params = lamb.models.rayleigh_lamb.rlDefaultParams;
opts = lamb.models.rayleigh_lamb.rlDefaultOptions("Balanced");
opts.computeS0 = true;
result = lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(params, opts);
approx = lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations( ...
    result.configuration.effective.parameters.frequency_Hz, result.material, result.geometry);
```

Physical inputs use SI: shear modulus `mu` (Pa), Poisson ratio `nu`,
density `rho` (kg/m3), and full `thickness` (m). The default material
formulation is `ShearPoisson`; `LameParameters` supports explicit Lame
formulation checks. Frequency controls are `fmin`, `fmax` (Hz),
`numFrequencyPoints`, and `frequencySpacing`.

`lamb.models.rayleigh_lamb.rlDefaultOptions` accepts Fast, Balanced, or Robust. It owns branch toggles,
search grids, continuation, residual and jump tolerances. Defaults compute A0
only; enable S0 explicitly. Public defaults live in
`src/+lamb/+models/+rayleigh_lamb/rlDefaultParams.m` and
`src/+lamb/+models/+rayleigh_lamb/rlDefaultOptions.m`. Frequency construction and
validation live under `src/+lamb/+models/+rayleigh_lamb/+configuration/`.

## Result and limitations

`result.modes.A0` / `result.modes.S0` contain enabled branches with
`frequency_Hz`, `phaseVelocity_mps`, `wavenumber_radpm`, and
`validMask`. Quality is evaluated by `lamb.models.rayleigh_lamb.quality.rlEvaluateModeQuality` and exposed under
`result.quality` by the result builder. The result also contains material,
geometry, analytical approximations, diagnostics, operational execution
metadata, and requested/effective configuration. There is no top-level
frequency alias.

Requested and effective configuration use the common envelope:

```matlab
result.configuration.requested.parameters
result.configuration.requested.options
result.configuration.effective.parameters
result.configuration.effective.options
```

This is an isotropic elastic plate solver for fundamental A0/S0, not a
higher-mode, viscous, or fluid-loaded solver. Low-frequency analytical
approximations are separate estimates, not replacements for tracked roots.
RL never calls mRLFE; mRLFE may request an RL seed.

The maintained inverse API is `lamb.fitting.rayleigh_lamb.rlFitDispersionData`.
Parameter campaigns are opt-in studies, not model APIs.
Examples are executed by path, for example:

```matlab
run('examples/rayleigh_lamb/basic/run_default_A0_S0.m')
```

See `overview.md` for algorithm ownership and `fitting_workflow.md` for
the fitting-grid contract.
