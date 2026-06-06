# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

Current scope:

- A0 phase velocity calculation using the antisymmetric Rayleigh-Lamb residual.
- Experimental S0 phase velocity calculation using the symmetric Rayleigh-Lamb residual.
- Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
- mRLFE elastic real-k dispersion for fluid-loaded layers, including a multicandidate dynamic-programming tracker for A0-like soft-material cases.
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

Important mRLFE options added during the current development cycle include:

```matlab
options.mrlfeA0UseDPTracker
options.mrlfeA0DPCandidates
options.mrlfeA0DPCpScanPoints
options.mrlfeA0DPValidationMaxRelativeKDrift
options.mrlfeA0DPValidationMaxRelativeCpDrift
options.mrlfeA0DPValidationMaxCpJumpRelative
options.mrlfeA0DPValidationMaxCpPredictionError
```

For the production elastic A0-like real-k path, the DP tracker is enabled internally by `computeFundamentalLambModes` through `makeElasticRealKOptions`.

## Frequency grid and tracking notes

The GUI uses an automatic internal hybrid frequency grid. The grid combines logarithmic sampling at low frequency with linear sampling at higher frequency, so the user only needs to specify `fmin` and `fmax`.

At high frequencies, the Rayleigh-Lamb and mRLFE residual landscapes can contain multiple nearby minima. The current elastic A0-like mRLFE solver uses a multicandidate dynamic-programming tracker to suppress branch switching in soft-material cases. Han-style viscoelastic real-k branches still use the modal/local tracker and remain under active diagnosis for high-viscosity, low-stiffness cases.

When plotting against `wavenumber` or `kThickness`, different modes may end at different horizontal values because `k = omega / Cp` is mode-dependent. This does not mean that a branch was truncated in frequency.

## mRLFE dispersion models

The main GUI now focuses on phase-velocity dispersion, not attenuation.

The implemented mRLFE paths are:

- `mRLFEElasticRealK`: elastic, fluid-loaded, real-k dispersion. A0-like uses a multicandidate dynamic-programming tracker; S0-like uses the real-k modal tracker.
- `mRLFEHanViscoRealK`: Han-style viscoelastic, fluid-loaded, real-k dispersion. This path uses real lambda and complex shear modulus, and is still being diagnosed for high-viscosity validity limits.
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

For elastic A0-like mRLFE, the production solver now performs an additional preliminary local/modal A0-like solve and uses that branch only as a guide for the candidate scan range. The final A0-like branch is selected by `models/mrlfe/solveMRLFEBranchDP.m`, which extracts multiple local residual candidates at each frequency and chooses a globally smooth path using a dynamic-programming cost. The path cost penalizes residual, jump size, curvature, and distance from the modal reference.

Real-k S0-like and Han viscoelastic branches use modal scoring. The score penalizes both the singular-value residual and the distance from the reference branch. This prevents the tracker from automatically jumping to a lower-residual valley that belongs to another modal family.

The current strategy is conservative: when a local residual minimum consistent with the modal reference is not found, the branch is cut instead of silently plotting the seed/reference curve as a solution.

## Current validated working ranges

These ranges are based on the current diagnostic scripts and default geometry `thickness = 0.5 mm`, `nu = 0.4999`, and `CL = 1500 m/s`. They should be rechecked when geometry, fluid parameters, or material assumptions change.

### Elastic mRLFE real-k, etaS = 0

For the current 16 kHz diagnostic range:

```text
A0-like:
    E = 50 to 1500 kPa -> stable to 16 kHz.

S0-like:
    E = 50 to 1500 kPa -> stable to 16 kHz.
```

`SafeFmax_Hz` is defined in `examples/stress_test_mrlfe_elastic_range.m` as the frequency before the first valid Cp jump larger than the configured jump threshold. The current threshold is:

```matlab
largeJumpThreshold = 0.15;
```

The previous A0-like soft-material branch-switching issue was resolved for this tested range by the integrated DP tracker. The validation used:

```text
f = 500 to 16000 Hz
E = 50, 75, 100, 150, 225, 300, 400, 500, 750, 1000, 1500 kPa
thickness = 0.5 mm
nu = 0.4999
CL = 1500 m/s
```

### Han viscoelastic mRLFE real-k

The Han-style real-k path has been stress-tested to 16 kHz using:

```text
E = 50, 100, 300, 500, 1000, 1500 kPa
etaS = 0, 0.01, 0.05, 0.1, 0.3, 0.5, 0.7, 1.0 Pa*s
thickness = 0.5 mm
nu = 0.4999
CL = 1500 m/s
```

With the current validity criteria, the maximum etaS values that reached 16 kHz without warnings were approximately:

```text
A0-like:
    E = 50 kPa    -> etaS <= 0.01 Pa*s
    E = 100 kPa   -> etaS <= 0.01 Pa*s
    E = 300 kPa   -> etaS <= 0.1  Pa*s
    E = 500 kPa   -> etaS <= 0.1  Pa*s
    E = 1000 kPa  -> etaS <= 0.5  Pa*s
    E = 1500 kPa  -> etaS <= 1.0  Pa*s

S0-like:
    E = 50 kPa    -> etaS <= 0.01 Pa*s
    E = 100 kPa   -> etaS <= 0.01 Pa*s
    E = 300 kPa   -> etaS <= 0.1  Pa*s
    E = 500 kPa   -> etaS <= 0.1  Pa*s
    E = 1000 kPa  -> etaS <= 0.3  Pa*s
    E = 1500 kPa  -> etaS <= 0.7  Pa*s
```

For fitting, use only points where the branch validity mask is true and avoid extrapolating across branch cuts. For higher etaS, lower E, or higher frequency, the Han real-k residual landscape can be dominated by a low-Cp edge valley. The physical branch should be identified only through mode-relevant local minima, not through the global residual minimum.

## Branch-switching roadmap

The elastic A0-like branch-switching problem in soft mRLFE cases has been addressed for the current 16 kHz test range by `solveMRLFEBranchDP.m` and the chained elastic workflow. The active branch-tracking roadmap now focuses on Han-style viscoelastic real-k cases:

1. Ignore the global low-Cp edge valley when it is not mode-relevant.
2. Extract local residual minima at every frequency.
3. Filter local minima by branch-specific modal windows:
   - A0-like: broad modal window around the reference branch.
   - S0-like: stricter modal window to avoid confusing A0-like minima with S0-like minima.
4. Continue Han real-k branches only while a mode-relevant local minimum exists.
5. When no mode-relevant real-k minimum exists, cut the branch and report the real-k validity limit.
6. Use complex-k diagnostics to test whether the missing real-k minimum corresponds to a regime where spatial attenuation is essential.

The current conclusion is that Han viscoelastic real-k does not need the same global DP strategy used for elastic A0-like. It needs a modal-local tracker that rejects the low-Cp residual valley and cuts the branch when the mode-relevant local minimum disappears.

## mRLFE diagnostic workflow

Use these diagnostics when extending the solver beyond the current safe range:

```matlab
examples/check_default_outputs
examples/run_mrlfe_prototype
examples/stress_test_mrlfe_elastic_range
examples/prototype_mrlfe_a0_multicandidate_tracker
examples/stress_test_mrlfe_han_visco_range
examples/prototype_mrlfe_han_visco_a0_multicandidate_tracker
examples/diagnose_mrlfe_han_visco_validity_breakdown
examples/diagnose_mrlfe_han_visco_residual_landscape
```

`prototype_mrlfe_a0_multicandidate_tracker` compares the integrated elastic A0-like solver against a standalone best-residual path and a dynamic-programming multicandidate path. It was used to validate that the integrated solver now matches the DP path across `E = 50 to 1500 kPa` up to 16 kHz.

`stress_test_mrlfe_elastic_range` sweeps elastic stiffness to 16 kHz and writes:

```text
mRLFE_elastic_range_stability_summary.csv
```

This table includes `SafeFmax_Hz`, `FirstLargeJumpRelative`, and jump locations for each branch and stiffness.

`stress_test_mrlfe_han_visco_range` sweeps stiffness and shear viscosity for the Han real-k model and writes:

```text
mRLFE_han_visco_range_stability_summary.csv
```

This table identifies which combinations of `E`, `etaS`, and branch remain valid to 16 kHz.

`prototype_mrlfe_han_visco_a0_multicandidate_tracker` compares the current Han A0-like solver, a best-residual path, and a DP candidate path. It showed that a global DP path does not reliably fix Han viscoelastic branch loss, because the residual landscape can be dominated by a low-Cp edge valley or lose its mode-relevant local minimum.

`diagnose_mrlfe_han_visco_validity_breakdown` separates invalid points by residual, reference, smoothness, and non-finite Cp masks. It showed that many high-viscosity/low-stiffness Han real-k cuts occur because Cp becomes non-finite rather than because a later validation gate rejects an otherwise valid point.

`diagnose_mrlfe_han_visco_residual_landscape` scans the real-k residual around observed validity cuts and writes:

```text
mRLFE_han_visco_residual_landscape_summary.csv
mRLFE_han_visco_residual_landscape_samples.csv
```

This diagnostic distinguishes the global low-Cp residual valley from mode-relevant local minima using branch-specific modal windows. The current branch-specific windows are:

```text
A0-like: 0.35 to 2.50 times modal reference Cp
S0-like: 0.70 to 1.40 times modal reference Cp
```

For routine review, the most useful exported files are:

```text
mRLFE_elastic_range_stability_summary.csv
mRLFE_A0_multicandidate_summary.csv
mRLFE_han_visco_range_stability_summary.csv
mRLFE_han_visco_A0_multicandidate_summary.csv
mRLFE_han_visco_validity_breakdown.csv
mRLFE_han_visco_residual_landscape_summary.csv
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
examples/prototype_mrlfe_a0_multicandidate_tracker
examples/stress_test_mrlfe_han_visco_range
examples/prototype_mrlfe_han_visco_a0_multicandidate_tracker
examples/diagnose_mrlfe_han_visco_validity_breakdown
examples/diagnose_mrlfe_han_visco_residual_landscape
```

`check_default_outputs` prints valid point counts, Cp ranges, residuals, and finite `kThickness` counts for the default configuration.

`sweep_thickness_A0_S0` computes A0 and experimental S0 over multiple total thickness values and plots the corresponding Cp curves.

`run_mrlfe_prototype` computes Rayleigh-Lamb A0/S0 and the elastic real-k mRLFE A0-like/S0-like prototype branches over a moderate frequency range.

`run_mrlfe_complexk_prototype` computes the experimental complex-k mRLFE prototype and reports Cp and spatial attenuation.

`sweep_mrlfe_viscosity` sweeps solid shear viscosity in the experimental complex-k path. This is kept for advanced diagnostics only.

`sweep_mrlfe_shear_viscosity_phase_velocity` sweeps solid shear viscosity in the Han-style real-k model and plots only Cp dispersion curves.

`compare_mrlfe_elastic_vs_han_visco_cp` compares elastic real-k and Han viscoelastic real-k phase velocity, and plots the relative Cp shift caused by etaS.

`stress_test_mrlfe_elastic_range` validates the current elastic real-k fitting range across a broad stiffness sweep.

`prototype_mrlfe_a0_multicandidate_tracker` validates the elastic A0-like DP branch tracker against standalone candidate paths.

`stress_test_mrlfe_han_visco_range` estimates the current safe frequency range for Han viscoelastic real-k fitting across stiffness and viscosity sweeps.

`prototype_mrlfe_han_visco_a0_multicandidate_tracker` diagnoses whether a DP candidate path helps Han A0-like real-k tracking. Current results indicate that global DP is not the correct fix for Han visco branch loss.

`diagnose_mrlfe_han_visco_validity_breakdown` and `diagnose_mrlfe_han_visco_residual_landscape` diagnose why Han real-k branches terminate and whether a mode-relevant local minimum still exists.

## Development status summary

Current project state:

```text
Elastic mRLFE real-k:
    A0-like and S0-like are stable to 16 kHz for E = 50 to 1500 kPa
    under the current default diagnostic geometry.

Han viscoelastic mRLFE real-k:
    Works for low etaS and/or higher stiffness.
    At higher etaS, lower E, or higher frequency, branches can terminate
    because the mode-relevant real-k local minimum disappears or becomes
    ambiguous relative to a low-Cp residual valley.

Complex-k mRLFE:
    Still experimental. It is the likely next diagnostic path for regimes
    where Han real-k no longer has a mode-relevant local minimum.
```

Latest implemented code changes:

```text
models/mrlfe/solveMRLFEBranchDP.m
    Added production multicandidate dynamic-programming tracker for elastic A0-like mRLFE.

models/mrlfe/computeMRLFE.m
    Elastic A0-like DP tracker is seeded by a preliminary real-k branch used only to guide candidate scan range.

core/computeFundamentalLambModes.m
    Elastic real-k mRLFE enables A0 DP tracking internally.

core/defaultOptions.m
    Added A0 DP tracker and DP-specific validation options.

examples/stress_test_mrlfe_han_visco_range.m
examples/prototype_mrlfe_han_visco_a0_multicandidate_tracker.m
examples/diagnose_mrlfe_han_visco_validity_breakdown.m
examples/diagnose_mrlfe_han_visco_residual_landscape.m
    Added diagnostics for Han viscoelastic real-k stability, branch tracking, validity masks, and residual landscapes.
```

Open problems:

```text
1. Han viscoelastic real-k needs a modal-local tracker that filters local minima by branch-specific windows.
2. S0-like remains experimental and needs benchmarking against a trusted reference.
3. Complex-k attenuation is not validated for quantitative fitting.
4. The physical interpretation of high-viscosity real-k branch termination must be tested with complex-k diagnostics.
5. The examples folder still contains historical diagnostics that should be reorganized after Han visco tracking is stabilized.
```

Recommended next tasks:

```text
1. Implement Han real-k modal-local tracking using branch-specific modal windows.
2. Re-run stress_test_mrlfe_han_visco_range after the modal-local tracker is implemented.
3. Add a focused complex-k diagnostic for cases where the Han real-k modal minimum disappears.
4. Benchmark S0-like against a trusted Rayleigh-Lamb/fluid-loaded reference.
5. Organize examples into stable validation scripts, demos, and diagnostics archive after the viscoelastic path is stabilized.
```

## Current limitations

- S0 is implemented but should be treated as experimental until benchmarked against a trusted reference.
- mRLFE complex-k is a prototype and attenuation is not yet validated for quantitative fitting.
- Han viscoelastic real-k can terminate at high etaS, low E, or high frequency when no mode-relevant local minimum is found.
- The global minimum of the Han real-k residual can be a low-Cp edge valley and should not be interpreted as the physical branch.
- The examples folder contains several historical diagnostics from solver development and should be reorganized after Han visco tracking is stabilized.
- Group velocity is not implemented yet.
- Modal structure and displacement animations are not implemented yet.
- Higher modes such as A1 and S1 are not implemented yet.
