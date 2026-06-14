# GUI integration audit

This audit records the current state of the MATLAB GUI integration and proposes a low-risk path for connecting the GUI to maintained model APIs without calling scripts from `examples/`.

## Current GUI files

| File | Current role |
| --- | --- |
| `runApp.m` | Launch wrapper that calls `startup()` and then `LambFundamental_GUI()`. |
| `app/LambFundamental_GUI.m` | Main single-case GUI. Owns UI callbacks, reads controls into Rayleigh-Lamb parameter/options structs, runs Rayleigh-Lamb and mRLFE computations, plots results, exports workspace variables, and shows diagnostics. |
| `app/SweepTool_GUI.m` | Standalone mRLFE one-parameter sweep GUI. Builds sweep specs, calls analysis sweep utilities, plots sweep curves, and exports sweep outputs. |
| `app/createSetupTab.m` | Builds material, geometry, and frequency controls shared by the main GUI. |
| `app/createModelTabs.m` | Builds Rayleigh-Lamb and mRLFE model-selection controls. |
| `app/createAdvancedTab.m` | Builds robustness preset controls and numerical-settings notes. |
| `app/createPlotTab.m` | Builds plot visibility and axis controls. |

## Current model calls

### Main GUI

`app/LambFundamental_GUI.m` currently calls maintained Rayleigh-Lamb entrypoints directly:

```matlab
rlDefaultParams
rlDefaultOptions
rlComputeFundamentalLambModes
```

It also calls mRLFE support directly through the current maintained mRLFE API surface:

```matlab
defaultMRLFEParams
computeMRLFE
```

The main GUI does not currently call Acoustoelastic IOP/HGO functions.

### Sweep GUI

`app/SweepTool_GUI.m` currently calls Rayleigh-Lamb defaults and mRLFE defaults:

```matlab
rlDefaultParams
rlDefaultOptions
defaultMRLFEParams
```

It also calls analysis utilities rather than example scripts:

```matlab
runParametricSweep
summarizeParametricSweepBranch
```

The sweep GUI does not currently call Acoustoelastic IOP/HGO functions.

## Current assumptions

- The GUI assumes `startup()` has placed `app/`, `analysis/`, and the active `models/` tree on the MATLAB path. `runApp.m` satisfies this for the standard launch path.
- The main GUI assumes the Rayleigh-Lamb result shape returned by `rlComputeFundamentalLambModes`, including `results.grid`, `results.material`, `results.geometry`, `results.modes`, optional `results.approximations`, and optional `results.models`.
- The mRLFE plot/export paths assume model result fields named `mRLFEElasticRealK` and `mRLFEHanViscoRealK`, with branches named `A0Like` and `S0Like`.
- The main GUI still maintains a compatibility `mRLFE` result alias in `updateModelAliases`. This is internal to the GUI result struct and is not an `ae*` alias, but it is a compatibility assumption worth removing or formalizing in a future GUI adapter PR.
- `app/createPlotTab.m` keeps backward-compatible plot-control aliases `showMRLFEA0` and `showMRLFES0` for older GUI code paths. These aliases are local UI-handle aliases, not model API aliases.
- `app/createAdvancedTab.m` says detailed numerical tuning is configured in `defaultOptions.m`; that appears stale relative to the current `rlDefaultOptions` naming and should be cleaned up in a later app-text-only PR.
- The current GUI exposes Rayleigh-Lamb and mRLFE controls, but it has no Acoustoelastic IOP/HGO tab or callback path.

## Potential breakpoints

- **Solver logic is mixed into UI callbacks.** `app/LambFundamental_GUI.m` contains nested callback code that builds solver options, manages result caching, configures mRLFE real-k/Han options, calls model functions, plots, exports, and formats diagnostics. This makes future model integration riskier because UI state, solver policy, and plotting schema are tightly coupled.
- **Plotting logic is not fully separated from computation.** The main GUI plots directly from the raw solver result struct. This works today for Rayleigh-Lamb and mRLFE, but adding Acoustoelastic IOP/HGO will require either more raw-result special cases or a normalized GUI result layer.
- **mRLFE policy is embedded in the GUI.** The main GUI has nested helper functions that set detailed mRLFE tracker/scoring options. Those are application policy choices and should move behind a GUI adapter or an app-level model service before broadening the GUI to more models.
- **Acoustoelastic IOP/HGO is not reachable from the GUI.** The maintained long author-neutral API exists, but no current app controls call `defaultAcoustoelasticIOPHGOOptions`, `solveAcoustoelasticIOPHGOBranch`, `solveAcoustoelasticIOPHGOAtlasBranch`, or `solveAcoustoelasticIOPHGODispersion`.
- **Stale text references can confuse maintenance.** The `defaultOptions.m` mention in `createAdvancedTab.m` should be changed to `rlDefaultOptions` when app UI copy is next touched.
- **Path dependence is implicit.** Direct function calls are fine after `startup()`, but future adapters should include a small path smoke check to verify the GUI can resolve all active model entrypoints without relying on `examples/` scripts.

## Direct example-script usage

No files under `app/` currently call scripts from `examples/` directly. The sweep GUI uses `analysis/runParametricSweep` and `analysis/summarizeParametricSweepBranch`, which are maintained analysis utilities rather than example scripts.

## Current model accessibility

| Model family | GUI access today | Notes |
| --- | --- | --- |
| Rayleigh-Lamb | Yes | Main GUI directly calls `rlDefaultParams`, `rlDefaultOptions`, and `rlComputeFundamentalLambModes`. |
| mRLFE | Yes | Main GUI and sweep GUI use `defaultMRLFEParams`, `computeMRLFE`, and analysis sweep utilities. The main GUI only exposes elastic real-k and Han-style viscoelastic real-k workflows. |
| Acoustoelastic IOP/HGO | No | No current app tab, adapter, callback, or plotting path calls the maintained acoustoelastic API. |

## Recommended GUI integration architecture

Prefer an app-level adapter layer before adding new Acoustoelastic IOP/HGO controls:

```text
app/
├─ LambFundamental_GUI.m
├─ SweepTool_GUI.m
├─ createSetupTab.m
├─ createModelTabs.m
├─ createAdvancedTab.m
├─ createPlotTab.m
└─ adapters/
   ├─ guiRunRayleighLambModel.m
   ├─ guiRunMRLFEModel.m
   └─ guiRunAcoustoelasticIOPHGOModel.m
```

### Adapter responsibilities

#### `guiRunRayleighLambModel`

- Receive a GUI parameter struct in display-neutral solver units.
- Call `rlDefaultParams`, `rlDefaultOptions`, and `rlComputeFundamentalLambModes`.
- Return a normalized result struct for plotting and export.
- Keep Rayleigh-Lamb approximation handling behind the adapter so plot code does not need to know the raw solver result shape.

#### `guiRunMRLFEModel`

- Receive a GUI parameter struct in display-neutral solver units.
- Call `computeMRLFE` or maintained mRLFE solver entrypoints.
- Encapsulate the current elastic real-k and Han-style viscoelastic real-k GUI policy.
- Return a normalized result struct for plotting and export.
- Avoid renaming existing mRLFE model functions.

#### `guiRunAcoustoelasticIOPHGOModel`

- Receive a GUI parameter struct in display-neutral solver units.
- Call the existing long author-neutral Acoustoelastic IOP/HGO API, such as `defaultAcoustoelasticIOPHGOOptions`, `solveAcoustoelasticIOPHGOBranch`, `solveAcoustoelasticIOPHGOAtlasBranch`, or `solveAcoustoelasticIOPHGODispersion` as appropriate for the selected workflow.
- Do not introduce `ae*` aliases yet.
- Return a normalized result struct for plotting and export.

### Recommended normalized GUI result schema

Adapters should return either a scalar normalized result or an array/table of normalized branch results with these fields:

```matlab
result.modelName
result.branchName
result.frequency
result.phaseVelocity
result.wavenumber
result.kThickness
result.metadata
result.diagnostics
```

Recommended conventions:

- `modelName`: string scalar such as `"RayleighLamb"`, `"mRLFEElasticRealK"`, `"mRLFEHanViscoRealK"`, or `"AcoustoelasticIOPHGO"`.
- `branchName`: string scalar such as `"A0"`, `"S0"`, `"A0Like"`, `"S0Like"`, or an Acoustoelastic IOP/HGO branch label.
- `frequency`: column vector in Hz when available.
- `phaseVelocity`: column vector in m/s when available.
- `wavenumber`: column vector in `1/m`; may be real or complex depending on workflow, but plotting should explicitly select the component it displays.
- `kThickness`: column vector computed with the repository convention `k * thickness` where applicable.
- `metadata`: struct for material, geometry, options, display labels, source raw-result keys, and units.
- `diagnostics`: struct for validity masks, residuals, elapsed time, warnings, tracking summaries, and branch-quality summaries.

### GUI callback flow after adapters

1. UI callbacks read controls into a small GUI request struct.
2. Model adapters convert the request into solver parameters/options and run maintained APIs.
3. Adapters normalize raw solver outputs into the GUI result schema.
4. Plot code consumes only normalized results.
5. Export code can export both normalized results and optional raw results stored under `metadata.rawResult` or a similarly explicit field.

## Recommended next PRs

1. **Add app adapter skeletons and path smoke checks.** Add `app/adapters/` with `guiRunRayleighLambModel` and `guiRunMRLFEModel` first, plus a minimal GUI path smoke check that verifies adapter and model entrypoints resolve after `startup()`.
2. **Move main GUI compute paths behind adapters.** Refactor `app/LambFundamental_GUI.m` so callbacks create GUI request structs and adapters own solver calls/caching policy. Keep numerical behavior unchanged and preserve existing public model function names.
3. **Normalize plotting.** Update main GUI plotting/export code to consume normalized branch results while keeping raw solver output available for diagnostics/export during transition.
4. **Add Acoustoelastic IOP/HGO adapter only.** Implement `guiRunAcoustoelasticIOPHGOModel` against the long author-neutral API without creating `ae*` aliases.
5. **Add Acoustoelastic IOP/HGO UI controls.** Add a focused model tab after the adapter is covered by smoke tests. Keep the first UI limited to a known branch workflow rather than exposing every solver option.
6. **Clean stale UI copy and compatibility aliases.** Replace stale `defaultOptions.m` wording and decide whether internal `mRLFE` result aliases and old plot-control aliases are still needed.
