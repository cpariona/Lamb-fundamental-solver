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
| `mRLFE` | `etaS`, `mu`, `thickness` | `A0Like`, `S0Like` | Uses the unified `mRLFE real-k` path. `etaS = 0` is the elastic limit; `etaS > 0` is the viscous case. The A0 atlas policy selector exposes `delayedCut` and `adaptivePhysicalTail`. |
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
Robustness: Fast
etaS: 0.05 Pa*s
A0 atlas policy: delayedCut
```

Expected outcome:

- The sweep runs without an adapter error.
- The values are interpreted in kPa and converted to solver units by the registry scale.
- The summary table has two rows.
- The normalized model name is `mRLFERealK`.
- `SweepToolOutput.atlasPolicy.mrlfeUseUnifiedAtlasRoute` is `true`.
- `SweepToolOutput.atlasPolicy.mrlfeA0Policy` matches the selected A0 policy.
- `SweepToolOutput`, `SweepToolRequest`, `SweepToolNormalized`, `SweepToolResults`, and `SweepToolSummary` export to the base workspace.

### mRLFE etaS check

Use:

```text
Model family: mRLFE
Sweep parameter: etaS
Values: 0, 0.05
Model: mRLFE real-k
Branch: A0Like
Robustness: Fast
A0 atlas policy: delayedCut
```

Expected outcome:

- `etaS = 0` gives the elastic fluid-loaded limit.
- `etaS > 0` uses the same mRLFE real-k model with shear viscosity.
- The normalized model name remains `mRLFERealK` for both cases.
- The exported `SweepToolOutput.atlasPolicy` reports the selected atlas route and A0 policy.

### mRLFE adaptive A0 policy check

Use:

```text
Model family: mRLFE
Sweep parameter: etaS
Values: 0.05
Model: mRLFE real-k
Branch: A0Like
Robustness: Fast
A0 atlas policy: adaptivePhysicalTail
```

Expected outcome:

- The sweep completes without adapter errors.
- The summary table has one row.
- `SweepToolOutput.atlasPolicy.mrlfeA0Policy` is `adaptivePhysicalTail`.
- This check verifies routing only. It does not prove physical validity of the adaptive policy for a given experiment.

### Rayleigh-Lamb thickness check

Use:

```text
Model family: Rayleigh-Lamb
Sweep parameter: thickness
Values: 0.3, 0.4
Model: Rayleigh-Lamb
Branch: A0
Robustness: Balanced
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
Robustness: Balanced
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
Robustness: Fast
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
Robustness: Fast
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

Current model normalizers:

```matlab
guiNormalizeMRLFESweep
guiNormalizeRLSweep
guiNormalizeAcoustoelasticIOPHGOSweep
```

The GUI should not call scripts under `examples/` directly. Example scripts and GUI callbacks should share maintained backend utilities or model APIs through adapters.

mRLFE atlas policy integration is documented in:

```text
docs/gui/mrlfe_atlas_policy_integration.md
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
