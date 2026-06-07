# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

Current scope:

- A0 phase velocity calculation using the antisymmetric Rayleigh-Lamb residual.
- Experimental S0 phase velocity calculation using the symmetric Rayleigh-Lamb residual.
- Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
- mRLFE elastic real-k dispersion for fluid-loaded layers, including a multicandidate dynamic-programming tracker for A0-like soft-material cases.
- mRLFE Han-style viscoelastic real-k dispersion with real lambda, complex shear modulus, and conservative modal-local Cp-window tracking.
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

The GUI exposes these robustness presets in the `Advanced` tab.

Important current mRLFE options include:

```matlab
options.mrlfeA0UseDPTracker
options.mrlfeA0DPCandidates
options.mrlfeA0DPCpScanPoints
options.mrlfeHanUseModalLocalTracker
options.mrlfeHanA0ModalCpWindow
options.mrlfeHanS0ModalCpWindow
options.mrlfeHanPreviousCpWeight
options.mrlfeHanPreviousCpMaxRelativeJump
```

For the production elastic A0-like real-k path, the DP tracker is enabled internally by `computeFundamentalLambModes` through `makeElasticRealKOptions`.

For the production Han viscoelastic real-k path, the modal-local tracker is enabled internally by `computeFundamentalLambModes` through `makeHanRealKOptions`.

## GUI implementation status

The GUI is implemented for the current phase-velocity workflow:

- Rayleigh-Lamb A0 and experimental S0 can be selected.
- Elastic real-k mRLFE can be selected.
- Han viscoelastic real-k mRLFE can be selected.
- The GUI exposes the main Han material parameter `etaS` and the fluid parameters `fluidDensity` and `fluidSoundSpeed`.
- The GUI plots valid Cp points using each branch validity mask.
- The GUI exports `LambResults`, Rayleigh-Lamb tables, approximation results, `MRLFEElasticRealKResults`, and `MRLFEHanViscoRealKResults`.
- The GUI diagnostics panel reports valid Cp counts and residual summaries for Rayleigh-Lamb, elastic mRLFE, and Han mRLFE branches.

The GUI intentionally does not expose the internal Han tracker tuning options. The branch-specific modal windows, previous-point continuity penalty, and hard Cp-jump cutoff are production defaults in `core/defaultOptions.m` and are applied internally by the backend.

Complex-k attenuation remains hidden from the main GUI because it is still experimental and not validated for quantitative fitting.

## mRLFE dispersion models

The main GUI focuses on phase-velocity dispersion, not attenuation.

The implemented mRLFE paths are:

- `mRLFEElasticRealK`: elastic, fluid-loaded, real-k dispersion. A0-like uses a multicandidate dynamic-programming tracker; S0-like uses the real-k modal tracker.
- `mRLFEHanViscoRealK`: Han-style viscoelastic, fluid-loaded, real-k dispersion. This path uses real lambda, complex shear modulus, branch-specific modal Cp windows, previous-point continuity scoring, and a hard local Cp-jump cutoff.
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

Elastic A0-like mRLFE uses `models/mrlfe/solveMRLFEBranchDP.m`, a multicandidate dynamic-programming path selector designed to suppress branch switching in soft-material cases.

Han viscoelastic real-k uses conservative modal-local tracking:

```text
A0-like modal window: 0.35 to 2.50 times elastic reference Cp
S0-like modal window: 0.70 to 1.40 times elastic reference Cp
```

The stabilized Han tracker also uses:

```matlab
options.mrlfeHanPreviousCpWeight = 80.0;
options.mrlfeHanPreviousCpMaxRelativeJump = 0.18;
```

The current strategy is conservative: when a local residual minimum consistent with the modal reference and previous-point continuity is not found, the branch is cut instead of silently plotting the seed/reference curve or jumping to another local minimum.

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

With the stabilized modal-local and continuity-constrained Han tracker, the maximum etaS values that reached 16 kHz without warnings are approximately:

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

These limits are conservative real-k validity limits. For fitting, use only points where the branch validity mask is true and avoid extrapolating across branch cuts.

## Branch-tracking status

The elastic A0-like branch-switching problem in soft mRLFE cases has been addressed for the current 16 kHz test range by `solveMRLFEBranchDP.m` and the chained elastic workflow.

The Han-style viscoelastic real-k path is now stabilized as a conservative modal-local tracker:

1. Ignore the global low-Cp edge valley when it is not mode-relevant.
2. Extract local residual minima at every frequency.
3. Filter local minima by branch-specific modal windows.
4. Penalize jumps relative to the previous Han point.
5. Reject candidates with relative Cp jumps larger than `0.18`.
6. Continue Han real-k branches only while a mode-relevant continuous local minimum exists.
7. When no such real-k minimum exists, cut the branch and report the real-k validity limit.

The current conclusion is that Han viscoelastic real-k does not need the same global DP strategy used for elastic A0-like. It uses a modal-local tracker that rejects the low-Cp residual valley and cuts the branch when the mode-relevant continuous local minimum disappears.

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

`stress_test_mrlfe_elastic_range` validates the elastic real-k fitting range.

`stress_test_mrlfe_han_visco_range` estimates the conservative safe frequency range for Han viscoelastic real-k fitting across stiffness and viscosity sweeps.

`diagnose_mrlfe_han_visco_validity_breakdown` separates invalid points by residual, reference, smoothness, and non-finite Cp masks. After stabilization, Han real-k cuts are expected to appear primarily as non-finite Cp after the solver rejects non-continuous or non-modal candidates.

`diagnose_mrlfe_han_visco_residual_landscape` distinguishes the global low-Cp residual valley from mode-relevant local minima using branch-specific modal windows.

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

## Development status summary

Current project state:

```text
Elastic mRLFE real-k:
    A0-like and S0-like are stable to 16 kHz for E = 50 to 1500 kPa
    under the current default diagnostic geometry.

Han viscoelastic mRLFE real-k:
    Stabilized as a conservative modal-local real-k tracker.
    Uses branch-specific Cp windows and a hard previous-point Cp jump cutoff.
    Works for low etaS and/or higher stiffness.
    At higher etaS, lower E, or higher frequency, branches terminate when no
    mode-relevant continuous real-k local minimum remains.

Complex-k mRLFE:
    Still experimental. It is the likely next diagnostic path for regimes
    where Han real-k no longer has a mode-relevant local minimum.
```

Open problems:

```text
1. S0-like remains experimental and needs benchmarking against a trusted reference.
2. Complex-k attenuation is not validated for quantitative fitting.
3. The physical interpretation of high-viscosity real-k branch termination must be tested with complex-k diagnostics.
4. The examples folder still contains historical diagnostics that should be reorganized after Han visco tracking is stabilized.
```

Recommended next tasks:

```text
1. Add a focused complex-k diagnostic for cases where the Han real-k modal minimum disappears.
2. Benchmark S0-like against a trusted Rayleigh-Lamb/fluid-loaded reference.
3. Organize examples into stable validation scripts, demos, and diagnostics archive after the viscoelastic path is stabilized.
4. Decide whether the GUI should expose advanced Han tracker options or keep them as backend-only defaults.
```

## Current limitations

- S0 is implemented but should be treated as experimental until benchmarked against a trusted reference.
- mRLFE complex-k is a prototype and attenuation is not yet validated for quantitative fitting.
- Han viscoelastic real-k can terminate at high etaS, low E, or high frequency when no mode-relevant continuous real-k local minimum is found.
- The global minimum of the Han real-k residual can be a low-Cp edge valley and should not be interpreted as the physical branch.
- The examples folder contains several historical diagnostics from solver development and should be reorganized after Han visco tracking is stabilized.
- Group velocity is not implemented yet.
- Modal structure and displacement animations are not implemented yet.
- Higher modes such as A1 and S1 are not implemented yet.
