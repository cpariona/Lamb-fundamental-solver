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
| Prestressed Plate: `lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion` | Reviewed A0 support, one condition and signed principal direction, scalar current full thickness and density. Original unweighted Li regression. At least **two** independent frequency groups plus its existing observation/group rank, conditioning, eta-squared span and tensile-support screens. Optional `independentFrequencyGroupId` belongs to this family only. | `accepted`, `reasons`, unconstrained candidate moduli/residuals and explicit observation/group diagnostics. A returned candidate is not necessarily accepted. |
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

## Maintained manual Plate study

The single executable workflow is [aePlateOceStudy.m](../studies/aePlateOceStudy.m).
It replaces the pilot preview/export coordinator. It contains no specimen names,
absolute study paths, FIG input dependency, frequency optimizer or model dispatcher.
Initialize the reviewed OCE `src` path explicitly; Lamb startup supplies its integration and visualization APIs.

Open the script, clear `study` to reset configuration, then run/edit section 1.
Execute sections 2--7 manually, or run the script with a configured `study` in the
workspace. Inspect `sourceMetadata` and `observationReview` before fitting. They
retain source rows/bins, repetitions, actual Hz, original flags and the final mask.

| Configuration | Meaning |
| --- | --- |
| `experimentRoot`, `summaryFile` | OCE root and persisted MAT containing `experiment`; OCE owns recovery. |
| `experimentId`, `subexperimentId`, `sampleId`, `conditionId`, `condition` | Explicit identities and scalar mechanical condition entries: literal text for stored text, exact doubles for stored doubles. No folder-name inference or cross-type coercion. |
| `mode`, `period_us`, `repetitions`, `scanAxisIndex`, `direction`, `curve` | QH/Pulse, literal Pulse period, repetition labels, signed direction and an existing raw/smoothed curve. |
| `frequencySelection`, `frequency_Hz` | `all`, inclusive observed-Hz `interval=[low high]`, or `explicit` nominal requests mapped to original observations. No nearest-valid repair or interpolation. |
| `physical`, `review` | Native Plate density/current full scalar thickness and explicit A0/thickness/density/support review. |
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

The single thickness policy is an explicit reviewed constant current full thickness
in `physical.thickness_m`, for either modality. Its source and scalar-selection
justification are required. A researcher may supply a median of reviewed OCT
measurements or an independent measurement; the study never silently changes
the measurement population by mode or invents uncertainty.

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

- `selection`: experiment/root/summary references, condition with its original
  value types, modality/period, repetitions, signed axis, curve, frequency mode,
  nominal frequencies and effective requested graphic frequencies.
- `code.Lamb` and `code.OCE`: resolved repository roots, Git commits, porcelain
  modification/untracked status and availability. Missing Git evidence is explicit;
  a dirty status requires preserving the corresponding code changes separately.
- `matlabVersion`, `matlabRelease`, and `inputFiles` (path, bytes, SHA-256).
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
from the native result without reopening OCE files. Root paths remain explicit
and can be relocated by the researcher. No raw BIN, ProcessingConfig or
ProcessingRun manifest is read or hashed by this study; their references are
producer provenance, not verified historical inputs. Physical review references
are caller attestations, not additional files implicitly read by the study.

Use OCE PR #146's exact-identity producer/recovery contract; the integration README
pins its revision and legacy ambiguity boundary. No local label normalizer or
summary migration belongs to Lamb.

A historical review may name the scalar-selection method as its thickness policy.
For the current study, declare `explicit_constant_current_thickness` and retain
that selection method in the justification; do not rewrite the archived review,
scalar physical input or native result.

Pulse uses compatible OCE selected Hz or original bins nearest explicit graphic
targets before applying validity. Missing/excluded bins stay absent. Per-source
graphic masks are checked against the renderer's exact-Hz selection; incompatible
grids require review instead of silently selecting additional rows. All numerical
diagnostics and acceptance still describe the complete fixed fitting request.

Workspace outputs include `frequencySelectionMapping`, `assembly`, `observationReview`, `nativeResult`, `reusedResult`
and, when requested, `fig`/`figureEvidence`. This study is Plate only. RL, mRLFE and
IOP/HGO retain their model-specific direct APIs and scientific requirements.

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

The maintained manual driver is `studies/aePlateOceStudy.m`.
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
