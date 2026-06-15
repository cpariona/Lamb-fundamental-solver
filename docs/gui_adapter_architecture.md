### GUI adapter architecture

This document summarizes the current GUI architecture after the refactor that introduced normalized adapter outputs. The goal is to keep the interactive app usable while progressively decoupling plotting and export logic from backend-specific raw solver structures.

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

The GUI export currently sends the following objects to the MATLAB base workspace:

```matlab
LambResults
GuiResults
GuiBranchTables
```

`LambResults` is the raw result. `GuiResults` is the normalized adapter result. `GuiBranchTables` is the table-oriented normalized export.

### Cache behavior

The GUI contains cache paths for avoiding unnecessary recomputation:

```text
cache: reused previous results
cache: reused selected Rayleigh-Lamb seed(s)
cache: reused selected elastic mRLFE branch(es)
```

After the normalized plotting refactor, cache paths regenerate `lastGuiResult` from the updated `lastResults` using:

```matlab
guiNormalizeRawResult(lastResults, "cache...")
```

This preserves normalized plotting/export even when the backend computation is partially reused.

### Current tests

The adapter architecture is covered by:

```text
tests/test_gui_normalized_adapters_smoke.m
```

This smoke test validates:

```text
guiRunRayleighLambModel
guiRunMRLFEModel
guiNormalizeRawResult
guiGetNormalizedBranchPlotData
guiNormalizedBranchesToTables
```

It checks that Rayleigh-Lamb produces normalized `A0` and `S0` branches, that mRLFE elastic produces an `A0Like` branch, that mRLFE does not duplicate the elastic branch under the compatibility alias `mRLFERealK`, that plot data are valid, and that normalized branch tables contain the expected core columns.

The test is called from:

```text
tests/run_all_smoke_tests.m
```

### Current architectural status

The current state is a stable transition architecture:

```text
GUI controls
    -> model adapters
        -> maintained backend solvers
            -> raw results
                -> normalized GUI result
                    -> plotting/export/tests
```

Raw-result compatibility has not been removed. This is intentional. It reduces risk while the GUI migrates toward normalized plotting/export.

### Next planned GUI step

The next functional step is to connect the acoustoelastic IOP/HGO model to the GUI through:

```text
app/adapters/guiRunAcoustoelasticIOPHGOModel.m
```

That step should be done after confirming that the current normalized Rayleigh-Lamb and mRLFE GUI paths remain stable.

The expected direction is:

```text
1. Add minimal acoustoelastic GUI controls.
2. Build a GUI request for the acoustoelastic adapter.
3. Normalize the acoustoelastic branch output to the same branch schema.
4. Reuse the existing normalized plotting and export paths.
5. Add an acoustoelastic GUI adapter smoke test.
```
