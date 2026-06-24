# Dispersion fitting architecture

This document defines the planned architecture for fitting experimental dispersion data against the maintained Lamb-wave model families in this repository.

It is a Phase 0 design document only. It does not introduce MATLAB fitting code, GUI callbacks, new solvers, or file moves.

## Scope

The fitting layer will estimate model parameters from experimental phase-speed data:

```text
frequency -> measured phase speed -> model parameters
```

The supported experimental observable is the phase-speed curve:

```matlab
frequency_Hz
Cp_mps
```

The first fitting target is dispersion data for the maintained model families:

```text
Rayleigh-Lamb
mRLFE
Acoustoelastic IOP/HGO
```

The fitting layer must be reusable from scripts, tests, and the GUI. It must not be embedded directly inside GUI files or long example scripts.

## Design principles

1. The GUI must not implement fitting algorithms.
2. Example scripts must not be used as backend dependencies.
3. Fitting must call maintained model APIs or model-specific adapters.
4. Shared fitting utilities should live in a small generic fitting helper layer.
5. Model-specific fitting logic should live with the corresponding model helper layer.
6. Solver improvements should benefit fitting automatically as long as the solver input/output contract is preserved.
7. Diagnostic branches must not be promoted to production fitting outputs without explicit validation.

The GUI-facing architecture should follow the same separation already used by the sweep tool:

```text
GUI panel
    -> request struct
    -> app/fitting dispatcher
    -> model-specific adapter
    -> maintained model API
    -> normalized fit result
    -> plotting/export
```

## Planned user workflow

The intended fitting workflow is:

```text
1. Load or paste experimental data.
2. Select model family.
3. Select branch.
4. Select basic or assisted fitting mode.
5. Select free parameter(s).
6. Set fixed parameters, initial guesses, and bounds.
7. Optionally run an identifiability check.
8. Run fitting.
9. Plot experimental data, fitted curve, and residuals.
10. Export the fit request and fit result.
```

## GUI integration policy

Fitting should be integrated visually into the main GUI as an additional panel or tab, for example:

```text
Forward model
Sweep analysis
Experimental fitting
```

The fitting panel should call a fitting backend rather than directly calling model scripts. A future standalone `FitTool_GUI` may exist, but it should reuse the same backend.

The planned GUI-side fitting layer is:

```text
app/fitting/guiGetFitRegistry.m
app/fitting/guiBuildFitRequest.m
app/fitting/guiRunFit.m
app/fitting/guiNormalizeFitResult.m
app/fitting/guiPlotFitResult.m
```

Model-specific GUI adapters should follow the existing adapter pattern:

```text
app/adapters/guiFitRLSolver.m
app/adapters/guiFitMRLFESolver.m
app/adapters/guiFitAcoustoelasticIOPHGOSolver.m
```

## Experimental data contract

The normalized experimental data structure should use explicit SI units:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Required fields:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
```

Optional fields:

```matlab
experimental.standardError_Cp_mps
experimental.validMask
```

### Frequency and phase-speed units

The internal fitting contract is:

```text
frequency in Hz
phase speed in m/s
standard error in m/s
```

The first GUI implementation should default to Hz and m/s. Optional display support for kHz may be added later, but stored/request structures should keep explicit SI field names.

### validMask

`validMask` is an optional logical vector indicating which experimental points should participate in fitting.

It can be used to exclude:

```text
low-SNR points
failed experimental tracking points
NaN or nonfinite points
manual outliers
frequencies outside the trusted range
```

If missing, the backend should build a default valid mask from finite `frequency_Hz` and finite `Cp_mps` values.

### Standard error and weights

Experimental standard error may be supplied as:

```matlab
experimental.standardError_Cp_mps
```

Visible user-facing fitting should not require an explicit `weight` vector in the first implementation.

A hidden or advanced option may later convert standard error into weights:

```matlab
weight = 1 ./ standardError_Cp_mps.^2;
```

The default first implementation should use unweighted residuals unless the fitting options explicitly enable standard-error weighting.

## FitRequest contract

A fitting request should be represented as a structure with this conceptual schema:

```matlab
fitRequest = struct();

fitRequest.modelFamily = "rayleigh_lamb";
fitRequest.branchName = "A0";

fitRequest.experimental.frequency_Hz = frequency_Hz;
fitRequest.experimental.Cp_mps = Cp_mps;
fitRequest.experimental.standardError_Cp_mps = [];
fitRequest.experimental.validMask = [];

fitRequest.fixedParams = struct();
fitRequest.freeParams = ["mu"];

fitRequest.initialGuess = struct();
fitRequest.bounds = struct();

fitRequest.options = struct();
fitRequest.options.mode = "basic";
fitRequest.options.useStandardErrorWeights = false;
fitRequest.options.optimizer = "lsqnonlin";
```

The exact fields may evolve during implementation, but the separation between experimental data, fixed parameters, free parameters, bounds, and options should remain stable.

## FitResult contract

A fitting result should be represented as a structure with this conceptual schema:

```matlab
fitResult = struct();

fitResult.modelFamily = fitRequest.modelFamily;
fitResult.branchName = fitRequest.branchName;

fitResult.bestParams = struct();
fitResult.fixedParams = fitRequest.fixedParams;

fitResult.frequency_Hz = frequency_Hz;
fitResult.Cp_exp_mps = Cp_exp_mps;
fitResult.Cp_fit_mps = Cp_fit_mps;
fitResult.residuals_mps = residuals_mps;
fitResult.validMask = validMask;

fitResult.metrics.RMSE = RMSE;
fitResult.metrics.NRMSE = NRMSE;
fitResult.metrics.MAE = MAE;

fitResult.identifiability = identifiabilitySummary;

fitResult.optimizer.exitFlag = exitFlag;
fitResult.optimizer.message = message;

fitResult.rawSolverResult = rawSolverResult;
fitResult.normalizedModelResult = normalizedModelResult;
```

The result should preserve enough raw solver information for diagnostics while exposing a normalized result for GUI plotting and export.

## Fitting modes

### Basic mode

In basic mode, the user explicitly chooses the free parameter or parameters.

For a single experimental frequency-speed pair, the GUI should allow only one free parameter. The remaining parameters should be fixed and editable.

For a curve with multiple valid frequency-speed points, the GUI may allow multiple free parameters, subject to basic identifiability checks and user warnings.

### Assisted mode

In assisted mode, the system should estimate whether the selected data can support the requested free-parameter set.

The recommendation should consider:

```text
number of valid data points
frequency span
local sensitivity of Cp to each candidate parameter
correlation between sensitivity columns
condition number of the sensitivity matrix
model-specific branch validity
```

Assisted mode should recommend and warn. It should not silently change the solver policy or promote diagnostic branches.

## Identifiability policy

Let:

```text
N = number of valid experimental points
P = number of free parameters
```

The minimum mathematical rule is:

```text
N >= P
```

The recommended practical rule is:

```text
N >= 3P
```

The backend should also support local sensitivity analysis:

```matlab
S(:, j) = dCp(f_i) / dtheta_j;
```

Useful diagnostics include:

```matlab
rank(S)
cond(S' * S)
corr(S(:, i), S(:, j))
```

If sensitivity columns are nearly collinear or the condition number is large, the result should report the fit as weakly identifiable or ill-conditioned.

## Planned file layout

The first implementation should minimize structural disruption.

Generic fitting helpers:

```text
analysis/fitting/normalizeExperimentalDispersionData.m
analysis/fitting/validateExperimentalDispersionData.m
analysis/fitting/computeDispersionFitResiduals.m
analysis/fitting/computeDispersionFitMetrics.m
analysis/fitting/buildParameterVector.m
analysis/fitting/unpackParameterVector.m
analysis/fitting/estimateLocalSensitivity.m
analysis/fitting/assessFitIdentifiability.m
```

Rayleigh-Lamb fitting helpers:

```text
analysis/rayleigh_lamb/rlBuildFitProblem.m
analysis/rayleigh_lamb/rlEvaluateFitModel.m
analysis/rayleigh_lamb/rlFitDispersionData.m
```

mRLFE fitting helpers:

```text
analysis/mrlfe/mrlfeBuildFitProblem.m
analysis/mrlfe/mrlfeEvaluateFitModel.m
analysis/mrlfe/mrlfeFitDispersionData.m
```

Acoustoelastic IOP/HGO fitting helpers:

```text
analysis/acoustoelastic_iop_hgo/aeBuildFitProblem.m
analysis/acoustoelastic_iop_hgo/aeEvaluateFitModel.m
analysis/acoustoelastic_iop_hgo/aeFitDispersionData.m
```

GUI fitting layer:

```text
app/fitting/guiGetFitRegistry.m
app/fitting/guiBuildFitRequest.m
app/fitting/guiRunFit.m
app/fitting/guiNormalizeFitResult.m
app/fitting/guiPlotFitResult.m
```

Model-specific GUI adapters:

```text
app/adapters/guiFitRLSolver.m
app/adapters/guiFitMRLFESolver.m
app/adapters/guiFitAcoustoelasticIOPHGOSolver.m
```

Example scripts should live under each model family:

```text
examples/rayleigh_lamb/fitting/fit_default_A0.m
examples/mrlfe/fitting/fit_mrlfe_A0Like.m
examples/acoustoelastic_iop_hgo/fitting/fit_ae_atlasA0.m
```

Tests should live under each model family or GUI test group:

```text
tests/rayleigh_lamb/test_rl_fit_synthetic_A0.m
tests/mrlfe/test_mrlfe_fit_synthetic_A0Like.m
tests/acoustoelastic_iop_hgo/test_ae_fit_synthetic_atlasA0.m
tests/gui/test_gui_fit_registry_contract.m
```

## Model-specific fitting policy

### Rayleigh-Lamb

Rayleigh-Lamb should be the first fitting implementation because it is the simplest validation target.

Initial branches:

```text
A0
S0
```

Initial free-parameter candidates:

```text
mu
thickness
```

Typical fixed parameters:

```text
rho
nu
```

Initial validation should use synthetic data generated from known parameters, optionally with small noise, and verify parameter recovery within a tolerance.

### mRLFE

mRLFE should be implemented after Rayleigh-Lamb fitting is working.

Initial branches:

```text
A0Like
S0Like
```

Initial free-parameter candidates:

```text
mu
etaS
thickness
```

Recommended fitting progression:

```text
one parameter: mu
two parameters: mu + etaS
three parameters: mu + etaS + thickness only when enough valid points and frequency span are available
```

### Acoustoelastic IOP/HGO

Acoustoelastic IOP/HGO fitting should be implemented after the simpler fitting workflows are stable.

The initial production branch should be:

```text
atlasA0
```

Initial free-parameter candidates:

```text
mu
IOP
thickness
```

Initially fixed parameters should include:

```text
R
rho
rhoF
fluidBulkModulus
k1
k2
```

The official output remains `result.Cp` and `result.validCp` under the maintained `atlasA0` policy. Diagnostic branches such as `identityA0Diagnostic`, `raw_branch1`, and `branch_families` must remain diagnostic-only unless a future validation document explicitly changes that policy.

If the solver returns `NaN` or `validCp = false` for a frequency, fitting should not force interpolation across that point in production mode.

## Registry expectations

The fitting registry should declare, for each model family:

```text
model family name
available branches
free-parameter candidates
default fixed parameters
default initial guesses
bounds
display labels
display units
internal unit scales
supported fitting modes
model-specific warnings
```

The GUI should not hard-code model parameter lists. It should read them from the fitting registry.

## Validation expectations

Phase 0 does not require MATLAB execution because it only adds documentation.

Once fitting code is introduced, validation should include:

```matlab
clear functions
rehash toolboxcache
startup
run_core_smoke_tests
run_gui_smoke_tests
```

For model-specific fitting phases, add focused tests such as:

```matlab
test_rl_fit_synthetic_A0
test_mrlfe_fit_synthetic_A0Like
test_ae_fit_synthetic_atlasA0
```

For broad changes, run:

```matlab
run_all_smoke_tests
```

## Future structural refactor note

The current helper layout is:

```text
analysis/acoustoelastic_iop_hgo
analysis/mrlfe
analysis/rayleigh_lamb
```

Adding `analysis/fitting` creates a mixed level where generic cross-model helpers and model-specific helper folders sit side by side.

This is acceptable for the first fitting implementation because it minimizes disruption, but it should be recorded as future refactor debt.

A later cleanup may group shared helpers and model helpers more explicitly, for example:

```text
analysis/common/fitting
analysis/common/io
analysis/common/plotting
analysis/rayleigh_lamb
analysis/mrlfe
analysis/acoustoelastic_iop_hgo
```

or another documented layout that preserves the repository's model-centered organization.

Do not perform this structural refactor as part of the first fitting implementation.

## Phase plan

### Phase 0

Add this architecture document and register it in the active documentation list.

### Phase 1

Implement generic experimental-data normalization, residual, metrics, and identifiability helpers.

### Phase 2

Implement Rayleigh-Lamb fitting against synthetic A0/S0 data.

### Phase 3

Add app-level fitting registry, request builder, dispatcher, normalizer, and plotting helpers.

### Phase 4

Add minimal GUI integration for Rayleigh-Lamb fitting.

### Phase 5

Implement mRLFE fitting.

### Phase 6

Implement Acoustoelastic IOP/HGO fitting with official `atlasA0` output only.
