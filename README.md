# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

## Current scope

* Rayleigh-Lamb A0 phase velocity using the antisymmetric residual.
* Experimental Rayleigh-Lamb S0 phase velocity using the symmetric residual.
* Low-frequency analytical approximations for A0 thin-plate flexure and S0 extensional motion.
* mRLFE real-k dispersion and fitting for fluid-loaded layers.
* Acoustoelastic IOP/HGO atlas-branch solver for prestress studies.
* GUI plotting and fitting of phase velocity Cp versus frequency, angular frequency, wavenumber, or `kThickness`.

## Repository structure

```text
app/                                  Main MATLAB GUI and UI helper files.
analysis/                             Analysis utilities and model-specific summaries.
docs/                                 Active repository, API, validation, and workflow documentation.
examples/rayleigh_lamb/               Maintained Rayleigh-Lamb examples and validation scripts.
examples/mrlfe/                       Maintained mRLFE examples, sweeps, diagnostics, and stress tests.
examples/acoustoelastic_iop_hgo/      Maintained acoustoelastic IOP/HGO examples, sweeps, and diagnostics.
models/rayleigh_lamb/                 Clean Rayleigh-Lamb implementation using `rl*` functions.
models/mrlfe/                         Modified Rayleigh-Lamb fluid-loaded model.
models/acoustoelastic_iop_hgo/        Acoustoelastic model using IOP prestress and HGO constitutive response.
tests/                                Lightweight smoke and consistency tests.
references/                           Reference material for development and validation context.
```

A more detailed structure map is available in:

```text
docs/repository/repository_structure.md
```

Maintained solver, example, diagnostic, and test entrypoints are listed in:

```text
docs/repository/maintained_entrypoints.md
```

The repository naming strategy is documented in:

```text
docs/repository/naming_strategy.md
```

The current GUI integration audit and adapter plan are documented in:

```text
docs/workflows/gui/integration_audit.md
```

Repository cleanup policy is tracked in:

```text
docs/repository/repository_hygiene_plan.md
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
examples/rayleigh_lamb/
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

## Defaults and execution profiles

Default physical and frequency parameters are provided by the Rayleigh-Lamb API function:

```matlab
rlDefaultParams
```

Current file: `models/rayleigh_lamb/core/rlDefaultParams.m`.

Default Rayleigh-Lamb numerical options are provided by:

```matlab
rlDefaultOptions
```

Current file: `models/rayleigh_lamb/core/rlDefaultOptions.m`.

The canonical app-level field is:

```matlab
executionProfile
```

The historical field remains supported as a compatibility alias:

```matlab
robustness
```

Available execution profiles:

* `Fast`: fewer scan points and faster calculations.
* `Balanced`: default setting for routine exploration.
* `Robust`: more scan points and wider search windows for difficult cases.

Visible GUI defaults are:

| Surface | Default |
| --- | --- |
| `LambFundamental_GUI` | `Balanced` |
| `SweepTool_GUI` | `Fast` |
| `FitTool_GUI` | `Fast` |

Model-specific adapters report requested and effective profile metadata. mRLFE
keeps maintained fast atlas presets for GUI and fitting routes; inspect
`requestedExecutionProfile`, `effectiveExecutionProfile`, and
`profileOverrideReason` when comparing requested versus effective behavior.

## mRLFE solver workflow

The maintained mRLFE GUI surface exposes a single real-k model family:

```text
mRLFERealK
```

The forward solver and sweep workflows still use the Rayleigh-Lamb seed and maintained mRLFE real-k branch machinery. The FitTool fitting route is atlas-first:

```text
mrlfeFitDispersionData
    -> mrlfeBuildFitProblem
    -> mrlfeEvaluateFitModel
    -> mrlfeEvaluateAtlasFitModel
    -> official mRLFE atlas branch output
```

For A0Like FitTool fitting, the current default policy is:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

The conservative `delayedCut` policy remains available for diagnostics and policy comparisons.

Main mRLFE folders:

```text
models/mrlfe/core/
models/mrlfe/solvers/
models/mrlfe/options/
analysis/mrlfe/
examples/mrlfe/
```

The high-level mRLFE function is:

```matlab
computeMRLFE
```

Maintained mRLFE analysis helpers:

```matlab
objectiveMRLFEResidual
summarizeMRLFETrackingQuality
compareMRLFETrackingStrategies
```

Maintained mRLFE sweeps:

```matlab
sweep_mu_A0Like_viscoelastic
sweep_mu_S0Like_viscoelastic
sweep_etaS_A0Like_viscoelastic
sweep_etaS_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

Maintained mRLFE fitting and comparison examples:

```matlab
fit_mrlfe_A0Like
compare_mrlfe_elastic_vs_visco_cp
```

Focused mRLFE diagnostics:

```matlab
compare_mrlfe_tracker_vs_condition_peaks
diagnose_etaS_direct_atlas_fit
diagnose_etaS_forward_cache
diagnose_fit_timing
diagnose_fit_option_sensitivity
stress_test_mrlfe_real_k_range
```

The complete mRLFE diagnostic inventory and historical cleanup candidates are documented in:

```text
examples/mrlfe/diagnostics/README.md
```
