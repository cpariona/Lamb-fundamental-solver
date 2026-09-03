# Rayleigh-Lamb public API

```matlab
params = rlDefaultParams;
opts = rlDefaultOptions("Balanced");
opts.computeS0 = true;
result = rlComputeFundamentalLambModes(params, opts);
approx = rlComputeAnalyticalApproximations( ...
    result.configuration.effective.frequency_Hz, result.material, result.geometry);
```

Physical inputs use SI: shear modulus `mu` (Pa), Poisson ratio `nu`,
density `rho` (kg/m3), and full `thickness` (m). The default material
formulation is `ShearPoisson`; `LameParameters` supports explicit Lame
formulation checks. Frequency controls are `fmin`, `fmax` (Hz),
`numFrequencyPoints`, and `frequencySpacing`.

`rlDefaultOptions` accepts Fast, Balanced, or Robust. It owns branch toggles,
search grids, continuation, residual and jump tolerances. Defaults compute A0
only; enable S0 explicitly. The exact defaults live in
`models/rayleigh_lamb/core/rlDefaultParams.m` and
`models/rayleigh_lamb/core/rlDefaultOptions.m`.

## Result and limitations

`result.modes.A0` / `result.modes.S0` contain enabled branches with
`frequency_Hz`, `phaseVelocity_mps`, `wavenumber_radpm`, and
`validMask`. Quality is owned by `rlBuildResult` under `result.quality`.
The result also contains material, geometry, analytical approximations,
diagnostics, operational execution metadata, and requested/effective
configuration. There is no top-level frequency alias.

This is an isotropic elastic plate solver for fundamental A0/S0, not a
higher-mode, viscous, or fluid-loaded solver. Low-frequency analytical
approximations are separate estimates, not replacements for tracked roots.
RL never calls mRLFE; mRLFE may request an RL seed.

Reusable analysis APIs are `rlFitDispersionData` and `rlRunSweep`.
Examples are executed by path, for example:

```matlab
run('examples/rayleigh_lamb/basic/run_default_A0_S0.m')
```

See `overview.md` for algorithm ownership and `fitting_workflow.md` for
the fitting-grid contract.
