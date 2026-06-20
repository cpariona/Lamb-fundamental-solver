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
numerical resolution: atlas search density and candidate count
```

The labels should be revised after the numerical-control convention is defined.

## 3. Standardize atlas numerical controls

Current controls:

```text
atlas y-points
atlas minima
```

These are solver-internal controls for atlas search density and candidate selection. They should not remain as raw internal variables in the user-facing GUI.

A later cleanup should map them to model-neutral controls compatible with the rest of the app, for example:

```text
robustness preset
frequency resolution
search density
tracking strictness
```

The final mapping should be defined before UI polish.

## 4. Improve responsive layout

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
