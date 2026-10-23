# Native inverse-result visualization

This app owner presents already-computed inverse results without GUI initialization,
OCE I/O, fitting calls or scientific eligibility decisions. Plate A0 establishes
the first model-specific renderer. It does not define a common result schema,
dispatcher or acceptance policy for RL, mRLFE or IOP/HGO.

## Plate diagnostics

`plotAePlateFitDiagnostics(result, provenance, ...)` consumes the **unchanged**
native result of `lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion`.
The caller supplies a scalar provenance struct with nonempty `label`, `material`,
`sourceReference` and `modelSupportReference`. It may supply one `repetitionId`
per original row and `sourceMasks` with original logical `valid_mask`,
`interpolated_mask` and `extrapolated_mask` evidence. Each supplied mask must match
the native row count. Unavailable evidence is explicitly labelled unavailable.
The renderer does not import OCE products or infer identity from paths.

The figure contains:

1. Original observed frequency/Cp pairs, in kHz and m/s. Included rows use circles
   coloured by the supplied repetition identity. Excluded-by-mask rows are gray
   dots. Ridge-invalid rows have gray crosses, interpolated rows orange squares,
   extrapolated rows purple triangles, and finite nonpositive Hz/Cp values plus
   markers. Categories can overlap: original ridge support is evidence, not a
   replacement fitting mask. Nonfinite coordinates are counted and retained in
   the figure's data, never assigned fabricated plot coordinates.
2. Native selected `etaSquared` against `rho*Cp^2` in Pa, with the unchanged
   `alpha - gamma*etaSquared` line whenever the native design has rank two.
   Numerically solvable rejected fits keep their unconstrained diagnostic line.
   Excluded positive finite observations are gray and use **display-only**
   eta-squared from the canonical `aePlateA0MasterCurve`, using measured
   `q=pi*f*currentFullThickness/Cp`. Their native eta-squared stays NaN. No
   excluded-row residual is created. Nonfinite transforms are counted.
3. Original selected native residuals in Pa against original row number, a zero
   line, native counts, observation/group ranks, condition numbers, group
   eta-squared span and native RMSE. Rank-deficient unavailable residuals are
   counted. There are no invented confidence intervals or alternative metrics.

The native `diagnostics.physicalCandidate` alone gates forward evaluation.
Supported candidates call `aePlateSolveDispersion` on a 128-point **display**
grid over the selected observed frequency extent. This does not change the
observed axis or scientific sampling. A numerically rejected but physically
supported candidate may have a clearly labelled candidate curve. Unsupported
rejected coefficients never produce a forward curve. Numerical acceptance is
always distinct from experimental A0/model-support validation.

Both the returned evidence and FIG `UserData` retain original rows, frequencies,
speeds, fixed mask, native eta-squared/residuals, optional original ridge flags,
display-only eta-squared, clipping evidence and complete caller provenance.
The result is not modified or refitted.

## Display scales

`resolveInversePhaseSpeedLimits(values, 'Mode', "complete")` chooses a padded
finite-data Cp range. `Mode="robust"` uses the positive population's upper
median/MAD screen (modified Z <= 3.5), solely for axis resolution, with 10 percent
padding. A zero MAD retains the population. Negative finite values remain
inspectable. An empty finite population gets a display fallback [0,1] m/s.
This takes the justified robust-scale principle from OCE presentation without
depending on its private helper, rounding rule or scientific processing.

To compare a reviewed population, resolve the scale **once** from the explicitly
chosen original population and pass `PhaseSpeedLimits=[low high]` to each diagnostic.
The renderer never silently rescales an explicit shared range. Captions and
evidence report observation/prediction counts and maximum values outside it.
All original points remain in the plotted objects and FIG data. Robust scales
are not fitting masks or automatic outlier deletion. Save a separate complete
view when clipping hides observations or prediction. Regression/residual/parameter
panels retain their own physical scales, not the phase-speed limit.

## Parameter trends

`plotAePlateParameterTrends(results, coordinates, 'CoordinateLabel', label)`
takes native result cells and a same-height caller-reviewed table containing
`mechanicalCoordinate`, `axisLabel`, `directionId`, `conditionId`, `material` and
`sourceReference`. An optional `seriesLabel` distinguishes actual populations,
such as pooled QH and one Pulse acquisition, at the same coordinate. One native
result per coordinate, signed axis and series is required. Empty result cells
declare missing cases. Coordinates must be finite and their physical label/unit
explicit. No stretch value, load, coordinate or mechanical state is inferred.

Alpha and gamma are shown in kPa. Accepted signed-axis series use distinct colours
and circle/square markers. Finite rejected coefficients use red crosses; they
remain diagnostic candidates. Accepted lines contain NaNs at rejected/missing
coordinates on the caller-supplied population's coordinate grid, so they do not
bridge those states. Declare unobserved states explicitly when they are otherwise
absent from the supplied population. The third panel shows alpha minus gamma
only for natively accepted, supported fits, through `aePlateInterpretModuli` in
its default principal setting. This does not assert uniaxial kinematics or assign
an absolute stress without justified normal traction. Per-result current full
thickness, density, coordinates, reasons and source references stay in FIG data;
the caption reports their physical ranges and material.

For extreme rejected candidates, `DisplayMode="accepted"` resolves each parameter
panel independently from **all finite natively accepted** values, with padding.
It does not screen accepted results. If none exist, that panel retains its
complete candidate scale. Rejected candidates remain in plotted objects/FIG data;
captions report counts and maximum absolute values outside the range. The default
`DisplayMode="complete"` retains every finite candidate in view. Save a separate
complete trend whenever the accepted-range view clips rejected candidates.

## Manual use and export

```matlab
%% Present the native result already retained by the study
provenance = struct('label', "Reviewed condition / signed direction", ...
    'material', "Researcher-specified material", ...
    'sourceReference', "Reviewed stored request/result", ...
    'modelSupportReference', "A0 working hypothesis; physical review reference");
[fig, evidence] = plotAePlateFitDiagnostics(nativeResult, provenance);

%% Use one shared display scale for a reviewed population
shared = resolveInversePhaseSpeedLimits(reviewedPopulationCp_mps, 'Mode', "robust");
fig = plotAePlateFitDiagnostics(nativeResult, provenance, 'PhaseSpeedLimits', shared);

%% Save to a caller-configured external analysis root
paths = saveInverseFigure(fig, externalOutputRoot, 'plate_condition_axis1_left_raw');

%% Review parameter trends using explicit experimental coordinates
trend = plotAePlateParameterTrends(nativeResults, reviewedCoordinates, ...
    'CoordinateLabel', "Recorded engineering strain [%]");
```

`saveInverseFigure` saves editable `.fig` and 300-dpi `.tif` using the existing
MATLAB savefig/exportgraphics conventions. It requires an explicit output root
and deterministic safe basename, rejects an existing destination of either type,
and never writes a native MAT result. No callbacks or cleanup objects are stored
in figure data. The existing GUI renderer/export and sensitivity FIG/PNG owner
are unchanged; the app does not depend on study functions.

Future renderers should consume their family's native outputs and reuse only
appropriate display-limit/export conventions. They must preserve each family's
residual units, supported branches, physical assumptions and rejection semantics.
