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
QH target grouping follows the explicit policy below. Pulse full-dispersion
selection remains a separate workflow and can reuse `prepareOceFitObservations`;
a Pulse period or filter center cannot replace the measured dispersion axis.

Authoritative producer contract:
[OCE schema v4](https://github.com/cpariona/OCE_Workflow/blob/5d7f758cc95ff644a5817edbf5bf5daaf01e8d2d/docs/scientific_result_schema.md).

## Reviewed QH target assembly and Plate coordination

The optional producer dependency is the official OCE recovery API published in
[PR #144](https://github.com/cpariona/OCE_Workflow/pull/144), merged as
`6ba9abae3e61eff51138ffb7026cf46532466ea2`. Its validated implementation commit is
`315ddacab1cfabf84b19f89fa94e968cfd544666`. Use `oce.results.recoverSummaryObservations`;
Lamb neither vendors that implementation nor decodes its persisted products.
Initialize OCE separately, load an existing summary with MATLAB `load`, then:

```matlab
recovered = oce.results.recoverSummaryObservations(experimentRoot, saved.experiment);
assembly = prepareOceQhFitObservations(recovered, selection);
% Only after physical review; do not run this line for unqualified experiments.
outcome = fitOceQhPrestressedPlate(assembly, physical, review, options);
```

`selection` supplies explicit `experimentId`, `subexperimentId`, `conditionId`, a nonempty `condition` struct
of canonical metadata key/value pairs, `scanAxisIndex`, signed `direction`,
`curve`, `metadataReference`, and an `observations` table. Its columns are:

| Column | Meaning |
| --- | --- |
| `sourceRow` | Local row of the supplied recovered summary, one per reviewed acquisition |
| `binIndex` | Explicitly reviewed existing k-f target bin for that acquisition |
| logical `include` | Fixed fitting selection; excluded target rows stay present |

The initial maintained workflow supports k-f targets only. It does not pool
arbitrary QH FFT bins or mix estimators. The selected raw/smoothed value and
its actual selected-bin Hz are passed unchanged. Physical excitation Hz and
requested target Hz remain separate vectors. Full prepared curves, original
quality masks, current metadata, repetition/run/direction identity and producer
provenance remain in `assembly.lineage`. All reviewed rows must match the
explicit condition and the intended experiment/subexperiment/signed physical axis. The supplied row
order is preserved; no absent repetitions are synthesized. The caller is
responsible for specifying the physical coordinates that define the condition,
including condition keys not present in a subexperiment's frequency-only design.

Metadata and original result identities must agree on experiment, subexperiment
and run. Specimen `sample_id` remains optional under the OCE contract: when
recorded, selected values must agree; when all are absent/blank, the group
reports `identity.sampleIdAvailable=false` without fabricating an identifier.
Mixing recorded and unavailable specimen IDs is ambiguous and rejected.
Optional `selection.sampleId` asserts an intended recorded specimen. Source
metadata are preserved unchanged. Cross-subexperiment equivalence is not
implemented; the current operation stays within one explicit subexperiment.

`sourceRow` is not a global acquisition identifier and must not be renumbered to
merge summaries implicitly. Local-row ambiguity and repeated source result paths
are rejected. Full `lineage.resultFile`, original acquisition identity, repetition
and processing provenance retain source identity even when run IDs repeat.

### Current scientific boundaries

Plate computes independent frequency coverage by exact equality of supplied
Hz. Its frequency-group diagnostic averages eta-squared within those exact
groups; the unweighted observation regression itself retains every repetition.
The app checks whether physical excitation groups and selected-bin Hz groups
define the same partition of the included rows. It uses no rounding tolerance,
changes no Hz and implements no replacement SVD diagnostic. If the partitions
differ, `status="requires_independent_frequency_groups"`, `nativeResult=[]`
and the physical-frequency count describe a blocked request, not a fitted or
accepted model. Even machine-precision bin differences cannot create coverage.
If compatible, native coefficients, masks, rejection reasons and diagnostics
are preserved unchanged, with status `accepted` or `rejected`. One physical
frequency with technical repeats remains insufficient for two coefficients.

The smallest proposed scientific extension is an optional independent-frequency
group identity in Plate, used by its existing coverage diagnostic while keeping
actual observation Hz in the regression. That changes a scientific acceptance
contract and requires separate review; it is not implemented here.

Plate currently accepts one scalar current full thickness. `physical` therefore
contains only `density_kgpm3` and `thickness_m`. The wrapper requires
`review.mode="A0"`, `thicknessPolicy="explicit_constant_current_thickness"`,
and nonempty `thicknessSource`, `thicknessJustification`, `densityReference` and
`modelSupportReference`. `physical.thickness_m` means the supplied scalar current
full physical thickness in SI metres, not half-thickness or nominal thickness.
Its source and justification remain in `outcome.review`, separately from native
fitting diagnostics. An independent current measurement can support this input
even if some or all original OCT thicknesses are unavailable. Every original OCT
value, including NaNs, is retained unchanged in the assembly. Compact selected-row
OCT counts/minimum/maximum/range are exposed in `outcome.thicknessDiagnostics`;
they neither select the supplied scalar nor affect acceptance. No measured thicknesses are combined,
substituted or compared using a new numerical threshold. An externally supplied
constant thickness is a reviewed physical approximation, not evidence that a
variable-thickness plate is supported. Review references are caller attestations;
the app cannot establish their physical validity. An alternative per-observation
thickness formulation would require separate scientific justification.

Following the [scientific independence rule in PR #162](https://github.com/cpariona/Lamb-fundamental-solver/pull/162),
condition labels organize observations; mass, transmitted force and DIC strain
are not fitting inputs, priors, constraints or weights. Constitutive assumptions,
principal propagation, current thickness/density, A0 identification and model
support must be justified before PML inversions. No uncertainty estimates or
external stress/strain comparisons are generated by this workflow.
