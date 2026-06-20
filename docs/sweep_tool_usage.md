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
| `mRLFE` | `etaS`, `E`, `thickness` | `A0Like`, `S0Like` | Uses the mRLFE sweep adapter and `runParametricSweep`. |
| `AE IOP` | `IOP`, `mu` | `atlasA0` | Uses the AE sweep adapter and the maintained atlas branch policy. |

## Recommended quick checks

### mRLFE elastic check

Use:

```text
Model family: mRLFE
Sweep parameter: E
Values: 50, 100
Model: Elastic real-k
Branch: A0Like
Robustness: Fast
```

Expected outcome:

- The sweep runs without an adapter error.
- The summary table has two rows.
- `SweepToolOutput`, `SweepToolRequest`, `SweepToolNormalized`, `SweepToolResults`, and `SweepToolSummary` export to the base workspace.

### AE IOP check

Use:

```text
Model family: AE IOP
Sweep parameter: IOP
Values: 10, 15
Model: AE IOP
Branch: atlasA0
Robustness: Fast
```

Expected outcome:

- The sweep runs through `guiRunSweep` and the AE adapter.
- The summary table has two rows.
- The normalized output has one curve per sweep value.

### AE mu check

Use:

```text
Model family: AE IOP
Sweep parameter: mu
Values: 25, 50
Model: AE IOP
Branch: atlasA0
Robustness: Fast
```

Expected outcome:

- The sweep runs through the same AE adapter.
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
