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

Reference values: `mu = 70 kPa`, `etaS = 0.05 Pa*s`, `2h = 0.5 mm`, `fmin = 100 Hz`, `fmax = 16000 Hz`.

Sweep values:

```matlab
mu = [60, 65, 70, 75, 80] kPa
etaS = [0, 0.1, 0.2, 0.3, 0.4, 0.5] Pa*s
thickness = [0.3, 0.4, 0.5, 0.6, 0.7] mm
```

Outputs follow the AE example pattern: data under `Results/mrlfe/<taskName>/` and figures under `examples/mrlfe/sweeps/figures/<taskName>/` as `.fig` and `.png`.
