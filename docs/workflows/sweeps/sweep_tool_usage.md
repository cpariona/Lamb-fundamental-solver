# SweepTool usage notes

`SweepTool_GUI` is the registry-driven interface for one-parameter sweep workflows.

## Launch

```matlab
clear functions
rehash toolboxcache
startup
SweepTool_GUI
```

## Current visible families

| Family | Parameters | Branches | Notes |
| --- | --- | --- | --- |
| `mRLFE` | `etaS`, `mu`, `thickness` | `A0Like`, `S0Like` | Routes each sweep point directly through `mrlfeSolve` using the public `fast` preset, adaptive selection, and no fallback. A0Like uses `physicalTail` termination; S0Like uses no additional termination. |
| `Rayleigh-Lamb` | `thickness`, `mu` | `A0`, `S0` | Uses the Rayleigh-Lamb sweep adapter and the maintained `rl*` API. |
| `AE IOP/HGO` | `IOP`, `mu` | `atlasA0` | Uses the AE IOP/HGO sweep adapter and the maintained atlas branch policy. |

## Recommended quick checks

### mRLFE real-k check

Use:

```text
Model family: mRLFE
Sweep parameter: mu
Values: 60, 75
Model: mRLFE real-k
Branch: A0Like
Execution profile: Fast
etaS: 0.05 Pa*s
A0 atlas policy: adaptivePhysicalTail
```

Expected outcome:

- The sweep runs without an adapter error.
- The values are interpreted in kPa and converted to solver units by the registry scale.
- The summary table has two rows.
- The normalized model name is `mRLFERealK`.
- `SweepToolOutput.atlasPolicy.guiRoutePolicy` is `mrlfeSolve`.
- `SweepToolOutput.atlasPolicy.effectiveA0Policy` is `physicalTail`.
- `SweepToolOutput.metadata.effectiveNumericalPresets` contains `fast`.
- `SweepToolOutput.metadata.fallbackPolicies` contains `none`.
- `SweepToolOutput`, `SweepToolRequest`, `SweepToolNormalized`, `SweepToolResults`, and `SweepToolSummary` export to the base workspace.

### mRLFE etaS check

Use:

```text
Model family: mRLFE
Sweep parameter: etaS
Values: 0, 0.05
Model: mRLFE real-k
Branch: A0Like
Execution profile: Fast
A0 atlas policy: adaptivePhysicalTail
```

Expected outcome:

- `etaS = 0` uses the public elastic adaptive engine.
- `etaS > 0` uses the public viscoelastic adaptive engine.
- The normalized model name remains `mRLFERealK` for both cases.
- The exported `SweepToolOutput.metadata.internalEngines` reports every effective engine present in the sweep, so mixed zero/positive-viscosity sweeps report both `elastic_adaptive` and `viscoelastic_adaptive`.

### mRLFE adaptive A0 policy check

Use:

```text
Model family: mRLFE
Sweep parameter: etaS
Values: 0.05
Model: mRLFE real-k
Branch: A0Like
Execution profile: Fast
A0 atlas policy: adaptivePhysicalTail
```

Expected outcome:

- The sweep completes without adapter errors.
- The summary table has one row.
- `SweepToolOutput.atlasPolicy.effectiveA0Policy` is `physicalTail`.
- `SweepToolOutput.rawResults.points{1}.termination.policy` is `physicalTail`.
- This check verifies routing only. It does not prove physical validity of the adaptive policy for a given experiment.

### Rayleigh-Lamb thickness check

Use:

```text
Model family: Rayleigh-Lamb
Sweep parameter: thickness
Values: 0.3, 0.4
Model: Rayleigh-Lamb
Branch: A0
Execution profile: Fast
```

Expected outcome:

- The sweep runs through `guiRunSweep` and the Rayleigh-Lamb adapter.
- The values are interpreted in mm and converted to solver units by the registry scale.
- The summary table has two rows.
- The normalized output has one A0 curve per sweep value.

### Rayleigh-Lamb stiffness check

Use:

```text
Model family: Rayleigh-Lamb
Sweep parameter: mu
Values: 60, 75
Model: Rayleigh-Lamb
Branch: A0
Execution profile: Fast
```

Expected outcome:

- The sweep runs through the same Rayleigh-Lamb adapter.
- The values are interpreted in kPa and converted to solver units by the registry scale.
- `E`, `lambda_Lame`, `K`, `CT`, and `CL` are derived by the material helper from `mu`, `nu`, and `rho`.

### AE IOP/HGO IOP check

Use:

```text
Model family: AE IOP/HGO
Sweep parameter: IOP
Values: 10, 15
Model: AE IOP/HGO
Branch: atlasA0
Execution profile: Fast
```

Expected outcome:

- The sweep runs through `guiRunSweep` and the AE IOP/HGO adapter.
- The summary table has two rows.
- The normalized output has one curve per sweep value.

### AE IOP/HGO mu check

Use:

```text
Model family: AE IOP/HGO
Sweep parameter: mu
Values: 25, 50
Model: AE IOP/HGO
Branch: atlasA0
Execution profile: Fast
```

Expected outcome:

- The sweep runs through the same AE IOP/HGO adapter.
- The values are interpreted in kPa and converted to solver units by the registry scale.

## Architecture contract

The GUI should continue to follow this sequence:

```text
SweepTool_GUI
    -> guiGetSweepRegistry
    -> guiBuildSweepRequest
    -> guiRunSweep
    -> model-specific sweep adapter
    -> model-specific normalizer
    -> guiPlotSweepResult
```

Current model adapters:

```matlab
guiRunMRLFESweep
guiRunRLSweep
guiRunAcoustoelasticIOPHGOSweep
```

For mRLFE, `guiRunMRLFESweep` maps each sweep point with
`mrlfeBuildSweepSolveRequest` and calls `mrlfeSolve` once per point. SweepTool
does not call `guiRunMRLFEModel`, inherit Main GUI fallback, or choose
historical GUI route names. Main GUI mRLFE solving remains a separate migration
target.

The maintained mRLFE SweepTool route uses:

```text
numerical preset    fast
selection strategy  adaptive
fallback policy     none
A0Like termination  physicalTail
S0Like termination  none
```

Each point stores its public model result in `rawResults.points{i}.modelResult`
and exposes compatibility aliases for plotting and export:

```matlab
frequency_Hz
phaseVelocity_mps
validMask
status
errorIdentifier
errorMessage
```

Aggregate metadata reports unique effective values across all points rather
than treating the first point as representative:

```matlab
metadata.effectiveNumericalPresets
metadata.internalEngines
metadata.terminationPolicies
metadata.fallbackPolicies
metadata.anyFallbackApplied
metadata.pointCount
metadata.failedPointCount
metadata.validPointCount
```

Zero-viscosity A0Like SweepTool results may differ from the old Main GUI route
when the old route would have used zero-viscosity fallback. That is an expected
architectural correction; the production reference for SweepTool is now
`mrlfeSolve` with `fallback.policy = "none"`.

Current model normalizers:

```matlab
guiNormalizeMRLFESweep
guiNormalizeRLSweep
guiNormalizeAcoustoelasticIOPHGOSweep
```

The GUI should not call scripts under `examples/` directly. Example scripts and GUI callbacks should share maintained backend utilities or model APIs through adapters.

mRLFE atlas policy integration is documented in:

```text
docs/workflows/gui/mrlfe_atlas_policy_integration.md
```

## Export contract

The export button writes:

```matlab
SweepToolOutput
SweepToolRequest
SweepToolNormalized
SweepToolResults
SweepToolSummary
SweepToolModelName
SweepToolBranchName
```

`SweepToolNormalized` is the preferred object for plotting and downstream app work. `SweepToolResults` is preserved for raw diagnostics and compatibility.
