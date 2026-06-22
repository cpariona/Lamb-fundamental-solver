# Current mRLFE sweeps

Maintained scripts:

```matlab
sweep_mu_A0Like_viscoelastic
sweep_mu_S0Like_viscoelastic
sweep_etaS_A0Like_viscoelastic
sweep_etaS_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

Reference values: `mu = 75 kPa`, `etaS = 0.05 Pa*s`, `2h = 0.5 mm`, `fmin = 100 Hz`, `fmax = 16000 Hz`.

Sweep values:

```matlab
mu = [60, 65, 70, 75, 80] kPa
etaS = [0, 0.1, 0.2, 0.3, 0.4, 0.5] Pa*s
2h = [0.3, 0.4, 0.5, 0.6, 0.7] mm
```

The `mu` sweep is displayed as shear modulus but solved internally as `E = 3*mu`. This parameterization cleanup is tracked in `docs/mrlfe/pending_cleanup.md`.

Plots use AE-style two-line titles, frequency in kHz, and axes starting at zero. Data are written under `Results/mrlfe/<taskName>/`; figures are written under `examples/mrlfe/sweeps/figures/<taskName>/` as `.fig` and `.png`.

Legacy compatibility wrapper:

```matlab
sweep_mrlfe_shear_viscosity_phase_velocity
```

This wrapper is retained temporarily because the file still exists under `examples/mrlfe/sweeps/`. It no longer performs the old etaS phase-velocity sweep. It delegates to the maintained full-thickness workflow and runs both A0-like and S0-like sweeps for `2h = [0.3, 0.4, 0.5, 0.6, 0.7] mm` with fixed `mu = 75 kPa` and `etaS = 0.05 Pa*s`.
