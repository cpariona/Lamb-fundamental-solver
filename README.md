# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

Current scope:

- A0 phase velocity calculation using the antisymmetric Rayleigh-Lamb residual.
- Experimental S0 phase velocity calculation using the symmetric Rayleigh-Lamb residual.
- Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
- mRLFE elastic real-k dispersion for fluid-loaded layers.
- mRLFE Han-style viscoelastic real-k dispersion with real lambda and complex shear modulus.
- Experimental complex-k mRLFE path kept internally for spatial attenuation exploration.
- GUI plotting of phase velocity Cp versus frequency, angular frequency, wavenumber, or `kThickness`.
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

## mRLFE dispersion models

The main GUI now focuses on phase-velocity dispersion, not attenuation.

The implemented mRLFE paths are:

- `mRLFEElasticRealK`: elastic, fluid-loaded, real-k dispersion.
- `mRLFEHanViscoRealK`: Han-style viscoelastic, fluid-loaded, real-k dispersion.
- `mRLFEComplexK`: experimental internal path for spatial attenuation; not part of the main GUI workflow.

All mRLFE variants use the modified Rayleigh-Lamb fluid-loaded 5-by-5 matrix and the normalized singular-value residual:

```matlab
sigma_min(M) / sigma_max(M)
```

instead of `det(M)` for better numerical scaling.

For the Han-style viscoelastic real-k model, lambda is real and shear viscosity enters only through the complex shear modulus:

```matlab
lambdaValue = lambda;
muStar = mu + 1i * omega * etaS;
```

A complex lambda is disabled by default and kept only as an internal future extension using `mrlfeParams.useComplexLambda = true`.

## Attenuation terminology

Use these terms consistently:

- `solid shear viscosity etaS`: material Kelvin-Voigt shear viscosity. It modifies the material shear modulus through `muStar = mu + 1i*omega*etaS`.
- `viscoelastic material damping`: energy loss inside the solid caused by complex material moduli.
- `spatial attenuation Im(k)`: decay of the guided-wave amplitude along propagation, obtained only when solving a complex wavenumber `k = kReal + 1i*kImag`.
- `fluid loading`: change in dispersion caused by the acoustic fluid boundary condition. This can change phase velocity even in a real-k calculation.
- `leaky/radiation attenuation`: possible spatial attenuation due to energy radiated into the surrounding fluid. This requires a validated complex-k formulation and is not currently used for fitting.

The complex-k prototype reports:

```matlab
attenuation = imag(k);
```

but this attenuation is not yet validated for quantitative use.

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
examples/sweep_mrlfe_shear_viscosity_phase_velocity
```

`check_default_outputs` prints valid point counts, Cp ranges, residuals, and finite `kThickness` counts for the default configuration.

`sweep_thickness_A0_S0` computes A0 and experimental S0 over multiple total thickness values and plots the corresponding Cp curves.

`run_mrlfe_prototype` computes Rayleigh-Lamb A0/S0 and the elastic real-k mRLFE A0-like/S0-like prototype branches over a moderate frequency range.

`run_mrlfe_complexk_prototype` computes the experimental complex-k mRLFE prototype and reports Cp and spatial attenuation.

`sweep_mrlfe_viscosity` sweeps solid shear viscosity in the experimental complex-k path. This is kept for advanced diagnostics only.

`sweep_mrlfe_shear_viscosity_phase_velocity` sweeps solid shear viscosity in the Han-style real-k model and plots only Cp dispersion curves.

## Current limitations

- S0 is implemented but should be treated as experimental until benchmarked against a trusted reference.
- mRLFE complex-k is a prototype and attenuation is not yet validated for quantitative fitting.
- High-frequency fundamental-branch tracking can show branch-switching artifacts in difficult ranges.
- Group velocity is not implemented yet.
- Modal structure and displacement animations are not implemented yet.
- Higher modes such as A1 and S1 are not implemented yet.
