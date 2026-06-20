# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

## Current scope

* Rayleigh-Lamb A0 phase velocity using the antisymmetric residual.
* Experimental Rayleigh-Lamb S0 phase velocity using the symmetric residual.
* Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
* mRLFE elastic real-k dispersion for fluid-loaded layers.
* mRLFE Han-style viscoelastic real-k dispersion.
* Acoustoelastic IOP/HGO atlas-branch solver for prestress studies.
* GUI plotting of phase velocity Cp versus frequency, angular frequency, wavenumber, or `kThickness`.

## Repository structure

```text
app/                                  Main MATLAB GUI and UI helper files.
analysis/                             Analysis utilities and model-specific summaries.
docs/                                 Active repository, API, validation, and workflow documentation.
examples/basic/                       Basic Rayleigh-Lamb examples.
examples/validation/                  Maintained validation and stress-test scripts.
examples/mrlfe/                       Maintained mRLFE examples, sweeps, and diagnostics.
examples/acoustoelastic_iop_hgo/      Maintained acoustoelastic IOP/HGO examples, sweeps, and diagnostics.
models/rayleigh_lamb/                 Clean Rayleigh-Lamb implementation using `rl*` functions.
models/mrlfe/                         Modified Rayleigh-Lamb fluid-loaded model.
models/acoustoelastic_iop_hgo/        Acoustoelastic model using IOP prestress and HGO constitutive response.
tests/                                Lightweight smoke and consistency tests.
references/                           Reference material for development and validation context.
```

A more detailed structure map is available in:

```text
docs/repository_structure.md
```

Maintained solver, example, diagnostic, and test entrypoints are listed in:

```text
docs/maintained_entrypoints.md
```

The repository naming strategy is documented in:

```text
docs/naming_strategy.md
```

The current GUI integration audit and adapter plan are documented in:

```text
docs/gui_integration_audit.md
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
analysis/
models/rayleigh_lamb/
models/mrlfe/
models/acoustoelastic_iop_hgo/
examples/basic/
examples/validation/
examples/mrlfe/
examples/acoustoelastic_iop_hgo/
tests/
```

Historical archived examples have been removed; `startup.m` adds only maintained example folders.

## Naming convention

This project uses explicit thickness naming to avoid ambiguity with classical Rayleigh-Lamb notation:

* `thickness`: total plate thickness.
* `halfThickness`: `thickness / 2`, used internally by Rayleigh-Lamb equations.
* `kThickness`: dimensionless wavenumber, computed as `k * thickness`.

Public GUI labels, exported tables, and result structures should use `thickness` and `kThickness`, not `h`, `kh`, or `kH`.

## Defaults and robustness presets

Default physical and frequency parameters are provided by the Rayleigh-Lamb API function:

```matlab
rlDefaultParams
```

Current file: `models/rayleigh_lamb/core/rlDefaultParams.m`.

Default numerical options and robustness presets are provided by the Rayleigh-Lamb API function:

```matlab
rlDefaultOptions
```

Current file: `models/rayleigh_lamb/core/rlDefaultOptions.m`.

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

## Acoustoelastic IOP/HGO workflow

The acoustoelastic IOP/HGO model is organized in:

```text
models/acoustoelastic_iop_hgo/core/
models/acoustoelastic_iop_hgo/constitutive/
models/acoustoelastic_iop_hgo/solvers/
models/acoustoelastic_iop_hgo/options/
examples/acoustoelastic_iop_hgo/
```

Recommended author-neutral entrypoints:

```matlab
solveAcoustoelasticIOPHGOBranch
defaultAcoustoelasticIOPHGOOptions
run_atlas_branch
diagnose_sweep_reliability
```

The old author-specific compatibility wrappers have been removed; maintained acoustoelastic code should use the author-neutral Acoustoelastic IOP/HGO API and the short example/diagnostic entrypoints.

The current official branch policy is `atlasA0`. It selects a conservative A0-like branch and reports non-traceable high-frequency portions as `NaN` instead of reconnecting them automatically.

See:

```text
docs/acoustoelastic_iop_hgo_branch_policy.md
```

## Maintained tests

Run this sequence after refactors:

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```

## Maintained examples

Acoustoelastic IOP/HGO examples are in:

```text
examples/acoustoelastic_iop_hgo/basic/
examples/acoustoelastic_iop_hgo/sweeps/
examples/acoustoelastic_iop_hgo/diagnostics/
```

mRLFE examples are in:

```text
examples/mrlfe/basic/
examples/mrlfe/sweeps/
examples/mrlfe/diagnostics/
```
