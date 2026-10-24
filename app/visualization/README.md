# Native inverse-result visualization

This app owner presents already-computed inverse results without GUI initialization,
OCE I/O, fitting calls or scientific eligibility decisions. Plate A0 establishes
the first model-specific renderer. It does not define a common result schema,
dispatcher or acceptance policy for RL, mRLFE or IOP/HGO.

## Plate diagnostics and observation selection

`plotAePlateFitDiagnostics(result, provenance, ...)` presents the unchanged
`aePlateFitDispersion` result. It never fits, repairs a mask, screens fitting
outliers or interprets experimental validity. The four existing visualization
APIs remain the owners; no solver dispatcher or model-neutral plotting framework
is introduced. Other fitting families retain their own scientific contracts.

The study supplies an explicit fixed `validMask` from original OCE evidence:

```text
ridge.valid_mask & ~ridge.interpolated_mask & ~ridge.extrapolated_mask &
isfinite(frequency_Hz) & frequency_Hz > 0 & isfinite(Cp_mps) & Cp_mps > 0
```

All input rows, source masks, observed Hz, acquisition identities and signed
directions remain intact. Flag causes can overlap and must not be summed as
independent exclusions. This is a study selection policy, not an implicit policy
inside the model-neutral `prepareOceFitObservations` API.

QH retains one original selected k-f target bin per selected acquisition through
`prepareOceQhFitObservations`; this differs from pooling an entire QH FFT curve.
Pulse retains the original full frequency axis for each selected acquisition.
Selected repetitions form one fixed request without averaging phase speeds.
The base quality mask can be combined with an observed-Hz interval or nominal
frequency requests mapped to original bins by the study. Source passbands and ridge processing remain OCE
evidence; there is no hidden outlier screen or automatic optimal-band selection.

### Existing curve choice

The maintained study defaults to original OCE phase-speed estimates. Choosing
an already persisted smoothed curve is an explicit study decision. No smoothing
is performed here. Smoothing changes both regression coordinates; lower residuals
on a different response do not establish more accurate parameters or model validity.

### Presentation and mathematical interpretation

Supply nonempty `label`, `material`, `sourceReference` and
`modelSupportReference` in provenance. Optional `displayLabel` supplies the
human title (sample, state, signed direction and analysis); `displaySubtitle`
identifies the acquisition/modality/period. Both are presentation labels,
never identity matching keys. Preserve exact original metadata in provenance.
Optional per-row `repetitionId` and original `sourceMasks` retain their meanings.

The three panels show:

1. Observed phase speed [m/s] against actual observed frequency [kHz], separated
   by repetition/acquisition. A physically supported coefficient candidate alone
   enables the existing canonical `aePlateSolveDispersion` prediction on its
   128-point display grid. This grid never replaces observations.
2. `rho Cp^2` [Pa] against `eta^2`, with alpha/gamma in readable Pa-based units.
   A rank-two regression retains its calculated line even when inadmissible.
   Prediction and regression lines are black dashed. Physical support is stated separately as
   `alpha >= gamma > 0`, with the failed inequality shown when applicable.
3. Original fitted-minus-observed regression residuals [Pa] against the aligned
   original observed frequencies, and the native RMSE [Pa]. Repeated frequencies
   remain separate observations; no averaging, sorting or residual recomputation
   changes the fitting data.

The panels retain native coefficients and RMSE; the brief footer reports physical
support, density and scalar thickness. Rank, conditioning, group diagnostics,
native acceptance and full reasons remain in results/FIG data rather than the
footer. A0 and the remaining Plate assumptions are not experimentally confirmed.

Sparse repetitions use blue/orange/purple symbols. Without explicit graphic
sampling, dense series use fine dots at every original coordinate. Interpolated/extrapolated extensions are excluded
from the robust main view; their full arrays, flags and counts remain in FIG
data. The complete view uses sparse, unconnected extension glyphs, never a
continuous experimental extension. One shared legend avoids repeated decoding.

## Automatic panel scales and complete inspection

The existing `resolveInversePhaseSpeedLimits` remains the sole display-limit
owner. `Quantity="phase_speed"` (default) uses m/s; `Quantity="regression"` and
`Quantity="residual"` use Pa. Evidence provides `limits`, `quantity`, `unit` and
clipping counts/extremes; legacy m/s fields remain only for phase-speed results.

`Mode="robust"` uses the existing median/MAD display screen (modified Z <= 3.5),
upper-sided for phase speed/regression and two-sided for residuals. A zero MAD
retains the finite population. Ranges include the appropriate zero reference,
add 10 percent padding and round outward to readable bounds. An empty panel
uses a documented [0,1] display fallback in its own units.

For comparable cases, supply one vector per case in a cell vector. The resolver
takes the envelope of case-wise ranges, so denser acquisitions cannot dominate
the display merely by supplying more bins. Resolve one range **per panel** from
an explicitly declared comparable population and reuse those ranges through
`PhaseSpeedLimits`, `RegressionLimits` and `ResidualLimits`. No manual numeric
limits are required. Do not mix differing study populations silently.

Out-of-scale selected observations retain their full original coordinates and
receive sparse filled boundary triangles. Exclusions use open triangles; line/model
clipping uses compact summaries. Actual extrema appear above the panel.
Line/model clipping is summarized by count and extrema; all their
original coordinates remain available. None of these glyphs changes fitting
rows, residuals, coefficients or acceptance.

`DisplayMode="complete"` without shared limits restores all finite coordinates
and model/line values, including sparse excluded-extension glyphs. Editable FIG
data also retain `completePanelLimits`, exact observation rows, native parameters,
full diagnostics and provenance. No automatic duplicate full-range export or
serialized callback is needed; rerender complete inspection manually from the
same retained result.

## Manual study and Pulse graphic sampling

Use the single [Plate study](../../studies/aePlateOceStudy.m) and its
[configuration contract](../../docs/oce_study_contract.md#maintained-manual-plate-study)
for QH and Pulse. Scientific input is recovered individual OCE products, never FIG
contents, summary means or comparison statistics.

Select one condition, literal Pulse period and signed direction. Pool selected
repetitions into one native request without averaging velocities. Coefficients,
the single regression, residuals and RMSE use the complete fixed fitting mask.
Acquisition, repetition and source-bin identity remain available in the assembly.

`DisplayFrequency_Hz` optionally selects exact stored frequencies for glyphs in
all three panels; it never changes fitting masks or native diagnostics. The study
uses compatible OCE sampling indices, or original bins selected from explicit
graphic targets before checking validity. Missing/excluded bins remain absent.
No nearest-valid repair, interpolation or experimental extension is performed.

The approved diagnostic uses blue/orange/purple repetition symbols, simple
`Rep. 1`/`Rep. 2`/`Rep. 3`/`Model` labels and black dashed model/regression lines.
The brief footer states mathematical support, supplied density and scalar current
thickness (mm, three display decimals). Full diagnostics and unrounded inputs remain
in native results and figure data.

## Independent-fit compatibility view

The cell-input form of `plotAePlateFitDiagnostics` retains separate native fits;
it is not a pooled inversion. No maintained study currently requires this form,
but it remains available for compatibility with earlier independent-repetition
reviews. Removal requires a separate API decision. Automatic limits use the
existing case-envelope resolver for all three panels before rendering any case;
explicit shared limits remain supported. Each repetition's clipping summaries
and edge glyphs refer to those same limits, with full native evidence retained.
The scalar joint-fit path used by the maintained study is unchanged.

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
population = cellfun(@(r) r.experimental.Cp_mps(r.validMask), ...
    reviewedNativeResults, 'UniformOutput', false);
shared = resolveInversePhaseSpeedLimits(population, 'Mode', "robust");
fig = plotAePlateFitDiagnostics(nativeResult, provenance, 'PhaseSpeedLimits', shared);

%% Save to a caller-configured external analysis root
paths = saveInverseFigure(fig, externalOutputRoot, 'plate_condition_axis1_left');

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
