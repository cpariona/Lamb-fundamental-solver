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

Status: partially resolved.

The visible AE checkbox was changed from an atlas-policy name to a physical-result label:

```text
Compute AE A0-like
```

The visible panel title is now:

```text
Acoustoelastic A0-like setup
```

Remaining naming cleanup:

```text
- move remaining atlas-policy wording into diagnostics/help text only;
- keep user-facing labels focused on the physical A0-like phase-velocity output;
- keep solver-policy names such as atlasA0 inside options, diagnostics, and documentation.
```

## 3. Remove raw atlas numerical controls from the GUI

Status: resolved.

The following user-facing controls were removed from the AE IOP/HGO tab:

```text
atlas y-points
atlas minima
```

The atlas settings are now derived internally from the Advanced robustness preset through:

```text
app/adapters/guiBuildAcoustoelasticIOPHGOOptions.m
```

The temporary non-visible compatibility placeholders were also removed from `createModelTabs.m` after AE request construction was moved out of `LambFundamental_GUI.m`.

Target behavior remains:

```text
No raw atlasNumYPoints field in the GUI.
No raw atlasTopNMinima field in the GUI.
No model-specific numerical knobs unless there is a documented physical or numerical reason.
```

## 4. Investigate AE branch selection sensitivity

Status: partially resolved for output-grid start sensitivity.

The AE IOP/HGO wrapper now separates:

```text
internal atlas tracking grid
requested output frequency grid
```

The GUI receives `result.Cp` and `result.validCp` only on the requested output grid. Internal branch identity is selected on `result.trackingFrequency`.

A temporary diagnostic was added for this investigation:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_grid_start_sensitivity.m
```

Output path:

```text
Results/ae_iop_hgo/grid_start_sensitivity
```

Cleanup decision required after the solver issue is understood:

```text
- promote the diagnostic to maintained diagnostic evidence, or
- migrate reusable logic into analysis/acoustoelastic_iop_hgo/, or
- delete/archive the temporary diagnostic after preserving conclusions in documentation.
```

This file must not remain indefinitely as unclassified temporary code.

Remaining investigation items:

```text
- whether branch identity diagnostics still agree with the official atlasA0 output;
- whether the internal tracking grid is sufficient outside the current baseline case;
- whether the temporary diagnostic should become maintained evidence.
```

Solver-side residual waviness is tracked separately in:

```text
docs/acoustoelastic_iop_hgo/solver_pending_work.md
```

## 5. Standardize numerical-resolution policy across models

Status: partially resolved for the main GUI AE output curve.

The main GUI AE path now uses the shared frequency-vector builder through:

```text
app/adapters/guiBuildAcoustoelasticIOPHGORequest.m
```

rather than a model-specific 35/50/70 point logspace rule. This means the plotted AE curve uses the same requested output-grid density policy as Rayleigh-Lamb and mRLFE.

Current direction:

```text
Use shared controls for frequency range and output resolution.
Use robustness only as a preset for solver tolerances/search density.
Keep solver-specific internal parameters out of the GUI.
```

Remaining cleanup:

```text
- decide whether output frequency resolution should become an explicit GUI control instead of always using auto hybrid spacing;
- continue reducing model-specific logic inside LambFundamental_GUI.m when additional model families are added.
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

## 7. Split large GUI files into smaller components

Status: partially resolved for AE request construction.

AE-specific request and option construction now live in:

```text
app/adapters/guiBuildAcoustoelasticIOPHGORequest.m
app/adapters/guiBuildAcoustoelasticIOPHGOOptions.m
```

`LambFundamental_GUI.m` still contains plotting, status, diagnostics, export, and some model-routing logic. Future GUI work should avoid adding more solver-specific logic directly to this file.

Recommended direction:

```text
- Keep GUI callback code thin.
- Keep solver-specific options outside the main GUI file where possible.
- Prefer model-specific request builders over adding more nested functions to LambFundamental_GUI.m.
- Consider splitting diagnostics/export/status formatting into helpers after current behavior is stable.
```
