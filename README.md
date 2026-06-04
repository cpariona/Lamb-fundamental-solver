# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

Current scope:

- A0 phase velocity calculation using the antisymmetric Rayleigh-Lamb residual.
- Experimental S0 phase velocity calculation using the symmetric Rayleigh-Lamb residual.
- Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
- Real-k elastic mRLFE prototype seeded from Rayleigh-Lamb A0/S0 branches.
- GUI plotting of Cp versus frequency, angular frequency, wavenumber, or `kThickness`.
- Export of `LambResults`, `A0_table`, and, when available, `S0_table` to the MATLAB workspace.

## Naming convention

This project uses explicit thickness naming to avoid ambiguity with classical Rayleigh-Lamb notation:

- `thickness`: total plate thickness.
- `halfThickness`: `thickness / 2`, used internally by Rayleigh-Lamb equations.
- `kThickness`: dimensionless wavenumber, computed as `k * thickness`.

Public GUI labels, exported tables, and result structures should use `thickness` and `kThickness`, not `h`, `kh`, or `kH`.

## Launching the GUI

From the repository root, run:

```matlab
runApp
```

This calls `startup`, adds the project folders to the MATLAB path, and launches the GUI.

Alternatively:

```matlab
startup
LambFundamental_GUI
```

## Defaults and robustness presets

Default physical and frequency parameters are centralized in:

```matlab
core/defaultParams.m
```

Default numerical options and robustness presets are centralized in:

```matlab
core/defaultOptions.m
```

Available robustness presets:

- `Fast`: fewer scan points and faster calculations.
- `Balanced`: default setting for routine exploration.
- `Robust`: more scan points and wider search windows for difficult cases.

The GUI exposes these presets in the `Advanced` tab.

## Frequency grid and tracking notes

The GUI uses an automatic internal hybrid frequency grid. The grid combines logarithmic sampling at low frequency with linear sampling at higher frequency, so the user only needs to specify `fmin` and `fmax`.

At very high frequencies, the Rayleigh-Lamb residual contains many nearby roots and singular features. The current A0/S0 continuation solver is designed for robust fundamental-mode tracking in low-to-mid frequency ranges, but isolated branch-switching artifacts can still occur at high frequency. High-frequency A0/S0 curves should therefore be interpreted with additional care and may require benchmark validation before quantitative use.

When plotting against `wavenumber` or `kThickness`, different modes may end at different horizontal values because `k = omega / Cp` is mode-dependent. This does not mean that a branch was truncated in frequency.

## mRLFE prototype

The mRLFE implementation is currently a first plotting prototype:

- It uses the modified Rayleigh-Lamb fluid-loaded 5-by-5 matrix.
- It solves a real-wavenumber elastic version of the model.
- It uses the normalized singular-value residual `sigma_min(M) / sigma_max(M)` instead of `det(M)` for better numerical scaling.
- It uses the Rayleigh-Lamb A0/S0 branches as seeds.
- It reports only fundamental-like branches: `A0Like` and `S0Like`.

The current mRLFE prototype does not yet solve the full complex-k viscoelastic problem and does not yet report attenuation. Viscosity parameters and complex-k continuation are reserved for a later implementation step.

## Manual validation examples

Run these from the repository root:

```matlab
examples/run_default_A0
examples/run_default_A0_S0
examples/check_default_outputs
examples/sweep_thickness_A0_S0
examples/run_mrlfe_prototype
```

`check_default_outputs` prints valid point counts, Cp ranges, residuals, and finite `kThickness` counts for the default configuration.

`sweep_thickness_A0_S0` computes A0 and experimental S0 over multiple total thickness values and plots the corresponding Cp curves.

`run_mrlfe_prototype` computes Rayleigh-Lamb A0/S0 and the real-k elastic mRLFE A0-like/S0-like prototype branches over a moderate frequency range.

## Current limitations

- S0 is implemented but should be treated as experimental until benchmarked against a trusted reference.
- mRLFE is currently a real-k elastic plotting prototype, not the final complex-k viscoelastic Han-style fitting solver.
- High-frequency fundamental-branch tracking can show branch-switching artifacts in difficult ranges.
- Group velocity is not implemented yet.
- Modal structure and displacement animations are not implemented yet.
- Higher modes such as A1 and S1 are not implemented yet.
