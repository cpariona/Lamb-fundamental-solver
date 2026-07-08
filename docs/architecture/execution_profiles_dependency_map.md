# Execution Profiles Dependency Map

## Main GUI

### Rayleigh-Lamb

```text
LambFundamental_GUI
  -> createAdvancedTab (default robustness = Balanced)
  -> readOptionsFromGui
  -> rlDefaultOptions(selected robustness)
  -> guiRunRayleighLambModel
  -> rlComputeFundamentalLambModes
  -> rlSolveFundamentalBranch
```

Overrides:

- `readOptionsFromGui` sets branch booleans from checkboxes.
- No atlas or optimizer profile applies.

### mRLFE

```text
LambFundamental_GUI
  -> createAdvancedTab (default robustness = Balanced)
  -> readOptionsFromGui
  -> rlDefaultOptions(selected robustness)
  -> readMRLFEParamsFromGui
  -> mrlfeUseUnifiedAtlasRoute = etaS > 0
  -> mrlfeA0Policy = adaptivePhysicalTail or UI value
  -> guiRunMRLFEModel
  -> mrlfeBuildGuiSolveRequest
  -> mrlfeSolve
  -> mrlfeBuildSeed
  -> mrlfeTrackBranchAdaptive
  -> mrlfeApplyTerminationPolicy
```

Overrides:

- `guiRunMRLFEModel` maps GUI inputs to the public request contract.
- The maintained mRLFE preset is public `fast`.
- A0Like uses `physicalTail`; S0Like uses `none`.
- Fallback policy is `none`.

### AE IOP/HGO

```text
LambFundamental_GUI
  -> createAdvancedTab (default robustness = Balanced)
  -> readOptionsFromGui
  -> guiBuildAcoustoelasticIOPHGOOptions(selected robustness)
  -> guiBuildAcoustoelasticIOPHGORequest
  -> guiRunAcoustoelasticIOPHGOModel
  -> solveAcoustoelasticIOPHGOBranch / atlasA0 solver
```

Overrides:

- AE mode disables RL and mRLFE compute flags.
- `atlasBranchPolicy` is `atlasA0`.

## SweepTool

### Rayleigh-Lamb

```text
SweepTool_GUI
  -> guiGetSweepRegistry (default Robustness = Balanced)
  -> buildControlsForActiveFamily
  -> guiBuildSweepRequest
  -> guiRunSweep
  -> guiRunRLSweep
  -> rlDefaultOptions(request.controls.robustness)
  -> runParametricSweep
  -> rlComputeFundamentalLambModes
```

Overrides:

- Adapter falls back to `Balanced` if controls omit robustness.
- Branch checkbox equivalent is derived from `request.branchName`.

### mRLFE

```text
SweepTool_GUI
  -> guiGetSweepRegistry (default Robustness = Fast)
  -> buildControlsForActiveFamily
  -> controls.mrlfeUseUnifiedAtlasRoute = true
  -> controls.mrlfeA0Policy = delayedCut/adaptivePhysicalTail
  -> guiBuildSweepRequest
  -> guiRunSweep
  -> guiRunMRLFESweep
  -> rlDefaultOptions(request.controls.robustness)
  -> runMRLFEGuiAdapterSweep
  -> guiRunMRLFEModel
  -> GUI mRLFE route policy
```

Overrides:

- Sweep values can overwrite `options.mrlfeParams.etaS`, which then recomputes `mrlfeUseUnifiedAtlasRoute = etaS > 0`.
- `guiRunMRLFEModel` applies GUI fast atlas presets after the sweep adapter builds base options.

### AE IOP/HGO

```text
SweepTool_GUI
  -> guiGetSweepRegistry (default Robustness = Fast; presets Fast/Balanced)
  -> buildControlsForActiveFamily
  -> controls.atlasNumYPoints = 600 if Balanced else 300
  -> controls.atlasTopNMinima = 16 if Balanced else 12
  -> guiBuildSweepRequest
  -> guiRunSweep
  -> guiRunAcoustoelasticIOPHGOSweep
  -> buildAcoustoelasticOptions
  -> aeRunSweep
```

Overrides:

- `guiRunAcoustoelasticIOPHGOSweep` starts from `defaultAcoustoelasticIOPHGOOptions`, not `aeDefaultSweepOptions`.
- The GUI controls are the effective atlas density source.

## FitTool

### Shared request pipeline

```text
FitTool_GUI
  -> guiBuildFitParameterState
  -> guiBuildFitParameterRequest
  -> guiResolveFitModelSetup (synthetic data only)
  -> guiBuildFitRequest
  -> guiRunFit
  -> model-specific fit adapter
```

`guiResolveFitModelSetup` centralizes physical parameters for synthetic generation. It does not centralize numerical execution profiles.

### Rayleigh-Lamb

```text
FitTool_GUI
  -> guiGetFitRegistry (default Robustness = Fast)
  -> buildParameterConfig
  -> guiBuildFitRequest
  -> guiRunFit
  -> guiFitRLSolver
  -> rlDefaultOptions(request.controls.robustness)
  -> rlFitDispersionData
  -> rlEvaluateFitModel
```

Overrides:

- Adapter falls back to `Fast` if missing.
- Optimizer options are from `request.fitOptions` or `rlFitDispersionData` defaults.

### mRLFE

```text
FitTool_GUI
  -> guiGetFitRegistry (default Robustness = Fast; exposes Fast/Balanced/Robust)
  -> buildParameterConfig
  -> controls.mrlfeUseUnifiedAtlasRoute = true
  -> controls.mrlfeUseAtlasFitRoute = true
  -> controls.mrlfeA0Policy = UI value
  -> optimizer MaxIter=35, MaxFunEvals=80, TolX=1e-5
  -> guiBuildFitRequest
  -> guiRunFit
  -> guiFitMRLFESolver
  -> mrlfeDefaultSweepOptions(branchName, EtaS, UseUnifiedAtlasRoute, A0Policy)
  -> mrlfeFitDispersionData
  -> mrlfeEvaluateFitModel
  -> mrlfeEvaluateAtlasFitModel
  -> fast_fit_atlas
```

Overrides:

- `mrlfeDefaultSweepOptions` hard-codes `rlDefaultOptions("Fast")`.
- `guiFitMRLFESolver` sets `mrlfeFitAtlasPreset = "fast_fit_atlas"`.
- `mrlfeEvaluateAtlasFitModel` applies 260 scan points and candidates 5 by default.
- Legacy direct-viscous route is available only when atlas-fit routing and unified atlas routing are disabled.

### AE IOP/HGO

```text
FitTool_GUI
  -> guiGetFitRegistry (default Robustness = Fast; exposes Fast/Balanced/Robust)
  -> buildParameterConfig
  -> controls.atlasNumYPoints = 300
  -> controls.atlasTopNMinima = 12
  -> controls.atlasInitializationNumFrequencyPoints = 50
  -> optimizer MaxIter=10, MaxFunEvals=24, TolX=1e-3
  -> guiBuildFitRequest
  -> guiRunFit
  -> guiFitAcoustoelasticIOPHGOSolver
  -> aeDefaultSweepOptions(request.controls.robustness)
  -> controls override atlas density
  -> aeFitDispersionData
  -> aeEvaluateFitModel
```

Overrides:

- GUI controls overwrite atlas density after `aeDefaultSweepOptions`.
- Thickness fitting changes only optimizer `TolX` to `1e-8`.

## Requested vs effective matrix

| Model/case | Surface | Requested | Effective profile | Final options summary | Route | Atlas preset | Branch policy | Fallback | Metadata | Silent override |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RL A0/S0 | Main | Fast/Balanced/Robust | same | RL grid/search per `rlDefaultOptions` | direct | none | branch flags | no | raw options in GUI diagnostics | no |
| RL A0/S0 | Sweep | Fast/Balanced/Robust | same | RL grid/search per `rlDefaultOptions` | direct | none | branch name | no | request/rawResults | no |
| RL A0/S0 | Fit | Fast/Balanced/Robust | same | RL grid/search per `rlDefaultOptions`; optimizer separate | fit evaluator | none | branch name | prediction fallback rejected by tests | normalized fit result | no |
| RL A0/S0 | API | Fast/Balanced/Robust | same | direct `rlDefaultOptions` | direct | none | caller flags | no | raw result | no |
| mRLFE A0Like etaS=0 | Main | selected robustness | selected RL seed plus GUI fast atlas | GUI fast atlas scan 260 unless disabled | zero-viscosity adaptive atlas | `fast_zero_viscosity_adaptive` | `adaptivePhysicalTail` | elastic reference possible | `mrlfeGuiActualRoute`, preset, quality | yes, atlas density not tied to selected robustness |
| mRLFE A0Like etaS>0 | Main | selected robustness | selected RL seed plus GUI fast atlas | unified atlas scan 260 unless disabled | viscous unified atlas | `fast_viscous` | `adaptivePhysicalTail` | no standard fallback | GUI metadata | yes |
| mRLFE S0Like etaS=0 | Main | selected robustness | selected RL seed plus GUI fast atlas | adaptive atlas scan 260 unless disabled | zero-viscosity adaptive atlas | `fast_zero_viscosity_adaptive` | S0 adaptive continuation | elastic reference possible via quality route | GUI metadata | yes |
| mRLFE S0Like etaS>0 | Main | selected robustness | selected RL seed plus GUI fast atlas | unified atlas scan 260 unless disabled | viscous unified atlas | `fast_viscous` | S0 unified atlas | no standard fallback | GUI metadata | yes |
| mRLFE A0Like/S0Like | Sweep | Fast/Balanced/Robust | requested RL seed plus GUI fast atlas | same as Main GUI route | GUI adapter sweep | GUI fast presets | A0 policy from SweepTool | zero-eta fallback possible | `guiResults` metadata | yes |
| mRLFE A0Like etaS=0 | Fit | Fast/Balanced/Robust | Fast | `mrlfeDefaultSweepOptions` Fast; `fast_fit_atlas` 260 | zero-viscosity adaptive atlas fit | `fast_fit_atlas` | `adaptivePhysicalTail` | no production fallback, interpolation may drop invalids | `evaluationPath`, `fitPerformanceDefaults` | yes |
| mRLFE A0Like etaS>0 | Fit | Fast/Balanced/Robust | Fast | `mrlfeDefaultSweepOptions` Fast; `fast_fit_atlas` 260 | viscous unified atlas | `fast_fit_atlas` | `adaptivePhysicalTail` | no | routePolicy/evaluationPath | yes |
| mRLFE S0Like etaS=0 | Fit | Fast/Balanced/Robust | Fast | `fast_fit_atlas` 260 | zero-viscosity adaptive atlas fit | `fast_fit_atlas` | S0 adaptive continuation | no | routePolicy/evaluationPath | yes |
| mRLFE S0Like etaS>0 | Fit | Fast/Balanced/Robust | Fast | `fast_fit_atlas` 260 | viscous unified atlas | `fast_fit_atlas` | S0 unified atlas | no | routePolicy/evaluationPath | yes |
| AE atlasA0 | Main | Fast/Balanced/Robust | AE atlas density from selected profile | 300/12, 600/16, or 900/20 | atlasA0 | AE default sweep option | atlasA0 | solver-specific invalid masks | raw/metadata | semantic mismatch only |
| AE atlasA0 | Sweep | Fast/Balanced | same for exposed values | Fast 300/12; Balanced 600/16 | atlasA0 sweep | controls | atlasA0 | invalid masks | sweep summary | Robust unavailable |
| AE atlasA0 | Fit | Fast/Balanced/Robust | usually 300/12/50 from GUI | `atlasInitializationNumFrequencyPoints=50`; optimizer 10/24 | atlasA0 fit | Fit GUI controls | atlasA0 | invalid masks | normalized fit result | yes |
| AE atlasA0 | API | Fast/Balanced/Robust | same | `aeDefaultSweepOptions` 300/12, 600/16, 900/20 | atlasA0 | AE default sweep option | atlasA0 | invalid masks | raw result | no |
