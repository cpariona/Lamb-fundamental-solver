# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

Current scope:

- Rayleigh-Lamb A0 phase velocity using the antisymmetric residual.
- Experimental Rayleigh-Lamb S0 phase velocity using the symmetric residual.
- Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
- mRLFE elastic real-k dispersion for fluid-loaded layers, including a multicandidate dynamic-programming tracker for A0-like soft-material cases.
- mRLFE Han-style viscoelastic real-k dispersion with real lambda, complex shear modulus, and conservative modal-local Cp-window tracking.
- Experimental complex-k mRLFE path kept internally for spatial attenuation exploration.
- GUI plotting of phase velocity Cp versus frequency, angular frequency, wavenumber, or `kThickness`.

## Repository structure

```text
app/                  Main MATLAB GUI and UI helper files.
core/                 Solver orchestration, defaults, material/geometry builders, validation.
equations/            Rayleigh-Lamb residual functions.
approximations/       Low-frequency analytical approximation helpers.
tracking/             Generic Rayleigh-Lamb branch tracker.
models/mrlfe/         Fluid-loaded mRLFE model, real-k/complex-k solvers, and trackers.
examples/basic/       Lightweight examples and visual sweeps.
examples/validation/  Maintained validation and stress-test scripts.
examples/diagnostics/ Active diagnostic scripts for current solver questions.
examples/archive/     Historical prototypes and development diagnostics.
docs/                 Technical notes about validation status.
```

The legacy `GUI_current/` folder and `CONTEXT_FOR_CODEX.md` were removed after the current modular GUI and README became the source of truth.

## Launching the GUI

From the repository root, run:

```matlab
runApp
```

This calls `startup`, adds the active project folders to the MATLAB path, and launches the GUI.

Alternatively:

```matlab
startup
LambFundamental_GUI
```

## Path behavior

`startup.m` adds only the active solver, GUI, model, and maintained example folders to the MATLAB path:

```text
app/
core/
equations/
approximations/
tracking/
models/
examples/basic/
examples/validation/
examples/diagnostics/
```

The archived examples are intentionally not added by default. They remain in `examples/archive/` for traceability, but are not part of the normal workflow.

## Naming convention

This project uses explicit thickness naming to avoid ambiguity with classical Rayleigh-Lamb notation:

- `thickness`: total plate thickness.
- `halfThickness`: `thickness / 2`, used internally by Rayleigh-Lamb equations.
- `kThickness`: dimensionless wavenumber, computed as `k * thickness`.

Public GUI labels, exported tables, and result structures should use `thickness` and `kThickness`, not `h`, `kh`, or `kH`.

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

The previous A0-like soft-material branch-switching issue was resolved for this tested range by the integrated DP tracker.

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

## Maintained examples

Run these from the repository root after `startup`.

Basic examples:

```matlab
examples/basic/run_default_A0
examples/basic/run_default_A0_S0
examples/basic/sweep_thickness_A0_S0
examples/basic/run_mrlfe_prototype
examples/basic/compare_mrlfe_elastic_vs_han_visco_cp
examples/basic/sweep_mrlfe_shear_viscosity_phase_velocity
```

Validation scripts:

```matlab
examples/validation/check_default_outputs
examples/validation/stress_test_mrlfe_elastic_range
examples/validation/stress_test_mrlfe_han_visco_range
```

Active diagnostics:

```matlab
examples/diagnostics/diagnose_mrlfe_han_visco_validity_breakdown
examples/diagnostics/diagnose_mrlfe_han_visco_residual_landscape
examples/diagnostics/compare_mrlfe_tracker_vs_condition_peaks
```

Parametric sweeps:

```matlab
examples/sweeps/sweep_viscosity_A0Like_viscoelastic
examples/sweeps/sweep_viscosity_S0Like_viscoelastic
examples/sweeps/sweep_stiffness_A0Like_viscoelastic
examples/sweeps/sweep_stiffness_S0Like_viscoelastic
examples/sweeps/sweep_thickness_A0Like_viscoelastic
examples/sweeps/sweep_thickness_S0Like_viscoelastic
```

Sweep workflow documentation:

```text
docs/parametric_sweeps.md
```

Historical prototypes and exploratory diagnostics are in `examples/archive/` and are not part of routine validation.

## Development status summary

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
