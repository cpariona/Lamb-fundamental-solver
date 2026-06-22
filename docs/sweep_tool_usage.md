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
| `mRLFE` | `etaS`, `mu`, `thickness` | `A0Like`, `S0Like` | Uses the mRLFE sweep adapter and `runParametricSweep`. |
| `Rayleigh-Lamb` | `thickness`, `mu` | `A0`, `S0` | Uses the Rayleigh-Lamb sweep adapter and the maintained `rl*` API. |
| `AE IOP/HGO` | `IOP`, `mu` | `atlasA0` | Uses the AE IOP/HGO sweep adapter and the maintained atlas branch policy. |

## Recommended quick checks

### mRLFE elastic check

Use:

```text
Model family: mRLFE
Sweep parameter: mu
Values: 60, 75
Model: Elastic real-k
Branch: A0Like
Robustness: Fast
```

Expected outcome:

- The sweep runs without an adapter error.
- The values are interpreted in kPa and converted to solver units by the registry scale.
- The summary table has two rows.
- `SweepToolOutput`, `SweepToolRequest`, `SweepToolNormalized`, `SweepToolResults`, and `SweepToolSummary` export to the base workspace.

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
