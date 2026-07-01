# Fitting Phase 1 status

This document records the implementation status of the generic fitting backend introduced after `docs/workflows/fitting/architecture.md`.

## Scope

Phase 1 adds shared, model-independent utilities for experimental dispersion fitting.

It does not add:

```text
model-specific fitting
optimizer calls
GUI fitting panels
new solver behavior
file moves or structural refactors
```

## Implemented helper layer

Generic fitting helpers now live under:

```text
analysis/fitting/
```

Maintained helpers:

```matlab
normalizeExperimentalDispersionData
validateExperimentalDispersionData
computeDispersionFitResiduals
computeDispersionFitMetrics
buildParameterVector
unpackParameterVector
estimateLocalSensitivity
assessFitIdentifiability
```

## Data contract

The implemented helpers use the Phase 0 experimental-data contract:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Required:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
```

Optional:

```matlab
experimental.standardError_Cp_mps
experimental.validMask
```

All vectors are normalized to column vectors.

If `validMask` is missing, finite positive-frequency points with finite phase speed are treated as valid.

## Residual policy

Default residuals are unweighted:

```matlab
residual = CpModel_mps - CpExp_mps
```

Standard-error weighting is available only through an explicit option:

```matlab
options.useStandardErrorWeights = true;
```

When enabled, residuals are scaled as:

```matlab
residual = (CpModel_mps - CpExp_mps) ./ standardError_Cp_mps
```

This keeps weighting available for future use without making it a visible first-version GUI requirement.

## Identifiability support

Phase 1 includes local finite-difference sensitivity estimation:

```matlab
S(:, j) = dCp(f_i) / dtheta_j
```

and a coarse identifiability assessment based on:

```matlab
rank(S)
cond(S' * S)
correlation between sensitivity columns
```

The identifiability classification can be:

```text
insufficient_data
underdetermined
rank_deficient
ill_conditioned
weakly_identifiable
locally_identifiable
```

## Tests

A focused helper smoke test was added:

```matlab
test_fitting_helpers_smoke
```

The core smoke runner now checks that the shared fitting helpers are on the MATLAB path and calls the fitting helper smoke test:

```matlab
run_core_smoke_tests
```

## Next phase

Phase 2 should add the first model-specific fitting path for Rayleigh-Lamb, starting with synthetic data.

Recommended first target:

```text
Rayleigh-Lamb A0
fit parameter: mu
fixed parameters: thickness, rho, nu
```

The Phase 2 implementation should use the Phase 1 helpers instead of duplicating normalization, residual, metric, parameter-vector, or identifiability logic.
