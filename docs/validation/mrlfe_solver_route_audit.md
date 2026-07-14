# mRLFE solver-route audit

Historical characterization performed before the production API migration.
These routes are not maintained entrypoints.

## Purpose

This audit characterizes the solver routes that currently coexist for mRLFE before any repository-wide restructuring or deletion.

It is intentionally non-invasive. It does not change production defaults, solver implementations, GUI behavior, fitting behavior, branch-selection policies, or public APIs.

The audit exists to answer four questions with executable evidence:

1. Which routes are actually reachable from maintained surfaces?
2. Do those routes return the same branch on the same requested grid?
3. Which routes are materially faster or more robust?
4. Which behavior must be preserved before removing wrappers, aliases, or legacy solvers?

## Entry points

Quick audit:

```matlab
clear; clc; close all;
startup
run_mrlfe_solver_route_audit
```

Direct call:

```matlab
audit = auditMRLFESolverRoutes('Mode', "quick");
```

Expanded parameter matrix:

```matlab
audit = auditMRLFESolverRoutes('Mode', "full");
```

The default output folder is:

```matlab
fullfile(tempdir, 'lamb_fundamental_solver', 'mrlfe_solver_route_audit')
```

A custom output folder can be supplied:

```matlab
audit = auditMRLFESolverRoutes( ...
    'Mode', "full", ...
    'OutputFolder', fullfile(pwd, 'local_audit_results'));
```

## Compared routes

### Main GUI adapter route

```text
guiRunMRLFEModel
```

This captures the route currently used by the main forward interface and, indirectly, by SweepTool.

Expected behavior:

```text
etaS = 0  -> zero_viscosity_adaptive_atlas or zero_viscosity_adaptive_fallback
etaS > 0  -> viscous_unified_atlas
```

The route includes the Main GUI fast atlas preset and the zero-viscosity quality guard/fallback.

### FitTool fast atlas route

```text
mrlfeEvaluateFitModel
  -> mrlfeEvaluateAtlasFitModel
```

This is the route that must not be lost during restructuring.

Expected configuration:

```text
route family = atlas
preset       = fast_fit_atlas
A0 policy    = adaptivePhysicalTail
```

Expected path:

```text
etaS = 0  -> zero_viscosity_adaptive_atlas
etaS > 0  -> viscous_unified_atlas
```

### Direct unified-atlas route

```text
solveMRLFEAtlasUnified
```

This exposes the behavior of the currently named unified solver without Main GUI or FitTool wrappers.

Important known distinction:

```text
etaS = 0 -> elastic modal atlas
```

This differs from the zero-viscosity adaptive route currently used by Main GUI and FitTool.

### Legacy compute route

```text
computeMRLFE
```

This represents the older reference-based workflow still reachable indirectly through Rayleigh-Lamb integration, examples, diagnostics, and explicitly disabled atlas-fit routes.

The audit intentionally runs this route with unified atlas disabled and the conservative `delayedCut` policy.

## Case matrix

Quick mode evaluates:

| Branch | etaS | mu | Thickness | Frequency grid |
| --- | ---: | ---: | ---: | --- |
| A0Like | 0 | 75 kPa | 0.5 mm | 1–6 kHz, 10 points |
| S0Like | 0 | 75 kPa | 0.5 mm | 1–6 kHz, 10 points |
| A0Like | 0.05 Pa·s | 75 kPa | 0.5 mm | 1–6 kHz, 10 points |
| S0Like | 0.05 Pa·s | 75 kPa | 0.5 mm | 1–6 kHz, 10 points |

Full mode evaluates:

```text
branches:  A0Like, S0Like
etaS:      0, 0.05, 0.10 Pa·s
mu:        50, 75, 158, 250 kPa
thickness: 0.5 mm
frequency: 1–12 kHz, 20 points
```

The full matrix contains 24 physical cases and four route evaluations per case.

## Recorded evidence

For every route evaluation, the audit records:

```text
case identifier
branch
etaS
mu
thickness
requested route
actual route metadata
preset metadata
fallback state
elapsed time
valid count
valid fraction
last valid frequency
maximum relative Cp jump
error identifier
error message
```

For every pair of routes in the same physical case, it records:

```text
common valid point count
maximum absolute Cp difference
RMS Cp difference
maximum relative Cp difference
```

## Output files

```text
mrlfe_solver_route_cases.csv
mrlfe_solver_route_summary.csv
mrlfe_solver_route_pairwise.csv
mrlfe_solver_route_audit.mat
```

The MAT file preserves raw outputs under:

```matlab
audit.details
```

This permits inspection of route metadata, branch candidates, diagnostics, fallback state, and solver-specific fields without expanding the CSV schema.

## Interpretation rules

The audit does not assume that all current routes should agree.

A difference can indicate:

- an intentional branch-selection policy difference;
- a fast-versus-dense numerical approximation;
- a different zero-viscosity formulation;
- a hidden fallback;
- a grid-continuation sensitivity;
- a defect or stale route.

The first restructuring pass should preserve the FitTool fast-atlas baseline unless the audit demonstrates that it is incorrect.

## Required validation sequence

Run quick mode first:

```matlab
run_mrlfe_solver_route_audit
```

Review:

```matlab
MRLFESolverRouteAudit.routes
MRLFESolverRouteAudit.pairwise
```

Only if quick mode completes without infrastructure errors, run full mode:

```matlab
MRLFESolverRouteAuditFull = auditMRLFESolverRoutes('Mode', "full");
```

After both runs, retain the generated CSV and MAT files outside Git unless they are explicitly selected as validation fixtures.

## Current scope boundary

This branch must not yet:

- rename solver functions;
- move model folders;
- delete wrappers;
- change Main GUI or FitTool defaults;
- replace `fast_fit_atlas`;
- change `adaptivePhysicalTail`;
- remove `computeMRLFE` from Rayleigh-Lamb;
- rewrite metadata schemas;
- declare one route physically correct without numerical and external validation.

The evidence from this audit will determine the destructive restructuring plan.
