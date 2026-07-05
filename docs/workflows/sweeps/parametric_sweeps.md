# Parametric sweeps

This document summarizes the maintained one-parameter sweep examples.

## Maintained acoustoelastic IOP/HGO examples

Maintained AE sweep entrypoints live under:

```text
examples/acoustoelastic_iop_hgo/sweeps/
```

Current one-parameter scripts and values:

```matlab
sweep_iop        % [5, 10, 15, 20, 25] mmHg
sweep_mu         % [25, 50, 75, 100] kPa
sweep_thickness  % [400, 475, 550, 625, 700] um
sweep_k1         % [10, 25, 50, 75, 100] kPa
sweep_k2         % [50, 100, 200, 300, 400]
sweep_radius     % [7.0, 7.4, 7.8, 8.2, 8.6] mm
```

The maintained two-parameter case study is `sweep_mu_iop`.

One-parameter scripts use the existing AE structure:
`aeDefaultSweepParams` -> `aeDefaultSweepOptions` -> `aeRunSweep` ->
`aeSummarizeSweep` -> `aeWriteSweepOutputs` -> `aePlotSweepCp` ->
`aeSaveExampleFigure`.

Outputs follow:

```text
Results/ae_iop_hgo/<task>/
examples/acoustoelastic_iop_hgo/sweeps/figures/<task>/
```

## Maintained mRLFE examples

The maintained mRLFE examples live under:

```text
examples/mrlfe/sweeps/
```

Current scripts:

```matlab
sweep_mu_A0Like_viscoelastic
sweep_mu_S0Like_viscoelastic
sweep_etaS_A0Like_viscoelastic
sweep_etaS_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

All six scripts delegate to `mrlfeRunSweepExample` and share helpers under `analysis/mrlfe/`.

Current mRLFE reference settings:

```text
mu = 75 kPa
nu = 0.4999
etaS = 0.05 Pa*s
2h = 0.5 mm
fmin = 100 Hz
fmax = 16000 Hz
frequencySpacing = hybrid
rho = 1070 kg/m^3
fluidDensity = 1000 kg/m^3
fluidSoundSpeed = 1500 m/s
robustness preset = Fast
```

`E`, `lambda_Lame`, `K`, `CT`, and `CL` are derived from `mu`, `nu`, and `rho` through the shared elastic-material helpers.

Current mRLFE sweep values:

```matlab
mu = [60, 65, 70, 75, 80] kPa
etaS = [0, 0.1, 0.2, 0.3, 0.4, 0.5] Pa*s
2h = [0.3, 0.4, 0.5, 0.6, 0.7] mm
```

mRLFE plots use AE-style two-line titles. The first line gives the sweep target and the second line gives fixed reference parameters without overloading the legend.

mRLFE figures use frequency in kHz. The frequency and Cp axes start at zero.

mRLFE outputs follow the AE example pattern:

```text
Results/mrlfe/mu_sweep/
Results/mrlfe/etaS_sweep/
Results/mrlfe/thickness_sweep/
examples/mrlfe/sweeps/figures/mu_sweep/
examples/mrlfe/sweeps/figures/etaS_sweep/
examples/mrlfe/sweeps/figures/thickness_sweep/
```

Figures are saved as `.fig` and `.png`.

## Maintained Rayleigh-Lamb examples

Basic Rayleigh-Lamb examples live under:

```text
examples/rayleigh_lamb/basic/
```

and are reserved for minimal default runs such as:

```matlab
run_default_A0
run_default_A0_S0
```

Maintained Rayleigh-Lamb sweeps live under:

```text
examples/rayleigh_lamb/sweeps/
```

Current sweep scripts:

```matlab
sweep_thickness_A0_elastic
sweep_thickness_S0_elastic
```

Both scripts delegate to:

```matlab
rlRunSweepExample
```

and shared helpers under:

```text
analysis/rayleigh_lamb/
```

Current Rayleigh-Lamb reference settings:

```text
mu = 75 kPa
nu = 0.4999
2h = 0.5 mm
fmin = 100 Hz
fmax = 16000 Hz
frequencySpacing = hybrid
rho = 1070 kg/m^3
robustness preset = Balanced
```

`E`, `lambda_Lame`, `K`, `CT`, and `CL` are derived from `mu`, `nu`, and `rho`.

Current Rayleigh-Lamb sweep values:

```matlab
2h = [0.3, 0.4, 0.5, 0.6, 0.7] mm
```

Rayleigh-Lamb plots use AE-style two-line titles, frequency in kHz, and axes starting at zero. Outputs follow:

```text
Results/rayleigh_lamb/thickness_sweep/
examples/rayleigh_lamb/sweeps/figures/thickness_sweep/
```

Figures are saved as `.fig` and `.png`.

## Generic sweep utilities

Generic helpers live under `analysis/`:

```matlab
runParametricSweep
plotParametricSweepCp
summarizeParametricSweepBranch
```

`runParametricSweep` changes one scalar solver parameter. It supports optional `displayValues`, used by the mRLFE and Rayleigh-Lamb examples to display `2h` or `mu` while preserving current internal solver fields.

`plotParametricSweepCp` plots `Cp(f)` for one model/branch pair and supports frequency scaling, zero-start frequency limits, and multiline titles.

`summarizeParametricSweepBranch` reports branch validity, frequency range, Cp range, and elapsed time for each sweep case.

## Validation

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup

sweep_iop
sweep_mu
sweep_thickness
sweep_k1
sweep_k2
sweep_radius
sweep_mu_iop
sweep_mu_A0Like_viscoelastic
sweep_mu_S0Like_viscoelastic
sweep_etaS_A0Like_viscoelastic
sweep_etaS_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
sweep_thickness_A0_elastic
sweep_thickness_S0_elastic

run_all_smoke_tests
```
