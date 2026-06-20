# GUI integration audit

This document records the maintained GUI integration status after the SweepTool cleanup.

## Active app structure

```text
app/
├─ LambFundamental_GUI.m
├─ SweepTool_GUI.m
├─ sweep/
│  ├─ guiGetSweepRegistry.m
│  ├─ guiGetSweepFamilyConfig.m
│  ├─ guiGetSweepParameterConfig.m
│  ├─ guiFormatSweepValues.m
│  ├─ guiBuildSweepRequest.m
│  ├─ guiRunSweep.m
│  └─ guiPlotSweepResult.m
└─ adapters/
   ├─ guiRunRayleighLambModel.m
   ├─ guiRunMRLFEModel.m
   ├─ guiRunAcoustoelasticIOPHGOModel.m
   ├─ guiRunMRLFESweep.m
   ├─ guiNormalizeMRLFESweep.m
   ├─ guiRunAcoustoelasticIOPHGOSweep.m
   └─ guiNormalizeAcoustoelasticIOPHGOSweep.m
```

## Main GUI status

`LambFundamental_GUI` still owns the main interactive single-case workflow. It keeps both raw and normalized outputs:

```matlab
lastResults
lastGuiResult
```

The raw output is preserved for diagnostics and compatibility. The normalized output is preferred for plotting and table export.

## SweepTool status

`SweepTool_GUI` is registry-driven and supports visible one-parameter sweeps for:

```text
mRLFE
AE IOP/HGO
```

Current visible sweep parameters:

```text
mRLFE: etaS, E, thickness
AE IOP/HGO: IOP, mu
```

## Dependency policy

App code should call maintained model APIs or analysis helpers through adapters. It should not call scripts under `examples/` directly.

Current backend paths:

```text
mRLFE sweep:
SweepTool_GUI -> guiRunSweep -> guiRunMRLFESweep -> runParametricSweep

AE IOP/HGO sweep:
SweepTool_GUI -> guiRunSweep -> guiRunAcoustoelasticIOPHGOSweep -> aeRunSweep -> aeSummarizeSweep
```

## Remaining cleanup candidates

- Main GUI plotting still contains some legacy fallback paths.
- Main GUI mRLFE policy still has some logic in callbacks.
- Some plot styling issues remain in `SweepTool_GUI`; these are UI polish, not structural blockers.
- `app/createAdvancedTab.m` still has stale text mentioning `defaultOptions.m`; this should be corrected in a later UI-copy cleanup.

## Validation

Recommended validation:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
SweepTool_GUI
```

Manual SweepTool checks are documented in:

```text
docs/sweep_tool_usage.md
```
