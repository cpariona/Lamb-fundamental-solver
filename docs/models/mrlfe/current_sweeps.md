# Current mRLFE sweeps

Maintained scripts:

```matlab
mrlfe_sweep_mu_A0Like
mrlfe_sweep_mu_S0Like
mrlfe_sweep_etaS_A0Like
mrlfe_sweep_etaS_S0Like
mrlfe_sweep_thickness_A0Like
mrlfe_sweep_thickness_S0Like
```

Reference values: `mu = 75 kPa`, `etaS = 0.05 Pa*s`, `2h = 0.5 mm`, `fmin = 100 Hz`, `fmax = 16000 Hz`.

Sweep values:

```matlab
mu = [60, 65, 70, 75, 80] kPa
etaS = [0, 0.1, 0.2, 0.3, 0.4, 0.5] Pa*s
2h = [0.3, 0.4, 0.5, 0.6, 0.7] mm
```

The maintained mRLFE sweep parameterization uses `mu` as the primary elastic stiffness input. Derived quantities such as `E`, Lamé parameters, bulk modulus, and wave speeds are computed by the shared material helpers rather than treated as primary soft-material sweep variables.

The maintained etaS > 0 result containers use the normalized model name `mRLFEViscoRealK`; the public sweep entrypoint names do not carry a redundant `_viscoelastic` suffix.

Plots use the shared sweep renderer with a single-line title, frequency in kHz, axes starting at zero, and a right-side information panel for fixed parameters and sweep values. Data are written under `Results/mrlfe/<taskName>/`; figures are written under `examples/mrlfe/sweeps/figures/<taskName>/` as `.fig` and `.png`.

## Cleanup note

The old `sweep_mrlfe_shear_viscosity_phase_velocity` compatibility wrapper is no longer present in the repository. It should not be referenced as a maintained or temporary sweep entrypoint.
