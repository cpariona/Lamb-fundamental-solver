# Fitting Phase 10 status

This document records physical quality diagnostics for fitting.

## Scope

Phase 10 adds a quality-control layer that complements RMSE. It does not replace the solvers or optimizers.

Added files:

```text
analysis/fitting/computeConstantSpeedBaseline.m
analysis/fitting/assessFitPhysicalQuality.m
app/fitting/guiEvaluateFitFullCurve.m
tests/fitting/test_fit_physical_qc_flat_rl.m
tests/fitting/test_fit_physical_qc_synthetic_pass.m
docs/fitting_phase10_status.md
```

Updated files:

```text
app/fitting/guiNormalizeFitResult.m
app/fitting/guiPlotFitResult.m
tests/fitting/run_fit_validation_tests.m
tests/run_core_smoke_tests.m
docs/maintained_entrypoints.md
```

## New diagnostics

The normalized fit output now includes:

```matlab
normalized.qc
normalized.fullCurve
```

`normalized.qc` contains:

```text
classification
reasons
constant-speed baseline
experimental dispersion ratio
model dispersion ratio
model RMSE
constant baseline RMSE
improvement over constant baseline
boundary-hit flag
local sensitivity score
```

## Constant-speed baseline

The new null model is:

```text
Cp(f) = mean(Cp_exp_valid)
```

If a physical model does not improve meaningfully over this baseline, the fit may be numerically good but physically uninformative.

## Physical QC classifications

Current classes:

```text
pass
caution
warning
```

Current warning reasons include:

```text
near-flat experimental curve
weakly dispersive fitted A0-like curve
constant-speed baseline is competitive
fitted parameter is near declared bound
low local parameter sensitivity
AE atlas fallback was used
```

## GUI behavior

`guiPlotFitResult` now plots:

```text
full fitted curve
constant-speed baseline
experimental data
model evaluated at experimental points
```

The plot title includes the physical QC class.

The result table includes:

```text
ConstantRMSE_mps
ImprovementOverConstant
ExpDispersionRatio
ModelDispersionRatio
SensitivityScore
PhysicalQC
QCReasons
```

## Tests

New tests:

```matlab
test_fit_physical_qc_flat_rl
test_fit_physical_qc_synthetic_pass
```

The flat RL A0 test uses a constant phase speed curve and expects QC to flag:

```text
near-flat experimental curve
constant-speed baseline is competitive
```

The synthetic dispersive RL test expects the physical model to improve over the constant-speed baseline.

`run_fit_validation_tests` now runs both physical QC tests.

## Interpretation

A low RMSE is now treated as only a numerical criterion.

A fit may have:

```text
low RMSE
warning physical QC
```

This indicates that the model curve can pass through the points, but the data/model combination may not contain enough dispersive information to support the physical interpretation.

## Recommended next phase

Phase 11 should review solver internals and add solver-specific reliability diagnostics where appropriate:

```text
Rayleigh-Lamb: A0/S0 ambiguity and k*h/Cp/CT reporting
mRLFE: A0Like/S0Like ambiguity and etaS sensitivity reporting
AE IOP/HGO: sensitivity correlation between mu, IOP, thickness
```
