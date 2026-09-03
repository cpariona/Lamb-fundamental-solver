# AE IOP/HGO fitting workflow

This document records the Acoustoelastic IOP/HGO dispersion fitting implementation.

## Scope

The current AE IOP/HGO fitting layer supports fitting experimental phase-speed data against the maintained official atlas branch output.

Implemented helpers:

```matlab
aeBuildFitProblem
aeEvaluateFitModel
aeFitDispersionData
solveDispersionFitProblem
```

The first maintained tested use case is:

```text
branch: atlasA0
free parameter: mu
fixed parameters: IOP, thickness, R, k1, k2, rho, rhoF, fluidBulkModulus
```

Additional hidden/fixed-parameter behavior is checked by the focused fitting validation suite.

## Production branch policy

The only production branch used for fitting is:

```text
atlasA0
```

The fitting evaluator uses only:

```matlab
result.phaseVelocity_mps
result.validMask
```

from:

```matlab
solveAcoustoelasticIOPHGOBranch
```

Diagnostic branches such as `identityA0Diagnostic`, `raw_branch1`, and branch-family candidates are not used as fitting outputs.

`aeEvaluateFitModel` is the fitting-grid adapter. It validates the flat
physical inputs, requests official `atlasA0`, and delegates every production
evaluation to the maintained public solver. FitTool and explicit requested
curve evaluation use this same route; neither app code nor analysis fitting
code calls the advanced atlas wrapper directly.

## Data contract

The fitting workflow uses the shared experimental data contract:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.standardError_Cp_mps
experimental.validMask
```

Only `frequency_Hz` and `Cp_mps` are required.

`validMask` is intersected with `result.validMask` through the shared residual helper because invalid atlas points return nonfinite or invalid model output.

## Solver options

The default fitting options are derived from:

```matlab
aeDefaultSweepOptions("Fast")
```

and force:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

The synthetic fitting tests use reduced atlas configurations for speed. These are contract tests, not final production-quality fitting configurations.

## Optimizer policy

`aeFitDispersionData` builds the AE-specific problem and delegates optimizer
orchestration to `solveDispersionFitProblem`. It uses no Optimization Toolbox dependency.

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

## Tests

AE smoke validation runs:

```matlab
clear functions
rehash toolboxcache
startup
run_quick_smoke_tests
```

The AE smoke runner checks the AE fitting helper path and runs:

```matlab
test_ae_fit_synthetic_atlasA0
```

Focused fitting validation runs:

```matlab
run_extended_integration_tests
```

AE cases inside the focused validation suite include:

```text
AE_atlasA0_mu_exact
AE_atlasA0_mu_app_adapter
AE hidden/fixed parameter validation
```

## App-level integration

The app-level fitting dispatcher supports:

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

The fitting registry exposes AE IOP/HGO through:

```matlab
guiGetFitModelConfiguration
FitTool_GUI
```

## Current limitations

This phase does not implement:

```text
fitting against diagnostic branches
AE IOP fitting validation
AE thickness fitting validation
AE multiparameter fitting validation
parameter covariance/uncertainty estimates
```

Multi-parameter fitting is structurally supported by the helper contracts, but the maintained validation targets remain synthetic single-parameter cases and hidden/fixed-parameter contract checks.
