# Architecture and ownership

## Repository domains

| Location | Responsibility |
| --- | --- |
| `src/+lamb/` | Forward science and inverse fitting |
| `integrations/oce/` | Translation of validated external observations and reviewed QH coordination |
| `visualization/` | GUI-independent scientific presentation and figure export |
| `app/` | GUI interaction, app request/result adaptation and execution profiles |
| `studies/` | Opt-in scientific investigations consuming production APIs |
| `examples/` | Opt-in usage examples consuming production APIs |
| `tests/` | Executable contracts, regressions, performance checks and tooling |

## Production ownership

| Package under `src/+lamb/` | Owner responsibility |
| --- | --- |
| `+models` | Forward physics, configuration, tracking, selection, validity, quality and canonical results |
| `+fitting` | Experimental-data validation, family adapters, objectives, optimization, metrics and sensitivity |
| `+elasticity` | Model-neutral material conversions |
| `+grids` | Model-neutral frequency-grid construction |
| `+sweeps` | Parameter-sweep execution through supplied production operations |

The model families are `rayleigh_lamb`, `mrlfe`, `acoustoelastic_iop_hgo`, and
`acoustoelastic_prestressed_plate`. Each owns its physical formulation and
numerical selection pipeline; their internal structures reflect different physics.

Rayleigh-Lamb keeps parameter validation, material/geometry construction,
physical branch identity, the regular boundary equation and continuation directly
in its family package. `rlComputeFundamentalLambModes` owns the complete solve,
with local option validation, result assembly and selected-mode quality assessment.
The `approximations` package retains its public analytical-reference operation.

mRLFE keeps request/preset resolution in `configuration`, problem construction
and residual physics in `core`, seed/discovery/refinement in `tracking`,
termination in `policies`, output assembly in `results` and selected-curve
assessment in `quality`. `mrlfeSolve` owns the branch workflow once; explicit
elastic and viscous option preparation feeds the same seed/tracking/policy chain.

AE retains constitutive/prestress, residual physics, atlas construction,
tracking/refinement, selection policy, result and quality boundaries. `solvers`
owns the production atlas operations; `diagnostics` owns direct real-Cp solves
and identity evidence. Diagnostic results do not replace official `atlasA0`
arrays. The result owner is reused by atlas and requested-grid assembly.

The acoustoelastic prestressed-plate family owns the dimensionless physical A0
curve, forward prediction and principal-state interpretation in
`models.acoustoelastic_prestressed_plate`.
`fitting.acoustoelastic_prestressed_plate` owns its fixed-mask data validation, direct
linear SVD regression and identification diagnostics. It consumes the public
master curve, with no nonlinear optimizer or family adapter framework.
It currently supports A0 only, following Li et al. (2022), and is
independent of AE IOP/HGO and its atlas.

Model-family and principal API identifiers describe physical formulations,
without publication-year branding or individual mode names. Established
scientific model names such as Rayleigh-Lamb and HGO retain their conventional
meaning; they are not identifiers derived from one publication. Mode-specific
mathematical helpers may identify their mode, such as `aePlateA0MasterCurve`.

Dependencies point toward scientific owners. Models do not depend on fitting,
integration, visualization, app, studies, examples, tests or documentation. Fitting calls canonical public
model APIs. Production never depends on studies, examples, tests or documentation.
The sole intentional cross-family scientific dependency is the mRLFE seed through
the public Rayleigh-Lamb solver. Model-neutral utilities do not own family policy.

## Canonical scientific chains

Rayleigh-Lamb:

```text
request/config -> material + geometry -> physical A0/S0 identity
-> regular boundary equation / request-independent continuation -> canonical result
```

mRLFE:

```text
request/config -> problem -> public RL seed -> discrete candidate discovery
-> selection -> bounded selected-candidate refinement
-> validity/termination -> canonical result
```

AE IOP/HGO:

```text
request/config -> constitutive/prestress state -> fixed atlas -> minima/linking
-> atlasA0 selection -> bounded true-SVD refinement -> validity -> canonical result
```

Nonlinear fitting (Rayleigh-Lamb, mRLFE and AE IOP/HGO):

```text
experimental fixed mask -> family adapter -> canonical public model
-> residual/objective -> optimizer -> metrics/sensitivity
```

Acoustoelastic prestressed plate (current A0 support):

```text
q = k*currentHalfThickness -> deflated physical A0 master curve
-> frequency-domain forward prediction

fixed A0 observations + current density/thickness + single condition/direction
-> measured kh -> master curve eta^2 -> linear SVD -> rank/coverage/support
```

Quality assesses an already selected curve. Diagnostic evidence remains separate
from official scientific arrays; AE official output is `atlasA0`.

## Inverse inputs versus external validation

Every inverse fit consumes only the measured observations, known physical quantities
and assumptions explicitly required by its selected scientific model. Experimental
control variables and independently measured validation quantities are not
automatically fit inputs, constraints, regularizers or priors merely because they
are available. The family-specific physics contract takes precedence: this rule
must not omit a prestress, deformation or other input genuinely required by a
different model.

For the supported Li-style prestressed-plate A0 inversion, applied loading mass,
externally estimated force and DIC-derived stretch are not required to estimate
the model's identifiable acoustoelastic coefficients from suitable wave
observations, measured current thickness and independently supplied material
density. Any stress/stretch derived from fitted coefficients is conditional on
the model's stated constitutive, deformation and principal-direction assumptions,
and cannot be reported as identified when the inverse problem lacks adequate
independent information. One measured frequency or multiple technical repeats
do not themselves guarantee identifiability.

Loading condition IDs may organize observations and distinguish experiments;
their physical load values need not appear in inversion figures. Independent
load/geometry-based stress and DIC-based local strain estimates are separate
comparison and validation products, not implicit optimization evidence. Preserve
their provenance and uncertainty without changing the original OCE observations,
fitting masks or scientific ownership.

## Consumer domains and dependency boundaries

The following table lists permitted outward dependencies. Collaboration within
each domain remains permitted; no production domain depends on studies, examples,
tests or documentation. The dependency tests inspect existing tracked and untracked
candidate files and exclude paths removed from the working tree.

| Consumer | Permitted dependencies |
| --- | --- |
| Models and neutral scientific utilities | Canonical scientific owners; the sole cross-family seed is mRLFE to public RL |
| Fitting | Public model APIs and scientific fitting utilities |
| OCE preparation | Validated OCE products and integration-local operations; no fitting, physics, GUI or schema I/O |
| QH Plate coordinator | Prepared QH observations and the native Plate fitting API |
| Visualization | Native result values and public forward/interpretation APIs; no fitting, integration, GUI or OCE package dependency |
| GUI/app | Integration, scientific APIs and visualization; no study or example implementation |
| Studies and scientific examples | Public scientific, integration and visualization APIs; no GUI internals or tests |

These are domain rules, not per-function exceptions. The model/fitting core remains
independent of optional producers. OCE's loader/recovery APIs remain its authority;
manual callers initialize OCE explicitly. `configureProjectPath` exposes app,
`integrations/oce/` and `visualization/` while studies, examples, tests and outputs
remain opt-in. Public function names are unchanged; no compatibility copies or
forwarding wrappers remain in the former app locations.

## Presentation boundary

`visualization/` owns GUI-independent presentation of native inverse results,
reviewed experimental coordinates, display-only Cp limits and FIG/TIF export.
Its first scientific presentation is Plate A0: it consumes unchanged native
coefficients, residuals, masks and acceptance diagnostics. Supported candidate
predictions and conditional principal interpretation call existing public Plate
model APIs. It invokes no fitting engine, reads no OCE files and does not depend
on studies or GUI initialization. See the [visualization contract](../../visualization/README.md).
Native RL diagnostics consume stored phase-speed predictions and raw m/s residuals
without forward evaluation or fitting; they retain RL's own result semantics.
Observation preparation, scientific inversion and presentation remain separate.
Neither the GUI-specific normalized renderer in `app/fitting/` nor the study-only
sensitivity presentation is moved or replaced. Reusable scale/export conventions
do not impose Plate fields or thresholds on other model families.

`prepareOceFitObservations` in `integrations/oce/` performs
model-independent request translation from an already validated OCE scientific
result. It is available
through the maintained startup path setup; it requires no GUI initialization.
OCE owns acquisition processing, schema validation and result I/O, through
`oce.results.validateScientificResult` and `oce.io.loadScientificResult`. The
translator reads their validated product; it neither decodes MAT/BIN files nor
implements a competing OCE schema validator.

The caller selects one acquisition-order signed direction, estimator and explicit
observation mask. Preparation preserves the original frequency/Cp rows, source
validity/interpolation/extrapolation masks, estimator identity, condition, repetition,
loading metadata, measured directional thickness and provenance. It rejects invalid
selected numbers at the external-observation boundary so downstream fitting
normalization cannot silently shrink the supplied mask. It does not use the GUI file-import
path, which intentionally removes invalid rows, sorts and can collapse duplicates.
Excluded observations and unknown thickness remain visible. Source ridge support
and the reviewed fitting mask are distinct evidence; no mask is derived or repaired.

Consumers pass `prepared.experimental` directly to the canonical family APIs:
`rlFitDispersionData`, `mrlfeFitDispersionData`, `aeFitDispersionData`, or
`aePlateFitDispersion`, in their respective `lamb.fitting` family packages.
Consumers explicitly supply each family's physical parameters, modal/branch choice,
fit configuration and support assessment. The translator selects no model, density,
mode, weighting, inverse equation or optimizer and invokes no family API. Measured
thickness is a physical observation, not a universal family-parameter mapping.
Family-specific restrictions, including full-axis frequency support, remain visible
as errors/rejections; integration must not trim or average inputs to bypass them.

Preparation has no dependency on model or fitting implementations. Nonlinear fitting
normalizes its own inputs; the direct plate fit consumes the minimal numeric request
without generated counts or empty uncertainty fields. Models/fitting never depend on
the translator. OCE remains the schema/I/O authority; preparation neither invokes a
family API nor owns its physics, optimizer or support decisions.

Read-only OCE result inspection in studies or examples does not establish a second
translation owner. The repository enforces dependency direction and absence of science,
GUI import and native schema I/O in preparation, rather than prohibiting field access.
Studies and examples consume reusable integration/visualization domains directly;
they do not depend on app components or maintain a duplicate adapter.

`prepareOceQhFitObservations` assembles explicitly reviewed k-f target rows from
OCE's recovered acquisitions, using `prepareOceFitObservations` once per signed
direction/acquisition. It preserves physical versus selected frequencies,
repetitions, measured thickness, original masks and full preparation lineage.
Request identity fixes one intended experiment and subexperiment, verifies original
result identity and preserves optional specimen-ID availability. Summary row numbers
remain local references; original result paths retain acquisition identity.
`fitOceQhPrestressedPlate` coordinates only the current Plate A0 fit after explicit
physical review. When physical and observed-Hz frequency partitions differ, it
passes explicit physical-frequency group codes to Plate's existing coverage
diagnostic while preserving observed Hz and the unweighted regression. Compatible
partitions retain the historical call. It requires a justified externally supplied constant current full thickness
with its source. Original OCT thicknesses, including NaNs, remain separate evidence;
their availability is not a universal prerequisite for an independent thickness input.
Compact OCT availability/range diagnostics belong to integration and do not alter native
scientific diagnostics or acceptance.
The OCE recovery dependency is optional and remains outside Lamb's scientific
packages. Equations, SVD and acceptance thresholds remain owned by Plate;
integration neither rounds frequencies nor supplies alternative rank diagnostics.
Mass, transmitted force and independent DIC strain do not enter this inversion.
See the [QH integration contract](../../integrations/oce/README.md#reviewed-qh-target-assembly-and-plate-coordination)
for the explicit-group contract and remaining physical thickness boundaries.

App translates UI state into requests and coordinates, presents or persists
already computed results. It never owns science. Physical parameters, numerical
options, execution profiles and UI state have distinct owners. Profiles vary
effort while preserving physical meaning. Public model and fitting entrypoints
are listed in [README](../../README.md); use MATLAB help for their SI inputs,
full physical thickness convention, unit-qualified outputs and validity contracts.

[AGENTS](../../AGENTS.md) owns modification policy and links to local invariants.
[Validation](validation_status.md) owns the canonical test contract.
