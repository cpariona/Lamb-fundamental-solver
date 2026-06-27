# AE IOP/HGO fitting workflow

This document records the first Acoustoelastic IOP/HGO dispersion fitting implementation.

## Scope

The current AE IOP/HGO fitting layer supports fitting experimental phase-speed data against the maintained official atlas branch output.

Implemented helpers:

```matlab
aeBuildFitProblem
aeEvaluateFitModel
aeFitDispersionData
```

The first tested use case is:

```text
branch: atlasA0
free parameter: mu
fixed parameters: IOP, thickness, R, k1, k2, rho, rhoF, fluidBulkModulus
```

## Production branch policy

The only production branch used for fitting is:

```text
atlasA0
```

The fitting evaluator uses only:

```matlab
result.Cp
result.validCp
```

from:

```matlab
solveAcoustoelasticIOPHGOAtlasBranch
```

Diagnostic branches such as `identityA0Diagnostic`, `raw_branch1`, and branch-family candidates are not used as fitting outputs.

## Data contract

The fitting workflow uses the shared experimental data contract:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Only `frequency_Hz` and `Cp_mps` are required.

`validMask` is intersected with `result.validCp` through the shared residual helper because invalid atlas points return nonfinite or invalid model output.

## Solver options

The default fitting options are derived from:

```matlab
aeDefaultSweepOptions("Fast")
```

and force:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

The first synthetic fitting test uses a reduced atlas configuration for speed:

```matlab
options.atlasNumYPoints = 120;
options.atlasTopNMinima = 8;
options.atlasInitializationNumFrequencyPoints = 16;
```

This is intended as a contract test, not as a final production-quality fitting configuration.

## Optimizer policy

`aeFitDispersionData` uses no Optimization Toolbox dependency.

Current behavior:

```text
one free parameter with finite bounds -> fminbnd
multi-parameter or unbounded case     -> fminsearch with bound penalties
```

## Example

Run:

```matlab
clear functions
rehash toolboxcache
startup
fit_ae_atlasA0
```

The example generates synthetic atlasA0 data with a known shear modulus and fits `mu` while keeping IOP, thickness, curvature, HGO fiber parameters, density, and fluid parameters fixed.

The example assigns the result to the base workspace as:

```matlab
AEAtlasA0FitResult
```

## Test

Run:

```matlab
clear functions
rehash toolboxcache
startup
test_ae_fit_synthetic_atlasA0
```

The test checks that the synthetic atlasA0 fit recovers `mu` within tolerance and verifies that the fitting branch remains `atlasA0`.

`run_acoustoelastic_smoke_tests` checks the AE fitting helper path and runs this fitting test.

## App-level integration

The app-level fitting dispatcher now supports:

```matlab
guiRunFit(request)
```

with:

```matlab
request.modelFamily = "acoustoelastic_iop_hgo";
request.branchName = "atlasA0";
```

The AE fitting adapter is:

```matlab
guiFitAcoustoelasticIOPHGOSolver
```

## Current limitations

This phase does not implement:

```text
visible AE controls inside FitTool_GUI
fitting against diagnostic branches
multi-parameter AE fitting validation
IOP fitting validation
thickness fitting validation
parameter covariance/uncertainty estimates
```

Multi-parameter fitting is structurally supported by the helper contracts, but the first maintained validation target is the one-parameter synthetic atlasA0 case.
