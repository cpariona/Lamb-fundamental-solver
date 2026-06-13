# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

## Current scope

* Rayleigh-Lamb A0 phase velocity using the antisymmetric residual.
* Experimental Rayleigh-Lamb S0 phase velocity using the symmetric residual.
* Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
* mRLFE elastic real-k dispersion for fluid-loaded layers.
* mRLFE Han-style viscoelastic real-k dispersion.
* Li 2024 acoustoelastic atlas-branch solver for IOP/HGO prestress studies.
* GUI plotting of phase velocity Cp versus frequency, angular frequency, wavenumber, or `kThickness`.

## Repository structure

```text
app/                           Main MATLAB GUI and UI helper files.
core/                          Solver orchestration, defaults, material/geometry builders, validation.
equations/                     Rayleigh-Lamb residual functions.
approximations/                Low-frequency analytical approximation helpers.
tracking/                      Generic Rayleigh-Lamb branch tracker.
models/li2024_acoustoelastic/  Li 2024 acoustoelastic model.
models/mrlfe/                  Modified Rayleigh-Lamb fluid-loaded model.
examples/li2024/               Maintained Li 2024 examples, sweeps, and diagnostics.
examples/mrlfe/                Maintained mRLFE examples, sweeps, and diagnostics.
examples/validation/           Maintained validation and stress-test scripts.
examples/archive/              Historical prototypes and development diagnostics.
tests/                         Lightweight smoke and consistency tests.
docs/                          Technical notes and repository documentation.
```

A more detailed structure map is available in:

```text
docs/repository_structure.md
```

Maintained solver, example, diagnostic, and test entrypoints are listed in:

```text
docs/maintained_entrypoints.md
```

## Launching the GUI

From the repository root, run:

```matlab
runApp
```

Alternatively:

```matlab
startup
LambFundamental_GUI
```

## Path behavior

`startup.m` adds only the active solver, GUI, model, analysis, test, and maintained example folders to the MATLAB path:

```text
app/
core/
equations/
approximations/
tracking/
models/
analysis/
examples/li2024/
examples/mrlfe/
examples/validation/
tests/
```

Archived examples remain in `examples/archive/` for traceability, but are not part of the routine MATLAB path.

## Naming convention

This project uses explicit thickness naming to avoid ambiguity with classical Rayleigh-Lamb notation:

* `thickness`: total plate thickness.
* `halfThickness`: `thickness / 2`, used internally by Rayleigh-Lamb equations.
* `kThickness`: dimensionless wavenumber, computed as `k * thickness`.

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

* `Fast`: fewer scan points and faster calculations.
* `Balanced`: default setting for routine exploration.
* `Robust`: more scan points and wider search windows for difficult cases.

## mRLFE solver workflow

The mRLFE real-k models are solved using an intentionally chained workflow:

```text
Rayleigh-Lamb A0/S0
    -> mRLFE elastic real-k A0-like/S0-like
        -> mRLFE Han viscoelastic real-k A0-like/S0-like
```

Main mRLFE folders:

```text
models/mrlfe/core/
models/mrlfe/solvers/
models/mrlfe/options/
examples/mrlfe/
```

The high-level mRLFE function is:

```matlab
computeMRLFE
```

Useful maintained examples:

```matlab
run_mrlfe_prototype
compare_mrlfe_elastic_vs_han_visco_cp
sweep_mrlfe_shear_viscosity_phase_velocity
```

Useful diagnostics:

```matlab
diagnose_mrlfe_han_visco_validity_breakdown
diagnose_mrlfe_han_visco_residual_landscape
compare_mrlfe_tracker_vs_condition_peaks
```

## Li 2024 acoustoelastic workflow

The Li 2024 model is organized in:

```text
models/li2024_acoustoelastic/core/
models/li2024_acoustoelastic/constitutive/
models/li2024_acoustoelastic/solvers/
models/li2024_acoustoelastic/options/
examples/li2024/
```

The recommended high-level solver is:

```matlab
solveDispersionIOPHGOAtlasBranch_Li2024
```

The default atlas-branch policy is `strictA0`. It selects an A0-like branch using low-start-speed and start-rank filters, splits large Cp jumps, and reports non-traceable high-frequency portions as `NaN` instead of reconnecting them automatically.

See:

```text
docs/li2024_branch_tracking_policy.md
```

Useful maintained example:

```matlab
run_li2024_IOP_HGO_A0_atlas_branch
```

Useful diagnostic:

```matlab
diagnose_li2024_atlas_branch_policy
```

## Maintained tests

Run this sequence after refactors:

```matlab
clear functions
rehash toolboxcache
startup

test_li2024_constitutive_identity
test_li2024_strictA0_smoke
test_mrlfe_smoke
```

## Maintained examples

Li 2024 examples are in:

```text
examples/li2024/basic/
examples/li2024/sweeps/
examples/li2024/diagnostics/
```

mRLFE examples are in:

```text
examples/mrlfe/basic/
examples/mrlfe/sweeps/
examples/mrlfe/diagnostics/
```

Validation scripts are in:

```text
examples/validation/
```
