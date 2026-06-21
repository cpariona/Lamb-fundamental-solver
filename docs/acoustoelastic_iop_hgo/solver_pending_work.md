### Acoustoelastic IOP/HGO solver pending work

This document records solver-side work that should not be hidden inside GUI cleanup tasks.

### Current status

The maintained production branch policy remains:

```text
atlasA0 = conservative official output
```

The main GUI now uses a dense requested output grid, and the IOP/HGO wrapper separates:

```text
internal atlas tracking grid
requested output frequency grid
```

The current plotted AE curve is usable for the GUI, but a small residual waviness remains in the phase-velocity curve.

### Pending numerical issue: residual waviness in Cp(f)

Observed symptom:

```text
Cp(f) is mostly smooth and monotonic, but shows small high-frequency waviness after dense output-grid evaluation and local-minimum refinement.
```

Current interpretation:

```text
The issue is likely numerical rather than physical.
```

Likely contributors:

```text
1. Cp is still derived from a finite atlas velocity grid yGrid/cGrid.
2. The current local refinement uses a three-point parabolic fit around a discrete minimum.
3. Neighboring local minima can be close in residual value and may alternate slightly across frequency.
4. Branch linking is based on residual minima and continuity in log(y), not on modal-shape information.
5. The dense GUI output grid makes small tracking/refinement noise visually apparent.
```

### Do not solve this by visual smoothing alone

Avoid using plotting-only smoothing as the production fix:

```text
smooth
movmean
Savitzky-Golay
spline smoothing applied only to the plotted curve
```

Those tools may hide branch-selection or residual-landscape problems. If smoothing is ever used, it should be diagnostic-only and explicitly labeled.

### Recommended future strategy

The preferred solver-side strategy is a two-stage workflow:

```text
1. Use the atlas grid to identify the A0-like modal family.
2. Evaluate Cp on the requested output grid using a continuous local minimizer around a branch-guided predictor.
```

Candidate implementation:

```text
- build atlasA0 on a moderate internal grid;
- construct a smooth predictor Cp_pred(f) from the selected branch, for example with pchip;
- for each requested output frequency, minimize objectiveAcoustoelasticResidual in log(Cp) inside a bounded local window around Cp_pred(f);
- reject the point if the refined minimum leaves the window, introduces a large jump, has poor residual behavior, or violates the branch identity constraints;
- preserve result.validCp and reliability diagnostics as the official quality gate.
```

This should be more efficient than simply increasing `atlasNumYPoints`, because it avoids a very dense global velocity scan at every frequency.

### Diagnostic checks before implementation

Before replacing the current refinement, add or extend diagnostics to inspect:

```text
Cp(f)
diff(Cp)
diff(Cp, 2)
nearestRank(f)
nearestBranchID(f)
objective(f)
selectedBranchPoints.MinRank
selectedBranchPoints.Objective
```

Interpretation guide:

```text
- waviness correlated with nearestRank or BranchID changes suggests modal tracking ambiguity;
- waviness without rank/branch changes suggests local minimization or velocity-grid quantization;
- objective spikes suggest residual conditioning or matrix-scaling issues.
```

### Status

This is a solver-refinement task, not a GUI task. It should be addressed after the current GUI cleanup pass unless the waviness becomes large enough to affect conclusions from parametric studies.
