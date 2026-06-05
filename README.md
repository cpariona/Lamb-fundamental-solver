# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

Current scope:

- A0 phase velocity calculation using the antisymmetric Rayleigh-Lamb residual.
- Experimental S0 phase velocity calculation using the symmetric Rayleigh-Lamb residual.
- Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
- Real-k elastic mRLFE prototype seeded from Rayleigh-Lamb A0/S0 branches.
- Complex-k mRLFE prototype for spatial attenuation exploration.
- GUI plotting of Cp or spatial attenuation versus frequency, angular frequency, wavenumber, or `kThickness`.
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

The mRLFE implementation is currently a staged prototype:

- It uses the modified Rayleigh-Lamb fluid-loaded 5-by-5 matrix.
- The real-k variant solves an elastic real-wavenumber version of the model.
- The complex-k variant solves for `k = kReal + 1i*kImag` to estimate spatial attenuation.
- It uses the normalized singular-value residual `sigma_min(M) / sigma_max(M)` instead of `det(M)` for better numerical scaling.
- It uses the Rayleigh-Lamb A0/S0 branches, and for complex-k uses the real-k mRLFE branch as a physical reference.
- It reports only fundamental-like branches: `A0Like` and `S0Like`.

Solid viscosity is introduced through complex Lamé parameters, not by assigning viscosity directly to `k`:

```matlab
muStar     = mu     + 1i * omega * etaS;
lambdaStar = lambda + 1i * omega * etaL;
```

The complex wavenumber is a consequence of solving the dispersive problem with complex material parameters and fluid loading. The plotted spatial attenuation is:

```matlab
attenuation = imag(k);
```

This is the guided-mode spatial attenuation `Im(k)` in `[1/m]`; it is not the material viscosity itself and should not be interpreted as water viscosity. Modeling viscous losses in the fluid would require a separate fluid-loss formulation.

## Manual validation examples

Run these from the repository root:

```matlab
examples/run_default_A0
examples/run_default_A0_S0
examples/check_default_outputs
examples/sweep_thickness_A0_S0
examples/run_mrlfe_prototype
examples/run_mrlfe_complexk_prototype
examples/sweep_mrlfe_viscosity
```

`check_default_outputs` prints valid point counts, Cp ranges, residuals, and finite `kThickness` counts for the default configuration.

`sweep_thickness_A0_S0` computes A0 and experimental S0 over multiple total thickness values and plots the corresponding Cp curves.

`run_mrlfe_prototype` computes Rayleigh-Lamb A0/S0 and the real-k elastic mRLFE A0-like/S0-like prototype branches over a moderate frequency range.

`run_mrlfe_complexk_prototype` computes the complex-k mRLFE prototype and reports Cp and spatial attenuation.

`sweep_mrlfe_viscosity` sweeps solid shear viscosity and plots Cp and spatial attenuation for the mRLFE complex-k prototype.

## Current limitations

- S0 is implemented but should be treated as experimental until benchmarked against a trusted reference.
- mRLFE complex-k is a prototype and attenuation is not yet validated for quantitative fitting.
- High-frequency fundamental-branch tracking can show branch-switching artifacts in difficult ranges.
- Group velocity is not implemented yet.
- Modal structure and displacement animations are not implemented yet.
- Higher modes such as A1 and S1 are not implemented yet.
