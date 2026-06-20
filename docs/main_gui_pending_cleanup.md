# Main GUI pending cleanup

This document records known cleanup items after the first Acoustoelastic IOP/HGO integration into `LambFundamental_GUI`.

## 1. Remove temporary helper bridges

Status: resolved for `getOptionValue`.

The temporary file below was removed:

```text
app/getOptionValue.m
```

The optional-field helper now lives locally inside `LambFundamental_GUI.m` as `getOptionValueLocal`, because it is currently only needed by that GUI file.

## 2. Rename atlas-related GUI labels

Current visible labels include:

```text
Compute AE atlasA0
atlas y-points
atlas minima
```

These names are functional but not ideal. `atlasA0` is a branch-selection or solution strategy, not a physical wave mode name. The UI should later distinguish:

```text
physical branch/result: A0-like phase-velocity curve
solver strategy: atlas tracking / atlas branch policy
numerical resolution: model-wide resolution preset
```

The labels should be revised after the numerical-control convention is defined.

## 3. Remove raw atlas numerical controls from the GUI

Current controls:

```text
atlas y-points
atlas minima
```

These controls must be removed from the user-facing GUI. They are solver-internal tuning variables and should not appear as independent model parameters.

The main GUI should expose model-neutral numerical controls consistent with the other models, for example:

```text
robustness preset
frequency range
frequency resolution
tracking/solver strictness, only if needed
```

The acoustoelastic implementation may still use internal atlas parameters, but they should be derived internally from the same model-neutral controls used by the rest of the app.

Target behavior:

```text
No raw atlasNumYPoints field in the GUI.
No raw atlasTopNMinima field in the GUI.
No model-specific numerical knobs unless there is a documented physical or numerical reason.
```

## 4. Investigate AE branch selection sensitivity

The current AE result may still be sensitive to the starting frequency or to the selected frequency grid. A suspicious symptom is a nearly constant or incorrectly tracked branch in some cases.

This needs solver-level investigation before further UI optimization. The investigation should check whether:

```text
- atlasA0 tracking is actually initialized from sufficiently low frequency;
- branch selection depends on the first frequency point;
- a constant or spurious branch is being selected under some parameter sets;
- robust mode only increases search density but does not increase the plotted/output frequency grid enough;
- frequency sampling is being fixed internally instead of following the GUI/requested resolution;
- branch identity diagnostics still agree with the official atlasA0 output.
```

Expected cleanup direction:

```text
- The GUI should pass a clear requested frequency grid or resolution policy.
- The solver should return output on that requested grid, unless an internal refinement grid is explicitly documented.
- Internal atlas search density should be decoupled from user-facing output resolution.
- The official output should not depend unexpectedly on where the requested frequency vector starts.
```

## 5. Standardize numerical-resolution policy across models

All model families should use structurally similar numerical controls unless a divergence is strictly necessary and documented.

Current concern:

```text
Rayleigh-Lamb and mRLFE use a general frequency setup and robustness options.
AE IOP/HGO exposes atlas-specific internals and may use fixed output point counts.
```

Required direction:

```text
Use shared controls for frequency range and output resolution.
Use robustness only as a preset for solver tolerances/search density.
Keep solver-specific internal parameters out of the GUI.
```

## 6. Improve responsive layout

The current GUI layout changes substantially across displays with different resolutions. The main causes are fixed pixel heights and dense control panels.

Later UI optimization should address:

```text
left panel width
model-specific tab height
scrollable or collapsible model panels
responsive row heights
screen-size-aware defaults
```

This should be treated as a UI layout task, separate from model integration.
