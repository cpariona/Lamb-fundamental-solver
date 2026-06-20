### GUI adapter architecture

This document summarizes the current GUI architecture after the refactor that introduced normalized adapter outputs and the sweep registry. The goal is to keep the interactive app usable while progressively decoupling plotting and export logic from backend-specific raw solver structures.

### Current high-level flow

```text
LambFundamental_GUI.m
        |
        v
GUI request struct
        |
        v
app/adapters/guiRun*Model.m
        |
        v
raw solver result
        |
        v
app/adapters/guiNormalizeRawResult.m
        |
        v
GuiResults.branches
        |
        +--> normalized plotting
        +--> normalized export tables
        +--> smoke tests
```

The GUI still keeps the raw result in `lastResults` for compatibility with existing diagnostics, raw workspace export, and legacy fallback logic. In parallel, it keeps the normalized adapter result in `lastGuiResult`.

### Sweep GUI flow

`app/SweepTool_GUI.m` now uses a registry-driven flow:

```text
SweepTool_GUI.m
        |
        v
app/sweep/guiGetSweepRegistry.m
        |
        v
app/sweep/guiGetSweepFamilyConfig.m
app/sweep/guiGetSweepParameterConfig.m
        |
        v
app/sweep/guiBuildSweepRequest.m
        |
        v
app/sweep/guiRunSweep.m
        |
        v
app/adapters/guiRunMRLFESweep.m
        |
        v
analysis/runParametricSweep.m
        |
        v
app/adapters/guiNormalizeMRLFESweep.m
        |
        v
app/sweep/guiPlotSweepResult.m
```

The sweep GUI no longer hardcodes parameter defaults, display units, or display-to-solver scaling inside the parameter-change callback. Those values are provided by `guiGetSweepRegistry`.

### Main GUI state

`app/LambFundamental_GUI.m` currently maintains two complementary result states:

```matlab
lastResults
lastGuiResult
```

`lastResults` is the raw solver result returned by the maintained backend. It preserves the historical schema used by earlier plotting, diagnostics, and export code.

`lastGuiResult` is the normalized GUI-facing result. It contains a common branch schema independent of whether the source model is Rayleigh-Lamb or mRLFE.

The current transition state is intentional:

```text
lastResults     -> compatibility, diagnostics, legacy fallback, raw export
lastGuiResult   -> normalized plotting, normalized tables, future GUI model integration
```

### Adapter entrypoints

The GUI-facing adapter entrypoints are:

```text
app/adapters/guiRunRayleighLambModel.m
app/adapters/guiRunMRLFEModel.m
app/adapters/guiRunAcoustoelasticIOPHGOModel.m
```

`guiRunRayleighLambModel` prepares Rayleigh-Lamb parameters/options, calls the maintained `rl*` API, and returns a normalized GUI result.

`guiRunMRLFEModel` prepares the Rayleigh-Lamb seed branches and mRLFE options, calls the maintained mRLFE workflow through the existing `rl*` surface, and returns a normalized GUI result.

`guiRunAcoustoelasticIOPHGOModel` exists as the GUI-facing entrypoint for the acoustoelastic IOP/HGO model. At this stage, it is available on the path but is not yet connected to controls in the main GUI.

The sweep-specific adapter entrypoints are:

```text
app/adapters/guiRunMRLFESweep.m
app/adapters/guiNormalizeMRLFESweep.m
```

New sweep-capable model families should follow the same pair pattern:

```text
app/adapters/guiRun<ModelFamily>Sweep.m
app/adapters/guiNormalize<ModelFamily>Sweep.m
```

### Sweep registry

The registry entrypoint is:

```text
app/sweep/guiGetSweepRegistry.m
```

Current registry contents:

```text
modelFamily = "mrlfe"
model labels = ["Viscoelastic real-k", "Elastic real-k"]
branches = ["A0Like", "S0Like"]
robustness presets = ["Fast", "Balanced", "Robust"]
parameters = ["etaS", "E", "thickness"]
```

Each parameter config provides:

```matlab
parameter.id
parameter.label
parameter.defaultValuesDisplay
parameter.displayUnit
parameter.displayScale
parameter.helpText
```

`displayScale` converts displayed GUI values to solver units. For example:

```text
etaS       display Pa*s -> solver Pa*s   scale 1
E          display kPa  -> solver Pa     scale 1e3
thickness  display mm   -> solver m      scale 1e-3
```

### Shared raw-result normalization

The common normalization helper is:

```text
app/adapters/guiNormalizeRawResult.m
```

Its role is to convert maintained raw solver outputs into the normalized GUI schema.

For Rayleigh-Lamb results, it reads:

```matlab
rawResult.modes.A0
rawResult.modes.S0
```

and converts them to normalized branches with:

```matlab
modelName = "RayleighLamb"
branchName = "A0" or "S0"
```

For mRLFE results, it reads:

```matlab
rawResult.models.mRLFEElasticRealK.branches
rawResult.models.mRLFEHanViscoRealK.branches
```

and converts them to normalized branches such as:

```matlab
modelName = "mRLFEElasticRealK"
branchName = "A0Like" or "S0Like"

modelName = "mRLFEHanViscoRealK"
branchName = "A0Like" or "S0Like"
```

The compatibility alias `mRLFERealK` is deliberately excluded when `mRLFEElasticRealK` exists, to avoid duplicated elastic branches in normalized plotting and export.

### Normalized branch schema

Each normalized branch follows this common structure:

```matlab
branch.modelName
branch.branchName
branch.frequency
branch.phaseVelocity
branch.wavenumber
branch.kThickness
branch.metadata
branch.diagnostics
```

The common physical quantities are:

```text
frequency       frequency vector [Hz]
phaseVelocity   phase velocity Cp [m/s]
wavenumber      wavenumber k [1/m]
kThickness      nondimensional k * thickness [-]
```

Diagnostics may include fields such as:

```matlab
branch.diagnostics.valid
branch.diagnostics.validCp
branch.diagnostics.residual
branch.diagnostics.objective
branch.diagnostics.pointStatus
```

Not every backend provides every diagnostic field. Plotting and table export helpers should therefore treat diagnostic fields as optional.

### Normalized plotting helpers

The main plotting helper is:

```text
app/adapters/guiGetNormalizedBranchPlotData.m
```

It converts one normalized branch into plot-ready data:

```matlab
plotData.x
plotData.y
plotData.validMask
plotData.xLabel
plotData.yLabel
plotData.modelName
plotData.branchName
plotData.displayName
```

It supports the same x-axis modes exposed by the GUI:

```text
frequency
angularFrequency
wavenumber
kThickness
```

`LambFundamental_GUI.m` now attempts to plot from `lastGuiResult.branches` first. If no normalized result is available, it falls back to the legacy raw plotting path.

The sweep plot helper is:

```text
app/sweep/guiPlotSweepResult.m
```

It consumes only normalized sweep curves:

```matlab
normalized.curves(i).frequency_Hz
normalized.curves(i).Cp_mps
normalized.curves(i).validMask
normalized.curves(i).label
```

### Normalized export helpers

The normalized export helpers are:

```text
app/adapters/guiNormalizedBranchToTable.m
app/adapters/guiNormalizedBranchesToTables.m
```

`guiNormalizedBranchToTable` converts one branch into a table with core columns:

```matlab
ModelName
BranchName
Frequency_Hz
PhaseVelocity_mps
Wavenumber_1_per_m
kThickness
```

When diagnostics are available, extra columns can be added, for example:

```matlab
Valid
ValidCp
Residual
Objective
PointStatus
```

`guiNormalizedBranchesToTables` converts all branches in `GuiResults.branches` into a struct of tables keyed by valid MATLAB field names.

The main GUI export currently sends the following objects to the MATLAB base workspace:

```matlab
LambResults
GuiResults
GuiBranchTables
```

`LambResults` is the raw result. `GuiResults` is the normalized adapter result. `GuiBranchTables` is the table-oriented normalized export.

The sweep GUI export currently sends:

```matlab
SweepToolOutput
SweepToolRequest
SweepToolNormalized
SweepToolResults
SweepToolSummary
SweepToolModelName
SweepToolBranchName
```

### Cache behavior

The GUI contains cache paths for avoiding unnecessary recomputation:

```text
cache: reused previous results
cache: reused selected Rayleigh-Lamb seed(s)
cache: reused selected elastic mRLFE branch(es)
```
