# Execution Profile Manual Validation Checklist

This checklist is for human GUI review. It is not marked complete by automated
tests.

Use these setup commands before manual checks:

```matlab
clear functions
rehash toolboxcache
startup
```

For each item, record one of:

```text
Pass
Fail
Not tested
Notes
```

## Main GUI

Launch:

```matlab
LambFundamental_GUI
```

| Check | Expected result | Status | Notes |
| --- | --- | --- | --- |
| Open initial view | Execution Profile selector starts at `Balanced`. | Not tested |  |
| Rayleigh-Lamb, A0, Balanced | Result metadata reports requested/effective `Balanced`; route is `direct`. | Not tested |  |
| Rayleigh-Lamb, Robust | Result metadata reports requested/effective `Robust`. | Not tested |  |
| AE IOP/HGO, Balanced | Result metadata reports requested/effective `Balanced`; atlas preset corresponds to 600/16; route is `atlasA0`. | Not tested |  |
| AE IOP/HGO, Robust | Result metadata reports 900/20 and `atlasA0`. | Not tested |  |
| mRLFE A0Like, `etaS = 0`, Balanced | Requested is `Balanced`, effective is `Fast`, override reason is visible or traceable; route is zero-viscosity adaptive atlas or fallback. | Not tested |  |
| mRLFE A0Like, `etaS > 0`, Balanced | Requested is `Balanced`, effective is `Fast`, internal preset is `fast_viscous`; route is viscous unified atlas. | Not tested |  |
| Model switch RL -> mRLFE -> AE -> RL | Selector remains valid; no internal preset from the previous model appears in the new result metadata. | Not tested |  |

## SweepTool

Launch:

```matlab
SweepTool_GUI
```

| Check | Expected result | Status | Notes |
| --- | --- | --- | --- |
| Open initial view | Execution Profile selector starts at `Fast`. | Not tested |  |
| Rayleigh-Lamb Fast sweep | Output and normalized export report requested/effective `Fast`; route is `direct`. | Not tested |  |
| Rayleigh-Lamb Robust sweep | Output and normalized export report requested/effective `Robust`. | Not tested |  |
| AE IOP/HGO Fast sweep | Output reports 300/12 and route `atlasA0`. | Not tested |  |
| AE IOP/HGO Robust sweep | Robust is available if exposed; output reports 900/20 and route `atlasA0`. | Not tested |  |
| mRLFE `etaS = 0` Fast sweep | Output reports effective `Fast`; internal preset is `fast_zero_viscosity_adaptive`. | Not tested |  |
| mRLFE non-Fast sweep | Output reports requested non-Fast, effective `Fast`, nonempty override reason. | Not tested |  |
| Family switch RL -> AE -> mRLFE -> RL | Default profile returns to `Fast`; profile list and controls are valid for each family. | Not tested |  |
| Export | `SweepToolOutput` and `SweepToolNormalized` preserve requested/effective profile metadata, support mode, internal preset, route policy, and override reason. | Not tested |  |

## FitTool

Launch:

```matlab
FitTool_GUI
```

| Check | Expected result | Status | Notes |
| --- | --- | --- | --- |
| Open initial view | Execution Profile selector starts at `Fast`. | Not tested |  |
| Change model | Switching model resets/keeps the surface default `Fast` without invalid profile state. | Not tested |  |
| Restore model defaults | Execution Profile returns to `Fast`. | Not tested |  |
| RL Fast/Balanced/Robust | Synthetic generation, fitting, normalized output, and fitted curve report requested/effective profile with route `direct`. | Not tested |  |
| AE Fast | Synthetic generation, fitting, and fitted curve use/report 300/12 and `atlasA0`. | Not tested |  |
| AE Balanced | Synthetic generation, fitting, and fitted curve use/report 600/16 and `atlasA0`. | Not tested |  |
| AE Robust | Synthetic generation, fitting, and fitted curve use/report 900/20 and `atlasA0`; no silent 300/12 override appears unless legacy density controls were explicitly set. | Not tested |  |
| mRLFE Fast | Fit output reports effective `Fast` and `fast_fit_atlas`. | Not tested |  |
| mRLFE Balanced/Robust if visible | Requested profile is preserved, effective profile is `Fast`, `fast_fit_atlas` is reported, and override reason is nonempty. | Not tested |  |
| Fitted curve | `FitToolLastOutput.normalized.fullCurve.executionProfile` matches `FitToolLastOutput.executionProfile`. | Not tested |  |

## Compatibility

| Check | Expected result | Status | Notes |
| --- | --- | --- | --- |
| Legacy scripts with `controls.robustness = "Fast"` | Continue to run and canonicalize to `executionProfile = "Fast"`. | Not tested |  |
| New scripts with `controls.executionProfile = "Fast"` | Run without requiring `robustness`. | Not tested |  |
| Case-insensitive inputs | `"fast"` and `"FAST"` canonicalize to `Fast`. | Not tested |  |
| Contradictory aliases | `executionProfile = "Robust"` and `robustness = "Fast"` fail before an expensive solver run. | Not tested |  |

## Second Diagnostics Pass

These checks focus on the harmonized diagnostic text. They do not require a
full physical revalidation.

| Surface | Check | Expected result | Status | Notes |
| --- | --- | --- | --- | --- |
| Main GUI | Rayleigh-Lamb Fast/Balanced/Robust | Diagnostics show control value, requested, effective, route `direct`, elapsed time, valid points, and RL settings such as grid/search fields. | Not tested |  |
| Main GUI | AE Fast/Balanced/Robust | Diagnostics show `ae_atlas_300x12`, `ae_atlas_600x16`, or `ae_atlas_900x20`, plus `atlasNumYPoints`, `atlasTopNMinima`, route `atlasA0`, elapsed time, and valid points. | Not tested |  |
| Main GUI | mRLFE Balanced/Robust | Diagnostics show requested/effective equality, `direct` support, matching public preset, no override, route policy, `etaS`, fallback, elapsed time, and valid points. | Not tested |  |
| SweepTool | Any completed sweep | Status area shows elapsed time, sweep cases, valid cases, requested/effective profile, internal preset, and route policy. | Not tested |  |
| SweepTool | AE Robust | Status shows `ae_atlas_900x20`, `atlasNumYPoints = 900`, `atlasTopNMinima = 20`, route `atlasA0`. | Not tested |  |
| SweepTool | mRLFE Balanced/Robust | Status shows requested/effective equality, direct support, matching preset, no override, and the actual route where available. | Not tested |  |
| FitTool | Synthetic generation | Status distinguishes synthetic diagnostics and shows requested/effective profile plus elapsed time. | Not tested |  |
| FitTool | AE fit | Fit status shows effective atlas preset and 300/12, 600/16, or 900/20 according to profile. | Not tested |  |
| FitTool | mRLFE fit | Fit status shows `fast_fit_atlas`, requested/effective mapping, override reason, actual route, fit elapsed, and fitted-curve elapsed. | Not tested |  |
