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

## Canonical public physical inputs

New human-facing inputs use SI unit-qualified physical names shared across
families: `density_kgpm3` (kg/m^3), `thickness_m` (current full m),
`poisson_ratio` (dimensionless), and `mu_Pa` where a dimensional shear
modulus is entered. The RL public fitting builder accepts these three fixed
physical fields and maps them to unchanged native solver symbols
(`rho`, `thickness`, `nu`) only at its request boundary. Existing native
solver and historical MAT fields retain their model-owned names and semantics;
legacy fixed-parameter names cannot be supplied alongside their canonical
counterparts. Plate already uses `density_kgpm3` and `thickness_m`.
Directional current thickness measured by OCE is still handled per original
acquisition; the scalar field is only a reference under that reviewed policy.

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
| `excitationMode`, `period_us`, `repetitions`, `scanAxisIndex`, `direction`, `curve` | QH/Pulse, literal Pulse period, repetition labels, signed direction and an existing raw/smoothed curve. |
| `fitFrequencySelection`, `fitFrequency_Hz`, `fullBandReviewed` | `all` requires an explicit `fullBandReviewed=true` acknowledgement in both manual and batch workflows; `interval=[low high]` and `explicit` select reviewed observed/nominal Hz. This acknowledgement does not validate any source-quality row. No nearest-valid repair or interpolation. |
| `physical`, `review` | Native Plate density and explicit A0/thickness/density/support review; default direction-matched OCE current full thickness per original row, optional reviewed scalar alternative. |
| `fitOptions` | Native options, forwarded unchanged. Empty options reuse a supplied result's effective settings; a new request otherwise uses native defaults. |
| `existingNativeResult`, `existingAssembly`, `resultFile`, `reuseOnly` | Approved native objects or a MAT with `nativeResult` and `assembly`. Default `reuseOnly=true` rejects changed requests before fitting. |
| `plotTargetFrequency_Hz` | Pulse graphic targets, independent of fitting selection; compatible OCE sampling is preferred. |
| `showFigure`, `displayLabel`, `displaySubtitle` | One diagnostic with the approved fixed typography and renderer. |
| `saveResult`, `exportFigure`, `figureFolder`, `figureName` | Opt-in persistence; defaults create no files. Existing destinations are never overwritten. |

For `explicit`, `fitFrequency_Hz` contains researcher-requested nominal frequencies.
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

The default thickness policy for the **manual single-study** workflow is
`oce_directional_per_acquisition` for both QH and Pulse; experiment-wide batch
defaults to a reviewed median (`oce_median_per_case`). Under the per-acquisition
policy, the native Plate SVD takes `experimental.observationThickness_m`
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
scalar policies use `physical.thickness_m` across all rows. The batch
median policy is also scalar, counting distinct selected acquisitions once each
regardless of their number of frequency observations. Original SVD,
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
Manual single-study workflows still default to `oce_directional_per_acquisition`.
The experiment-wide batch defaults to `oce_median_per_case`, using a single
source-derived current full thickness per reviewed condition, axis and direction.
Do not rewrite archived reviews, physical inputs or native results.

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
| `fitConfig` | Native branch, fixed/free parameters, initial guesses, bounds, solver options and fitting options; no Plate group policy or SVD fields. Units are native SI. Scalar `fixedParams.thickness_m` is used under `explicit_constant` or `oce_median_per_case`; per-observation OCE geometry instead uses `experimental.observationThickness_m`. |
| `thicknessPolicy` | Manual single default `oce_directional_per_acquisition`: one source-recorded current full directional thickness per observation. Batch default `oce_median_per_case`: one median across unique selected acquisitions, shared by every fitting row. `explicit_constant` retains an independently reviewed scalar. Missing selected acquisition thickness rejects the median request. |
| `review` | Derived `modelBranch`, `thicknessSource`, `thicknessJustification`, `densitySource`, `fitParameterJustification` and `modelAssumptionsJustification`. Explain measured fixed inputs and any fitted-parameter bounds/initial values, without inventing experimental validity. In the OCE thickness policy, source/justification are set to the actual recorded measurement policy. |

The current full thickness comes from the already selected OCE signed direction
(`borders.directional_mean_thickness_mm`, converted to meters). QH retains a
separate thickness for each selected acquisition/frequency; Pulse repeats each
acquisition's thickness only across that acquisition's original FFT bins. No
median or pooling is applied in this **per-acquisition** policy; the batch
`oce_median_per_case` option deliberately computes one scalar across selected
acquisitions, never averaging their frequency observations. The native
Rayleigh-Lamb evaluator solves separately on
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
requires a specific `fullBandReviewed=true` acknowledgement for `all`.
The same acknowledgement is required by manual MATLAB Editor workflows at
the shared observation-preparation boundary.
A read-only batch plan is the default; enabling `plan.execute=true` authorizes
native fitting. Output MAT, FIG and TIF are independently controlled. With
`plan.reuseOnly=true`, an existing exact-match `inversion.mat` is reused
read-only and is not rewritten; its recorded input-file hashes must match the
current sources. Reused MAT and newly exported figures must also retain the
same researcher-supplied scientific `review` (after read-only legacy name
normalization). Changed scientific hypotheses require a separately reviewed
output tag, or presentation explicitly disconnected from the saved MAT
(`saveResult=false`). Numerical equality alone does not authorize changing
archived scientific claims. Figure destinations remain non-overwritable. Any
historic `studyRecord.selection` naming is normalized in the returned record only.
Legacy visualization `modelSupportReference` and prior review-source labels
are accepted at a read-only provenance boundary, not rewritten into older MATs.
The derived `review` must remain separate from editable `study.review` so
manual MATLAB Editor review sections can be repeated without inconsistent state.

Manual single-study workflows retain their original output layout relative
to `experimentRoot`:
`Results/<subexperiment>/Inversions/<RayleighLamb|Plate>/<case>/inversion.{mat,fig,tif}`.
Batch runs instead default to an external `OCE_Inversions` output root,
`fullfile(fileparts(experimentRoot),"OCE_Inversions")`, with this layout:
`<experiment>/<subexperiment>/<RayleighLamb|Plate>/<case>/inversion.{mat,fig,tif}`.
The human batch workflow exposes optional `inversions_root`; the programmable
batch accepts optional `plan.inversionsRoot`. Both point to the absolute
external output root, not to an individual experiment output directory.
`experimentRoot` continues to anchor OCE source recovery and source hashes.
`outputRelativeFolder`, `outputTag` and `summaryRelativeFile` remain
optional: output overrides are root-relative to the active output base, and
summary overrides are always relative to `experimentRoot`. No absolute
per-case output override or parent traversal is supported, and existing
outputs are never replaced. `outputTag` distinguishes independent fit
reviews with the same physical case identity.
The batch `studyRecord.selection.outputBase="inversionsRoot"` explicitly
identifies how to interpret `selection.outputRelativeFolder` without saving
machine-specific paths. For single-study results, the legacy selection schema
is unchanged and implicitly refers to `experimentRoot`. The resulting
`studyRecord` retains fixed observation masks, original row mappings and
input hashes relative to `experimentRoot`; the original native OCE payload
and mechanical review remain alongside it.
Batch failures with `saveResult=true` create a separate
`inversion_failure.mat`, retaining the reviewed request, error identifier,
portable stack-location names and UTC time; an earlier failure file is never
replaced. `saveResult=false` leaves the failure in the returned batch report
only. A failure before fitting is **not** a fitted result or physical finding.
If native fitting succeeds but persistence or presentation fails, the batch
reports `partial` and retains the native result and metrics in memory. Its
failure record distinguishes the completed stage and references any saved
native MAT by a path relative to the batch `inversionsRoot`, with
a `nativeResultBase` marker. A one-output call to
`executeOceInversionStudy` still raises downstream errors; its optional second
output returns that error alongside the completed fit for batch coordination.

**Batch geometry policy:** `thickness_policy="oce_median_per_case"` takes one
recorded full directional OCE thickness from each distinct acquisition with
at least one selected fitting observation. The median across those acquisitions
is the sole current full thickness for every retained frequency and repetition
within that case, in both RL and Plate. Original thicknesses, identities and
masks remain in `assembly`; the derived scalar and policy are retained in the
native request and review. Technical repeats are not interpreted as independent
mechanical states. RL still fits one material `mu`, Plate one shared
`alpha,gamma`; the native Plate QH physical-frequency coverage check is unchanged.
The legacy `oce_directional_per_acquisition` policy remains available for both
models and produces thickness-specific model predictions. Other scalar policies
remain available for separately reviewed geometries.

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
