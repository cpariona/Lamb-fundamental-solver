# Reproducible OCE studies with native Lamb fitting families

OCE owns acquisition processing, persisted scientific products, summary identity,
source recovery and descriptive comparison. Lamb owns model physics, inverse
algorithms, model-specific validation and native results. A study coordinates
their maintained APIs; it does not decode OCE files, repair scientific observations,
select alternate branches, duplicate fitting or implement another dispatcher.

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
| Rayleigh-Lamb: `lamb.fitting.rayleigh_lamb.rlFitDispersionData` | Elastic parameters, current thickness, density, supported near-incompressible Poisson ratio; explicit A0/S0 choice, fixed/free parameters, bounds and execution options. Fitting requires a positive finite full frequency axis. Its evaluator maps requested observations through the canonical RL solver. | Fixed-mask model coverage, optimizer result, residuals/metrics, sensitivity and local identifiability; selected A0/S0 output and native diagnostics. |
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

Select models from reviewed physical assumptions before interpreting fitted
parameters. Native residual definitions, units and weighting can differ: Plate's
regression residuals in Pa are not directly comparable to speed or normalized
residuals from another family. This integration supplies no cross-model score or
automatic model-selection rule.

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

## Validation boundary

The maintained OCE-preparation suite tests lossless translation and direct/native
equivalence for all four families. Negative cases retain excluded DC and duplicate
axis entries and assert native model restrictions, rather than repairing them.
The native Plate/QH suites own its two-group coverage extension. Each repository's
maintained gate owns regression evidence; no reference update is part of integration.

Synthetic tests establish API/contract behavior. They do not certify hardware,
experimental provenance after same-ID edits, statistical independence, model
selection, modal purity, material assumptions or experimental fit validity.
