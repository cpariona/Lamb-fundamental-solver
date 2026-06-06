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

At high frequencies, the Rayleigh-Lamb and mRLFE residual landscapes can contain multiple nearby minima. The current solver uses modal scoring to reduce branch switching, but A0-like mRLFE can still encounter competing residual valleys in very soft materials or high-viscosity cases.

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

## mRLFE solver workflow

The mRLFE real-k models are solved using an intentionally chained workflow:

```text
Rayleigh-Lamb A0/S0
    -> mRLFE elastic real-k A0-like/S0-like
        -> mRLFE Han viscoelastic real-k A0-like/S0-like
```

This is more expensive than solving each model independently, but it is more robust because the simpler models provide branch references for the more complex ones.

Real-k mRLFE tracking uses modal scoring. The score penalizes both the singular-value residual and the distance from the reference branch. This prevents the tracker from automatically jumping to a lower-residual valley that belongs to another modal family.

The current strategy is conservative: when a local residual minimum consistent with the modal reference is not found, the branch is cut instead of silently plotting the seed/reference curve as a solution.

## Current validated working ranges

These ranges are based on the current diagnostic scripts and default geometry `thickness = 0.5 mm`, `nu = 0.4999`, and `CL = 1500 m/s`. They should be rechecked when geometry, fluid parameters, or material assumptions change.

### Elastic mRLFE real-k, etaS = 0

For the current 16 kHz diagnostic range:

```text
S0-like:
    E = 50 to 1500 kPa -> stable to 16 kHz.

A0-like:
    E >= 300 kPa      -> stable to 16 kHz.
    E = 225 kPa       -> safe to about 15.0 kHz.
    E = 150 kPa       -> safe to about 12.3 kHz.
    E = 100 kPa       -> safe to about 10.2 kHz.
    E = 75 kPa        -> safe to about 8.9 kHz.
    E = 50 kPa        -> safe to about 7.2 kHz.
```

`SafeFmax_Hz` is defined in `examples/stress_test_mrlfe_elastic_range.m` as the frequency before the first valid Cp jump larger than the configured jump threshold. The current threshold is:

```matlab
largeJumpThreshold = 0.15;
```

These limits do not mean that no mathematical residual minimum exists above the safe frequency. They mean that the tracked A0-like curve may undergo branch switching and should not be used for fitting without additional modal validation.

### Han viscoelastic mRLFE real-k

For the current 8 kHz sweep:

```text
etaS <= 0.7 Pa*s:
    A0-like and S0-like remained valid to 8 kHz for the tested default material.

etaS = 1.0 Pa*s:
    A0-like remained valid to about 7.9 kHz.
    S0-like remained valid to about 7.4 kHz.
```

For fitting, use only points where the branch validity mask is true and avoid extrapolating across branch cuts.

## Branch-switching roadmap

A0-like branch switching in soft elastic mRLFE remains an active issue. The current modal scoring reduces the problem but does not fully solve it for low stiffness and high frequency. The intended next improvements are:

1. Extract multiple local residual minima at every frequency, not only inside diagnostic scripts.
2. Track candidate branches globally using a dynamic-programming or Viterbi-style path cost.
3. Penalize residual, curvature, jump size, and distance from Rayleigh-Lamb or previous mRLFE references.
4. Preserve several candidate A0-like paths internally instead of forcing a single branch too early.
5. Select the final plotting/fitting branch from the candidate family using continuity and physical constraints.

Until this is implemented, `SafeFmax_Hz` should be treated as the practical cutoff for A0-like elastic fitting in soft-material cases.

## mRLFE diagnostic workflow

Use these diagnostics when extending the solver beyond the current safe range:

```matlab
examples/diagnose_mrlfe_a0_candidates
examples/diagnose_mrlfe_etaS1_transition
examples/diagnose_mrlfe_etaS1_local_candidates
examples/diagnose_mrlfe_elastic_soft_range_candidates
examples/stress_test_mrlfe_elastic_range
examples/stress_test_mrlfe_parameter_space
```

`diagnose_mrlfe_a0_candidates` extracts local residual minima and groups them into candidate branches. It is useful because high-frequency A0-like behavior can contain multiple residual valleys. A candidate branch should not be treated as a physical mode until it is continuous, stable under parameter changes, and benchmarked.

`stress_test_mrlfe_elastic_range` sweeps elastic stiffness to 16 kHz and writes:

```text
mRLFE_elastic_range_stability_summary.csv
```

This table includes `SafeFmax_Hz`, `FirstLargeJumpRelative`, and jump locations for each branch and stiffness.

`diagnose_mrlfe_elastic_soft_range_candidates` inspects the low-stiffness elastic cases and writes:

```text
mRLFE_elastic_soft_jump_summary.csv
mRLFE_elastic_soft_local_candidate_minima.csv
mRLFE_elastic_soft_local_candidate_branches.csv
mRLFE_elastic_soft_local_candidate_branch_summary.csv
```

For routine review, the most useful exported files are:

```text
mRLFE_elastic_range_stability_summary.csv
mRLFE_elastic_soft_jump_summary.csv
mRLFE_elastic_soft_local_candidate_branch_summary.csv
mRLFE_han_visco_sweep_summary.csv
mRLFE_A0_candidate_branch_table.csv
mRLFE_stress_test_table.csv
```

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
examples/compare_mrlfe_elastic_vs_han_visco_cp
examples/stress_test_mrlfe_elastic_range
examples/diagnose_mrlfe_elastic_soft_range_candidates
examples/diagnose_mrlfe_a0_candidates
examples/diagnose_mrlfe_etaS1_transition
examples/diagnose_mrlfe_etaS1_local_candidates
examples/stress_test_mrlfe_parameter_space
```

`check_default_outputs` prints valid point counts, Cp ranges, residuals, and finite `kThickness` counts for the default configuration.

`sweep_thickness_A0_S0` computes A0 and experimental S0 over multiple total thickness values and plots the corresponding Cp curves.

`run_mrlfe_prototype` computes Rayleigh-Lamb A0/S0 and the elastic real-k mRLFE A0-like/S0-like prototype branches over a moderate frequency range.

`run_mrlfe_complexk_prototype` computes the experimental complex-k mRLFE prototype and reports Cp and spatial attenuation.

`sweep_mrlfe_viscosity` sweeps solid shear viscosity in the experimental complex-k path. This is kept for advanced diagnostics only.

`sweep_mrlfe_shear_viscosity_phase_velocity` sweeps solid shear viscosity in the Han-style real-k model and plots only Cp dispersion curves.

`compare_mrlfe_elastic_vs_han_visco_cp` compares elastic real-k and Han viscoelastic real-k phase velocity, and plots the relative Cp shift caused by etaS.

`stress_test_mrlfe_elastic_range` estimates the current safe frequency range for elastic real-k fitting across a broad stiffness sweep.

`diagnose_mrlfe_elastic_soft_range_candidates` inspects the remaining A0-like branch-switching issue in soft elastic cases.

## Current limitations

- S0 is implemented but should be treated as experimental until benchmarked against a trusted reference.
- mRLFE complex-k is a prototype and attenuation is not yet validated for quantitative fitting.
- High-frequency fundamental-branch tracking can show branch-switching artifacts in difficult ranges.
- A0-like mRLFE in soft materials can contain multiple residual candidate branches; the current GUI still plots only one tracked branch.
- A0-like branch switching above `SafeFmax_Hz` remains unresolved and must be addressed before fitting low-stiffness A0-like data at high frequency.
- Group velocity is not implemented yet.
- Modal structure and displacement animations are not implemented yet.
- Higher modes such as A1 and S1 are not implemented yet.
