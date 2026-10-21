# OCE observation preparation

`prepareOceFitObservations(oceResult, selection, metadata)` translates an already
validated OCE result into model-independent fitting observations. Normal Lamb
`startup` exposes this maintained app API without initializing a GUI. OCE is an
optional external producer, not a dependency of Lamb's physics or inverse packages.
OCE's official loader/validator must run at the input boundary. No MAT/BIN decoder,
schema migration, OCE processing or family dispatch is implemented here.

## Contract

`selection.directionIndex` uses acquisition order (`left_1,right_1,...`).
`selection.estimator` is explicitly `"kf_ridge"` or `"phase_gradient"`.
For k-f, `selection.curve` is explicitly `"raw"` or `"smoothed"`:

| Output | Source |
| --- | --- |
| `experimental.frequency_Hz` | Original k-f Hz axis, or phase-gradient physical target Hz |
| `experimental.Cp_mps` | Selected existing raw/smoothed k-f curve, or scalar phase-gradient speed |
| `experimental.validMask` | Explicit logical `selection.validMask`, represented as a column |
| `experimental.conditionId` | Explicit metadata, never derived from filename |
| `experimental.directionId` | Scan-axis index plus literal signed `left`/`right` identity |
| `experimental.integrationMetadata` | Unchanged caller metadata, including loading and repetition |
| `experimental.source` | Estimator/curve, original masks/status, acquisition/direction/angle identity, processing-run reference, target and passband |
| `measuredThickness_m` | Selected current full directional thickness in mm multiplied by `1e-3` |

Metadata requires `conditionId`, positive integer `repetitionId`, nonempty scalar
`loadingCondition` struct, `sourceResultFile` and `metadataReference`. Extra evidence
fields are preserved. Density and mode identification are deliberately not requirements
of observation preparation; they belong to a subsequently selected model/request.
References are retained, not authenticated against external logs by this translator.

For k-f, all three original `ridge` masks are retained, including their original
shape. Original ridge support, interpolation/extrapolation flags and the reviewed
fitting mask are distinct evidence. No source mask or filter passband is promoted
automatically into a fitting mask. The function does not fill gaps; already computed
OCE values are transferred exactly. Review of any filled/smoothed value's suitability
belongs to the explicit observation selection, not to an inferred modal policy.
For phase-gradient, the original status and its `status=="valid"` support flag are
retained. Disabled estimators raise an error; invalid scalar estimates remain NaN
when explicitly excluded. Estimators are never mixed or substituted for one another.

Every source frequency/Cp entry, including excluded values and DC, remains present.
The app rejects selected nonfinite/nonpositive Hz or Cp before canonical fitting
normalization can intersect the mask with finiteness. Preparation itself does not
call that normalizer: it returns the explicit mask and numeric column vectors
without counts or empty uncertainty fields. Nonlinear fitting normalizes its own
request; the direct plate fit needs no such additions. Tests verify exact masks
through downstream normalization and completed fits. No rows are removed, sorted,
collapsed, averaged or reweighted.
The GUI import APIs are intentionally bypassed: `guiPrepareExperimentalFitData`
removes invalid rows, sorts and uses duplicate means by default. Their GUI behavior
is unchanged and does not define this integration boundary.

The acquisition/angular permutation is followed explicitly. Left/right stays signed
relative to the OCE scan axis; Cp remains a positive magnitude. Material/laboratory
axis assignment requires reviewed geometry. Each acquisition, repetition, loading
condition and direction is prepared separately, with no automatic grouping or pooling.
Unknown measured thickness stays NaN, even if velocities are valid.

## Downstream ownership and current limitations

Consumers call the selected canonical `lamb.fitting` family API directly; see the
[demonstration](../../examples/oce_integration/README.md). Model parameters, bounds,
modal choice, physics/support validation, inverse equations, optimizer and diagnostics
remain with their established owners. The app selects none of them. Preserve the
prepared request alongside the native fit result, since some fitting results expose
only a subset of input provenance.

Preparation is model independent; successful preparation does not imply support by
every family. In particular, current nonlinear evaluators can require finite positive
frequencies across the full input axis even for excluded rows. Rayleigh-Lamb rejects
DC/nonfinite full-axis frequencies; mRLFE also validates full-axis frequency support
and requires selected frequencies in ascending order. AE IOP/HGO keeps its atlas
support restrictions. The direct plate fit supports A0 only and requires explicit
current thickness/density and its physical assumptions. Errors/rejections must stay
visible. This change does not trim/regrid arrays or modify inverse algorithms to
make an unsupported request fit. No universal cross-family support is claimed.

For PML01–PML03, preparation still requires validated per-acquisition OCE products,
reviewed estimator/mask selection, condition/repetition matching and signed geometry.
Experimental fitting additionally needs density, calibrated current physical thickness
and explicit model/modal support evidence. Missing Pulse processing belongs to OCE.
QH target pooling needs a separately specified matching/thickness policy; pulse
period or filter center cannot replace the measured dispersion axis.

Authoritative producer contract:
[OCE schema v4](https://github.com/cpariona/OCE_Workflow/blob/5d7f758cc95ff644a5817edbf5bf5daaf01e8d2d/docs/scientific_result_schema.md).
