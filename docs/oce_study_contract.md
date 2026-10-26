# Reproducible OCE studies with native Lamb fitting families

OCE owns acquisition processing, persisted scientific products, summary identity,
source recovery and descriptive comparison. Lamb owns model physics, inverse
algorithms, model-specific validation and native results. A study coordinates
their maintained APIs; it does not decode OCE files, repair scientific observations,
select alternate branches, duplicate fitting or implement another dispatcher.

Summaries and comparison products identify and describe recorded conditions.
Inversion consumes recovered individual observations, never averaged comparison
values or paired scan-axis statistics. QH and Pulse are acquisition modes, not
inversion models. Their eligibility depends on the explicitly selected native
model, physical inputs and observation review.

## Shared preparation, explicit model choice

`prepareOceFitObservations` translates one already validated OCE acquisition and
one signed direction. The caller selects the estimator, existing raw/smoothed
curve and fixed fitting mask explicitly. Original Hz, speeds, row order,
exclusions, source quality masks, directional geometry, processing references and
metadata references remain visible. Unknown thickness stays unknown. Opposite
directions and different conditions are separate cases, not automatically averaged.

`prepareOceQhFitObservations` assembles reviewed k-f target rows within its stated
experiment/subexperiment/condition and signed direction. It preserves the actual
selected-bin Hz and separately records physical excitation and requested target
Hz. Its `assembly.experimental` is not intrinsically a Plate request. Every
consumer must still satisfy its native family's requirements.

Successful preparation proves neither a valid request for every model nor an
identifiable inverse problem. Full-axis restrictions can reject a request even
when its selected observations are valid. Do not trim excluded DC/NaN rows,
sort, collapse repeated frequencies, average speeds, modify the mask or substitute
diagnostic branches to bypass native rejection. Record the rejection. In particular,
pooled QH repetitions with duplicate observed Hz are not a valid native mRLFE
axis. Automatic repeated-frequency projection is not supplied by this integration;
changing that native fitting contract requires its own review. A per-acquisition
broadband curve can already satisfy the maintained mRLFE axis contract.

## Model-specific contracts

| Family and maintained fitting API | Explicit physical/model inputs and numerical boundaries | Native evidence |
| --- | --- | --- |
| Rayleigh-Lamb: `lamb.fitting.rayleigh_lamb.rlFitDispersionData` | Elastic parameters, current thickness, density, supported near-incompressible Poisson ratio; explicit A0/S0 choice, fixed/free parameters, bounds and execution options. Selected observations require positive finite Hz/Cp. Excluded nonpositive/nonfinite frequencies remain in place with unavailable predictions; positive finite frequencies use the canonical RL solver. Direct model evaluation still requires a positive finite full axis. | Fixed-mask model coverage, optimizer result, residuals/metrics, sensitivity and local identifiability; selected A0/S0 output and unchanged official solver diagnostics. |
| mRLFE: `lamb.fitting.mrlfe.mrlfeFitDispersionData` | Material modulus/viscosity, density, current thickness, supported Poisson ratio and fluid density/sound speed. Explicit A0Like/S0Like, numerical preset and fit-grid policy. The full requested frequency axis must be positive, finite and strictly ascending. Physical-tail/none termination and no fallback retain their native meaning. | Native public-solver route, requested/effective configuration, branch/termination and coverage evidence, optimizer result, sensitivity and identifiability. |
| Prestressed Plate: `lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion` | Reviewed A0 support, one condition and signed principal direction, density and current full thickness per original observation (optional `experimental.observationThickness_m`; scalar legacy `physical.thickness_m` retained). Original unweighted Li regression with one shared `alpha,gamma` across observations. At least **two** independent frequency groups plus its existing observation/group rank, conditioning, eta-squared span and tensile-support screens. Optional `independentFrequencyGroupId` belongs to this family only. | `accepted`, `reasons`, unconstrained candidate moduli/residuals and explicit observation/group diagnostics. A returned candidate is not necessarily accepted. |
| AE IOP/HGO: `lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData` | Geometry/radius, current thickness, IOP, matrix/fibre material parameters, tissue/fluid densities and fluid bulk modulus, with explicit fixed/free parameters and bounds. Only official `atlasA0`. Positive finite full frequency axis and the selected-frequency initialization-anchor requirement remain enforced. Plate assumptions and grouping fields do not replace this model's contracts. | Official atlas output and validity policy, fixed-mask coverage, optimizer result, sensitivity/identifiability and native model diagnostics. Diagnostic/fallback curves are not substitute observations or official predictions. |

The native builders for RL, mRLFE and AE IOP/HGO currently accept requests with
one selected observation; that does not establish parameter identifiability or
model support. This study contract adds no universal frequency-count requirement
and no three-frequency threshold. Plate's two-group minimum remains specific to
Plate. Each free-parameter set must be reviewed using its native diagnostics.

The nonlinear APIs do not expose Plate's `accepted`/`reasons` schema. Preserve
`optimizer`, `residualInfo.coverageAccepted`, `sensitivity`, `identifiability` and
native model evidence separately. Optimizer termination, finite predictions,
adequate sensitivity and experimental support are distinct findings. Do not
manufacture a shared scientific acceptance boolean or rank test in the study.

Native RL fitting requires explicit `validMask=false` for nonpositive/nonfinite
frequencies; an absent/empty mask does not infer their exclusion.
Observation-aligned prediction arrays retain the input
length/order. When excluded frequencies cannot be evaluated,
`modelEvaluation.evaluatedObservationMask` identifies the positive finite rows;
unevaluated predictions/residuals/wavenumbers are NaN and model validity is false.
Positive finite excluded rows may still have predictions. The official
`modelResult` and `diagnostics` retain the canonical solver's unique positive
grid, including its singleton auxiliary request when needed. Full-axis
`reliability` counts describe prediction availability, including unevaluated
exclusions; `residualInfo` separately reports complete coverage of the fixed
objective mask. An excluded DC row is neither a missing selected prediction
nor evidence of a failed root.

Select models from reviewed physical assumptions before interpreting fitted
parameters. Native residual definitions, units and weighting can differ: Plate's
regression residuals in Pa are not directly comparable to speed or normalized
residuals from another family. This integration supplies no cross-model score or
automatic model-selection rule.

## Maintained human Plate inversion workflow

The maintained Plate human workflow is [run_ae_plate_oce_inversion.m](../workflows/inversion/run_ae_plate_oce_inversion.m).
It replaces the pilot preview/export coordinator. It contains no specimen names,
absolute study paths, FIG input dependency, frequency optimizer or model dispatcher.
Open the actual driver in MATLAB Editor. In section 1, edit `oce_repository_root`
and the explicit `study` fields. Run section 2 to initialize both repositories;
it resolves the active Editor file to avoid MATLAB's temporary Run Section file.
Run section 3 to recover observations and inspect `sourceMetadata` and
`observationReview` before fitting. These retain source rows/bins, repetitions,
actual Hz, original flags and the fixed fitting mask. See the
[human workflow guide](../workflows/README.md) for the sequence and opt-in gates.
The ordinary Lamb `startup` intentionally excludes `workflows/`.

| Configuration | Meaning |
| --- | --- |
| `experimentRoot`, `summaryFile` | OCE root and persisted MAT containing `experiment`; OCE owns recovery. |
| `experimentId`, `subexperimentId`, `sampleId`, `conditionId`, `condition` | Explicit identities and scalar mechanical condition entries: literal text for stored text, exact doubles for stored doubles. No folder-name inference or cross-type coercion. |
| `mode`, `period_us`, `repetitions`, `scanAxisIndex`, `direction`, `curve` | QH/Pulse, literal Pulse period, repetition labels, signed direction and an existing raw/smoothed curve. |
| `frequencySelection`, `frequency_Hz` | `all`, inclusive observed-Hz `interval=[low high]`, or `explicit` nominal requests mapped to original observations. No nearest-valid repair or interpolation. |
| `physical`, `review` | Native Plate density and explicit A0/thickness/density/support review; default direction-matched OCE current full thickness per original row, optional reviewed scalar alternative. |
| `fitOptions` | Native options, forwarded unchanged. Empty options reuse a supplied result's effective settings; a new request otherwise uses native defaults. |
| `existingNativeResult`, `existingAssembly`, `resultFile`, `reuseOnly` | Approved native objects or a MAT with `nativeResult` and `assembly`. Default `reuseOnly=true` rejects changed requests before fitting. |
| `graphicRequestedFrequency_Hz` | Pulse graphic targets, independent of fitting selection; compatible OCE sampling is preferred. |
| `showFigure`, `displayLabel`, `displaySubtitle` | One diagnostic with the approved fixed typography and renderer. |
| `saveResult`, `exportFigure`, `figureFolder`, `figureName` | Opt-in persistence; defaults create no files. Existing destinations are never overwritten. |

For `explicit`, `frequency_Hz` contains researcher-requested nominal frequencies.
QH matches the registered physical excitation values and retains the existing
selected FFT bins. Pulse reuses compatible OCE requested/selected-frequency
correspondences; otherwise it selects the nearest bin on each complete original
axis before applying quality. Excluded bins are never replaced by nearby valid
ones. Requests outside an original Pulse axis are unmapped, not clamped to an end;
unrecorded QH physical frequencies likewise select nothing.
`frequencySelectionMapping` retains source/repetition, requested Hz, observed Hz,
original source-bin index, quality and mapping origin, including unmapped requests.
It is retained in the workspace and with newly saved study results. Multiple
requests selecting one bin never duplicate that fitting row.

Pulse fitting and graphic requests use one mapping pass on each original source
axis. OCE's saved selected Hz are resolved to that axis; its aligned-summary bin
indices are never used as original indices. `graphicSamplingMapping` records the
same correspondence fields for display requests. The two masks remain independent:
changing graphic targets cannot add or remove fitting observations. Both mapping
tables are retained with newly saved study results.

The default thickness policy is `oce_directional_per_acquisition` for both
QH and Pulse. The native Plate SVD takes `experimental.observationThickness_m`
with one source-recorded **current full** directional thickness per original
observation. QH keeps the measured value for each acquisition/frequency;
Pulse shares an acquisition/direction thickness only between that acquisition's
own FFT bins. Each selected row uses
`q_i=pi*f_i*observationThickness_m(i)/Cp_i`; the regression retains one
`alpha,gamma` per reviewed condition and signed propagation direction.
`physical.thickness_m` remains a non-operative, source-derived scalar reference
when the per-observation field exists. It does not pool, select, round, interpolate,
or substitute measured thickness. Missing selected thickness is an error.
A reviewer can instead explicitly choose `explicit_constant_current_thickness`
with an independently justified scalar, or `oce_reference_acquisition` with
one indexed original acquisition as a scalar-geometry approximation. Only these
scalar policies use `physical.thickness_m` across all rows. Original SVD,
validity mask, physical-frequency grouping and coverage/acceptance screens stay
unchanged. Per-observation geometry assumes the local uniform-plate A0 relation
is meaningful and shared acoustoelastic coefficients describe the fitted state;
it does **not** model spatial-gradient scattering or prove homogeneity.

QH uses `prepareOceQhFitObservations`; its existing Plate coordinator retains
physical-frequency coverage preparation. Pulse calls `prepareOceFitObservations`
per acquisition and concatenates every original row, including exclusions.
Both reach the same unweighted `aePlateFitDispersion`, one request per condition
and signed direction. Pulse periods/repetitions are never spectral group IDs.

Reuse requires identical observations/mask/IDs, physical inputs, effective options
and source-result references. QH additionally compares the saved physical and
requested-frequency assembly, without duplicating grouping logic. Legacy outcome
containers can be opened manually and their canonical `nativeResult`/`assembly`
supplied explicitly. No generic legacy MAT decoder is added.

That reuse check establishes numerical request compatibility, not historical
provenance equality. A compatible archived native result remains reusable even
when it lacks input hashes. Matching `processing_run_id` alone never authenticates
the bytes used during its historical OCE processing.

When `saveResult=true`, the existing result MAT additionally contains
`studyRecord`, with no duplicate observation arrays:

- `selection`: experiment/subexperiment identities, root-relative summary and
  output destinations, condition with original value types, modality/period,
  repetitions, direction, curve, frequency and graphic selection.
- `code.Lamb` and `code.OCE`: Git commits, relative porcelain
  modification/untracked status and availability **without local checkout roots**.
  Missing Git evidence is explicit; dirty code requires preserving patches.
- `matlabVersion`, `matlabRelease`, and `inputFiles` (experiment-root-relative
  `path`, bytes, SHA-256). Hashes are checked against unchanged absolute
  input locations **before** references are converted for persistence.
  Input hashes cover the loaded summary, indexed PhaseSpeed files and canonical
  AcquisitionParams tables used for recovery, including indexed sources outside
  the final fitting selection. Files are fingerprinted before recovery and checked
  again before persistence; changed inputs block saving.
- Pending efficiency review: hashing follows the complete summary recovery index,
  not only the selected condition. A future reduction must preserve recovery and
  provenance guarantees; it is not part of the current implementation.
- `numericallyReused`, `provenanceScope` and
  `historicalProcessingContentVerified=false`: the hash evidence applies to the
  current study inputs, never retroactively to historical processing.

The existing `nativeResult.experimental`, `nativeResult.options`, `physical`,
`review`, `assembly`, `observationReview` and frequency-mapping tables retain the
effective native request, fixed mask, physical justification, acquisition lineage,
original bins and quality flags. Together with `studyRecord.selection` they permit
scientific configuration reconstruction; numeric replay can call Plate directly
from the native result without reopening OCE files. The portable
`studyRecord` references are relative to `experimentRoot`; the original
native/OCE lineage is retained **unchanged**, including any absolute path
strings supplied by its producer. Those historical reference strings are
not required to reconstruct the native numerical result, but replay on a
different workstation must rebind the OCE checkout and source experiment root.
No raw BIN, ProcessingConfig or
ProcessingRun manifest is read or hashed by this study; their references are
producer provenance, not verified historical inputs. Physical review references
are caller attestations, not additional files implicitly read by the study.

Use OCE PR #146's exact-identity producer/recovery contract; the integration README
pins its revision and legacy ambiguity boundary. No local label normalizer or
summary migration belongs to Lamb.

Historical constant-thickness inversions retain their original
`explicit_constant_current_thickness` policy and physical reference.
New OCE inversions default to recorded `oce_directional_per_acquisition`;
do not rewrite archived reviews, physical inputs or native results.

Pulse uses compatible OCE selected Hz or original bins nearest explicit graphic
targets before applying validity. Missing/excluded bins stay absent. Per-source
graphic masks are checked against the renderer's exact-Hz selection; incompatible
grids require review instead of silently selecting additional rows. All numerical
diagnostics and acceptance still describe the complete fixed fitting request.

Workspace outputs include `frequencySelectionMapping`, `assembly`, `observationReview`, `nativeResult`, `reusedResult`
and, when requested, `fig`/`figureEvidence`. This study is Plate only. RL, mRLFE and
IOP/HGO retain their model-specific direct APIs and scientific requirements.

## Maintained human Rayleigh-Lamb inversion workflow

[run_rl_oce_inversion.m](../workflows/inversion/run_rl_oce_inversion.m) exposes
editable MATLAB Editor sections for native Rayleigh-Lamb A0/S0 fitting. Its
configuration section constructs `study`, and its Editor-safe initialization
section adds the opt-in workflow and the explicitly configured OCE `src` path.
Defaults request reuse only and write no files.

Both human drivers consume [prepareOceInversionObservations](../workflows/inversion/prepareOceInversionObservations.m)
for the same exact condition/repetition/signed-direction selection and nominal-to-
original-bin mapping. It calls canonical OCE recovery and the existing preparation
owners; it is not another loader, translator or experimental schema. The fixed
mask and complete observation order remain inspectable before fitting. QH k-f
requests use the recorded selected target bin, retaining full source preparations
in the assembly; Pulse retains every original bin, including excluded DC rows.
The RL study also accepts the already recorded QH `phase_gradient` estimator;
it does not compute one or substitute it for missing k-f results. Pulse requires
`kf_ridge`. Plate keeps its existing k-f contract.

RL uses the common selection fields above plus:

| Configuration | Native RL meaning |
| --- | --- |
| `estimator`, `curve` | Explicit `kf_ridge` raw/smoothed, or recorded QH `phase_gradient` (curve unused). |
| `observationMask` | Empty uses the existing source-quality/frequency policy. A supplied logical vector is the exact original-row mask and must respect frequency selection. Invalid selected values are rejected, never repaired; original ridge flags remain separate evidence. |
| `fitConfig` | Native branch, fixed/free parameters, initial guesses, bounds, solver options and fitting options; no Plate group policy or SVD fields. Units are native SI. A scalar `fixedParams.thickness` is used only under `explicit_constant`; under the OCE policy the native problem uses `experimental.observationThickness_m`. |
| `thicknessPolicy` | Default `oce_directional_per_acquisition`: one source-recorded current full directional thickness per observation (QH acquisition/nominal frequency; Pulse acquisition/repetition repeated over its original bins). `explicit_constant` retains reviewed scalar thickness. Missing nonpositive-frequency measurements are tolerated; missing thickness at any positive-frequency observation blocks the request. |
| `review` | Explicit `mode`, `thicknessSource`, `thicknessJustification`, `densityReference`, `parameterJustification` and `modelSupportReference`. Explain measured fixed inputs and any fitted-parameter bounds/initial values, without inventing experimental validity. In the OCE thickness policy, source/justification are set to the actual recorded measurement policy. |

The current full thickness comes from the already selected OCE signed direction
(`borders.directional_mean_thickness_mm`, converted to meters). QH retains a
separate thickness for each selected acquisition/frequency; Pulse repeats each
acquisition's thickness only across that acquisition's original FFT bins. No
sample median, pooled average, thickness interpolation, frequency matching or
rounding is applied. The native Rayleigh-Lamb evaluator solves separately on
each set of **exactly equal** thickness values, while retaining original
observation positions and one shared fitted modulus. It does not create a
single fictitious canonical model result for multiple geometries: native
model products and diagnostics are retained by thickness group. The scalar
`allParams.thickness` is a non-operative reference in this mode, never the
height used to evaluate all observations. Fitting a scalar thickness is
incompatible with this option. The RL figure presents the selected directional
thickness range and does not connect model curves for differing thicknesses.
`explicit_constant` preserves legacy single-height behavior when an
independently reviewed constant is needed. Prestressed Plate now supports
its own native per-observation geometry through `experimental.observationThickness_m`.
Unlike RL, it applies each h_i directly in the dimensionless A0 master curve
before one unweighted SVD of shared `alpha,gamma`; it does not independently
solve a new regression for each thickness group.

The native `rlBuildFitProblem` validates and resolves defaults without evaluating
the forward model. Reuse compares its effective value fields with the saved native
problem, including all observations, fixed mask, branch, parameters, bounds,
numerical/optimizer options and source-result order. QH additionally verifies
physical/requested target frequencies and original selected bins. If anything
differs, `reuseOnly=true` rejects before optimization. Native configuration or
source changes never silently trigger a fit. Setting `reuseOnly=false` explicitly
permits one call to `rlFitDispersionData`; repetitions are not averaged.

`resultFile` can recover a saved `nativeResult` and `assembly` when saving is off.
Alternatively supply `existingNativeResult` and `existingAssembly` explicitly.
Historical containers remain manually opened rather than decoded through a
generic legacy loader. A new save requires a different, absent destination.
The MAT retains `nativeResult`, `assembly`, `fitConfig`, `review`, the two mapping
tables, `observationReview` and `studyRecord`. The native `problem` owns resolved
options/parameters; selection records do not duplicate the observation arrays.
An explicit mask is reconstructible from `observationReview.validMask`, with its
policy recorded separately. The common [oceInversionProvenance](../workflows/inversion/oceInversionProvenance.m)
records the same current input hashes, code state and provenance limits as Plate.
The full-summary hashing scope is intentionally unchanged.

Numerical reuse does not authenticate historical processing bytes. A corrected
metadata source must remain linked to its correction record; retain superseded
requests/caches as historical evidence instead of relabelling them in place.
Check active metadata before applying any old correction package.

Both studies render the retained native result and export only through
`saveInverseFigure`: editable FIG plus full-canvas 300-dpi TIF, with no overwrite.
They introduce no PNG export path. `openfig(...,'new','visible'); drawnow` reopens
the editable product; scientific replay consumes the saved native request/config,
not FIG or raster data. Pulse graphic bins remain independent of the fitting mask.
The Plate/RL renderers retain their native diagnostic panels: B is Plate's
Pa regression or RL's native parameter summary, and C uses each model's own
residual definition/units. RL's observation-thickness option displays its
measured thickness range and keeps predictions for different exact thickness
groups on separate model lines.
RL convergence/identifiability and Plate native acceptance are not interchangeable
and establish neither experimental A0 purity nor physical model validation.

## Programmable one-case and batch execution (reviewed inputs only)

The source-of-truth for human and batch coordination is
`workflows/inversion/executeOceInversionStudy.m`, with shared physical review
(`reviewOceInversionPhysics`), exact-source native fitting and reuse
(`fitOceInversionNative`), provenance persistence and pure result rendering.
The manual Editor drivers retain their section boundaries, delegating to the
same owners. The maintained programmable entry point is
`runOceInversionBatch(plan,family)`, with `family="RayleighLamb"` or
`family="Plate"`, avoiding redundant forwarding wrappers.

Each independently reviewed case keeps the same recorded condition, signed
direction and frequency selection it would have in a human Run Section.
No automatic bandwidth optimization, robust outlier rejection, parameter
retuning, source-quality repair, modal identification or QH+Pulse pooling is
implemented. The batch refuses an unreviewed frequency-selection field and
requires a specific `approvedAllFrequencies=true` acknowledgement for `all`.
A read-only batch plan is the default; enabling `plan.execute=true` authorizes
native fitting. Output MAT, FIG and TIF are independently controlled.

The default storage layout, relative to the supplied machine-local experiment
root, is
`Results/<subexperiment>/Inversions/<RayleighLamb|Plate>/<case>/inversion.{mat,fig,tif}`.
Only the experiment and OCE source repository roots are machine-local inputs.
`outputRelativeFolder`, `outputTag` and `summaryRelativeFile` are optional
programmable overrides. No absolute output override or parent traversal is
supported, and existing outputs are never replaced. `outputTag` is required
to distinguish independent fit reviews with the same physical case identity.
The resulting saved `studyRecord` retains effective relative paths, fixed
observation mask, original row mappings and root-relative source hashes;
the original native OCE payload and mechanical review remain alongside it.
Batch failures with `saveResult=true` create a separate
`inversion_failure.mat`, retaining the reviewed request, error identifier,
portable stack-location names and UTC time; an earlier failure file is never
replaced. `saveResult=false` leaves the failure in the returned batch report
only. A failed attempt is **not** a fitted result or physical finding.

**Thickness policies are reviewed per model:** RL uses one recorded
directional current full thickness for each original observation and dispatches
exact-thickness forward groups. Plate uses the same OCE geometry evidence but
fits a **single** common `alpha,gamma` by substituting h_i into each row's
`q_i` before the unweighted master-curve SVD. Optional scalar Plate policies
(`explicit_constant_current_thickness` and `oce_reference_acquisition`)
retain the historical single-height fit. Plate figures use separate native
forward predictions for exactly equal thicknesses, avoiding false single-height
dispersion curves. QH physical-frequency coverage remains exclusively owned by
`fitOceQhPrestressedPlate`. Distinct h_i do not create statistically independent
frequency groups or independent material states.

## Manual MATLAB sections

Keep preparation, physical review, model choice and fitting separately executable.
The following are coordination examples; the caller supplies all reviewed
selections and configurations before running a fitting section.

```matlab
%% 1. Initialize the reviewed OCE and Lamb revisions
% Run each repository's documented startup/path setup explicitly.
% Record commits and the hash of any uncommitted validated patch.

%% 2. Recover and select original observations
saved = load(summaryPath, 'experiment');
sources = oce.results.recoverSummaryObservations(experimentRoot, saved.experiment);
% sourceRow identifies one reviewed record in this recovered summary.
prepared = prepareOceFitObservations( ...
    sources(sourceRow).scientific_result, selection, observationMetadata);
experimental = prepared.experimental;
% Alternatively use prepareOceQhFitObservations(sources, qhSelection), then
% experimental = assembly.experimental; retain the complete assembly lineage.

%% 3. Review physical support and construct the native configuration
% Supply current physical measurements, model/modal support evidence,
% fixed/free parameters, bounds, weighting and numerical options explicitly.
% Execute only the fitting section for the selected, reviewed family.

%% 4a. Rayleigh-Lamb
nativeResult = lamb.fitting.rayleigh_lamb.rlFitDispersionData(experimental, rlConfig);

%% 4b. Modified Rayleigh-Lamb
nativeResult = lamb.fitting.mrlfe.mrlfeFitDispersionData(experimental, mrlfeConfig);

%% 4c. Prestressed Plate
nativeResult = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion( ...
    experimental, platePhysical, plateOptions);
% For the reviewed QH constant-current-thickness workflow, use the existing
% fitOceQhPrestressedPlate(assembly, platePhysical, physicalReview, plateOptions).
% That coordinator alone derives physical QH codes for the Plate extension.

%% 4d. Acoustoelastic IOP/HGO
nativeResult = lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData(experimental, aeConfig);

%% 5. Inspect and retain the unchanged native result
% Save nativeResult together with its exact request and source/review references.
% Evaluate external scientific validation separately; do not refit to load/DIC.
```

No family API is automatically invoked by preparation. Measured directional OCT
thickness is an observation, not a universal assignment to every family's physical
configuration. A separately justified current thickness is permitted where the
native contract supports it. Load, applied mass and independent DIC strain are
not implicit priors, fitting constraints, weights or model-selection evidence.

## Minimum reproducible study record

For each separately reviewed condition, signed direction and model choice, keep:

1. `study.m`: manually executable sections identifying the selected family and
   canonical API, estimator/modal assumptions and the order of reviewed operations.
2. `request.mat`: the exact prepared request or QH assembly, unchanged mask and
   row mapping, native physical/configuration structs, units and fixed/free
   parameter decisions. Include repository commits and validated patch hashes;
   reference the OCE summary/source products and their available content digests.
   Retain original run/processing references and recovery provenance, including
   unavailable or historical evidence. Do not create a second canonical metadata table.
3. `native_result.mat`: the complete returned native fitting result, including
   rejected candidates and diagnostics, or the native exception if request
   validation fails. Retain the original request when no fit can run.
4. **review.md**: reasons for observation eligibility, physical/model support,
   numerical and identifiability assessment, uncertainties/limitations and any
   independent experimental validation. Reference measurements instead of
   changing inputs to obtain an accepted result.

An OCE scan-axis comparison table is a descriptive summary; it is not a substitute
for original signed-direction observations. Requested sample Hz, physical QH
excitation, actual selected-bin Hz and original/aligned bin axes must stay distinct.
Pulse periods describe acquisition conditions, not independent spectral groups.

## Experimental pilots and combined observations

Keep pilot configuration and results in a configurable external analysis root.
Retain relative source references with an explicitly supplied experiment root,
repository revisions and uncommitted patch hashes, original source hashes,
reviewed masks, full requests/results and output hashes. Relocation changes root
configuration, not datasets, saved observations or scientific APIs. Preserve
earlier reports as historical evidence; do not silently overwrite them.

The maintained manual driver is `workflows/inversion/run_ae_plate_oce_inversion.m`.
`integrations/oce/` owns the existing translation/preparation and QH coordinator
APIs, not the study script. Dataset-specific selections, physical review and
outputs remain external. The study coordinates canonical APIs in separately
executable MATLAB sections.

An exploratory fit may explicitly declare A0 and remaining model support as
working hypotheses. Record that evidence class separately from reviewed physical
inputs and the native accepted/rejected status; numerical acceptance cannot
confirm the modal or material assumptions. A representative scalar current OCT
thickness requires an explicit condition/direction selection policy and all
original measurements with their descriptive variability. A median or range is
not a calibrated uncertainty estimate, and no scalar is silently reused across
states or directions.

QH-Pulse condition matching is an explicit reviewed assertion, not a consequence
of equal specimen names, folder labels, strain text or scan-axis numbers. Record
the physical state correspondence and signed propagation geometry. Missing strain
remains missing; a support document can be referenced without rewriting metadata.

A joint QH+Pulse inversion additionally requires documented compatibility of the
current material state, physical/modal support, thickness/density reference,
calibration, geometry and observation eligibility. Review dependence/correlation,
relative acquisition multiplicity and the selected model's residual definition.
Do not automatically concatenate observations, assign equal dataset influence,
discard correlated bins or turn Pulse periods into frequency groups. Plate's
optional physical QH groups qualify its existing coverage screen; they do not
define a joint-dataset weighting or independence policy. A combined request that
lacks these decisions remains explicitly blocked, rather than introducing a new
solver or implying experimental validation from a native accepted result.

When Plate receives no optional explicit group IDs, its legacy diagnostics group
exact observed Hz. For a Pulse curve this does not establish independent physical
excitations or statistical independence of spectral bins. Preserve that native
meaning instead of borrowing the physical QH grouping interpretation.

## Inverse presentation after native fitting

Use the [visualization contract](../visualization/README.md) to present
stored Plate results and their reviewed request/provenance. Do not rerun fitting
to generate figures. Supply original ridge evidence and repetition identities
where available, retain excluded/nonfinite rows, and distinguish the fixed native
mask from robust/shared display limits. Save complete inspection views when
shared limits clip original observations or predictions. Figure data retains
the source references and clipping counts, including maxima outside the scale.

Parameter trends require explicit caller-reviewed mechanical coordinates and
signed axes. Pooled repetitions, raw/smoothed variants and per-repetition analyses
are not independent experiments. Keep modal/model-support limitations visible and
retain rejected native results. A later metadata correction must reference its
separate correction record; a plot must not rewrite a historical request/result
or silently invent the missing original metadata. Figures and FIG/TIF exports
are derived presentation, not new canonical scientific products. Other native
families keep their own equations, data requirements and residual definitions.

## Validation boundary

The maintained OCE-preparation suite tests lossless translation and direct/native
equivalence for all four families. Negative cases retain excluded DC and duplicate
axis entries and assert native model restrictions, rather than repairing them.
The native Plate/QH suites own its two-group coverage extension. Each repository's
maintained gate owns regression evidence; no reference update is part of integration.

Synthetic tests establish API/contract behavior. They do not certify hardware,
experimental provenance after same-ID edits, statistical independence, model
selection, modal purity, material assumptions or experimental fit validity.
