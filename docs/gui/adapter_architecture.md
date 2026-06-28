### GUI adapter architecture

This document records the maintained GUI adapter structure after the SweepTool refactor.

### Main GUI flow

```text
LambFundamental_GUI
    -> GUI request struct
    -> app/adapters/guiRun*Model
    -> raw solver result
    -> app/adapters/guiNormalizeRawResult
    -> normalized branches
    -> plotting/export
```

The main GUI keeps both raw and normalized result states:

```matlab
lastResults
lastGuiResult
```

`lastResults` is kept for compatibility and diagnostics. `lastGuiResult` is the preferred GUI-facing structure for plotting and table export.

### mRLFE atlas policy integration

The mRLFE GUI path exposes the unified real-k atlas route and A0 policy selector through adapters rather than by calling solver internals directly.

The integration contract is documented in:

```text
docs/gui/mrlfe_atlas_policy_integration.md
```

The maintained GUI-facing mRLFE policy fields are:

```matlab
mrlfeUseUnifiedAtlasRoute
mrlfeA0Policy
```

The supported A0 policies are:

```matlab
"delayedCut"
"adaptivePhysicalTail"
```

### SweepTool flow

```text
SweepTool_GUI
    -> guiGetSweepRegistry
    -> guiBuildSweepRequest
    -> guiRunSweep
    -> model-specific sweep adapter
    -> model-specific sweep normalizer
    -> guiPlotSweepResult
```

`SweepTool_GUI` should not call scripts under `examples/` directly.

### Sweep registry

The registry entrypoint is:

```text
app/sweep/guiGetSweepRegistry.m
```

Visible families:

```text
mRLFE
    parameters: etaS, mu, thickness
    branches: A0Like, S0Like

Rayleigh-Lamb
    parameters: thickness, mu
    branches: A0, S0

AE IOP/HGO
    parameters: IOP, mu
    branch: atlasA0
```

The registry owns GUI-facing labels, default values, display units, and display-to-solver scales.

### Sweep adapters

Current sweep adapters:

```text
app/adapters/guiRunMRLFESweep.m
app/adapters/guiNormalizeMRLFESweep.m
app/adapters/guiRunRLSweep.m
app/adapters/guiNormalizeRLSweep.m
app/adapters/guiRunAcoustoelasticIOPHGOSweep.m
app/adapters/guiNormalizeAcoustoelasticIOPHGOSweep.m
```

All new sweep-capable families should follow the same pair pattern:

```text
guiRun<ModelFamily>Sweep
guiNormalize<ModelFamily>Sweep
```

### Normalized sweep curve schema

`guiPlotSweepResult` expects:

```matlab
normalized.curves(i).label
normalized.curves(i).frequency_Hz
normalized.curves(i).Cp_mps
normalized.curves(i).validMask
normalized.curves(i).lastValidFrequency_Hz
normalized.summaryTable
```

### Export contract

SweepTool exports:

```matlab
SweepToolOutput
SweepToolRequest
SweepToolNormalized
SweepToolResults
SweepToolSummary
SweepToolModelName
SweepToolBranchName
```

`SweepToolNormalized` is preferred for app-level plotting and downstream workflows. `SweepToolResults` is preserved for raw diagnostics and compatibility.
