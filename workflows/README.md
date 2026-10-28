# Human research workflows

`workflows/` contains the maintained MATLAB Editor scripts for applying native
Lamb inverse models to reviewed OCE acquisitions. Callable functions live in
`workflows/inversion/`. Both are **opt-in**: ordinary `startup`
intentionally does not add workflows to the path.

| Open in MATLAB Editor | Scientific fitting owner |
| --- | --- |
| [run_rl_oce_inversion.m](run_rl_oce_inversion.m) | Rayleigh–Lamb A0/S0, native nonlinear fitting |
| [run_ae_plate_oce_inversion.m](run_ae_plate_oce_inversion.m) | Prestressed Plate A0, native linear SVD fitting |

## Run Section procedure

1. Open **one of the actual workflow files** in MATLAB Editor, not a copied
   command-window section or temporary `.m` file.
2. Execute **section 1** to initialize editable `study` options; set the local
   `oce_repository_root` and the persisted OCE experiment root/summary path.
   Inspect the exact experiment/subexperiment/sample/repetition/condition IDs in
   the original acquisition log. Numeric condition keys use their exact saved
   `double` values; Pulse periods are literal recorded text.
3. Execute **section 2** to initialize Lamb, the opt-in inversion workflow path,
   and OCE recovery. This deliberately uses
   `matlab.desktop.editor.getActiveFilename`, not `mfilename('fullpath')`.
4. Execute **section 3** to recover the original OCE observations, then
   **section 4** to inspect `sourceMetadata`, `observationReview`, selected
   rows and original masks. In Plate, the review output is printed in section 3
   and section 4 reviews physical inputs.
5. Populate the model-specific physical configuration and review justifications.
   Rayleigh–Lamb defaults to `study.thicknessPolicy="oce_directional_per_acquisition"`:
   its native fitter uses OCE's exact signed-direction thickness for each
   observation, retaining one acquisition thickness across Pulse frequency bins
   and each original QH thickness independently. Missing recorded thickness
   is an error; no median or average is substituted. `"explicit_constant"`
   permits a separately reviewed scalar alternative. Prestressed Plate
   now defaults to that same OCE directional policy: each original
   observation contributes its own current full `h_i` to the native
   `q_i=pi*f_i*h_i/Cp_i`, while one pair of `alpha,gamma` remains shared
   for the reviewed physical condition/direction. The former fixed-height
   behavior remains available with
   `study.thicknessPolicy="explicit_constant_current_thickness"` and
   `study.physical.thickness_m`. Alternatively,
   `"oce_reference_acquisition"` and
   `study.thicknessReferenceSourceIndex` select exactly one OCE geometry
   as a constant reference. No native SVD weighting, frequency grouping or
   numerical-acceptance criteria are changed.
   **Do not treat numeric acceptance as experimental model validation.**
   In both human MATLAB Editor workflows, setting
   `study.fitFrequencySelection="all"` requires explicitly setting
   `study.fullBandReviewed=true` after reviewing the band. This does not
   certify A0 purity or bypass the fixed observation mask.
6. Fitting is disabled by default (`study.reuseOnly=true`). Only after
   inspecting the request set `study.reuseOnly=false` in the workspace, then
   run the corresponding fit section (RL section 6; Plate section 5).
7. Saving MAT and exporting FIG/TIF are independently disabled by default.
   When enabled, paths are automatically resolved under the experiment root
   (see next section); absolute paths are not accepted as overrides.
   Optional `study.displayLabel` and `study.displaySubtitle` override
   figure text only when nonempty. Otherwise, the workflow builds a label
   from sample/subexperiment/signed direction and leaves native model-specific
   title/subtitle defaults in place. Source material and model-assumption
   references remain mandatory.

A failed or edited upstream section invalidates downstream workspace values.
Re-run dependent sections, not only the last fitting or export step.


## OCE source dependency versus shared engineering standard

Lamb's `.research-automation` submodule pins the **engineering standard** from
Research-Automation; it does **not** vendor OCE_Workflow's MATLAB `+oce`
package or guarantee that OCE's code is installed. Lamb's `integrations/oce`
is an opt-in translation layer, not a replacement OCE reader.
`oceRepositoryRoot` locates a maintained OCE_Workflow checkout whose
`oce.results.recoverSummaryObservations` and `oce.io.loadAcquisitionTable`
APIs recover and validate source metadata. The code checkout is a machine-local
dependency, while output/input paths are experiment-root-relative.
A future per-machine MATLAB path bootstrap could register the producer
once instead of exposing a checkout root in every request, provided its
API revision is checked; the current workflows deliberately do not infer a
parent folder or silently choose a different producer revision.

## Default storage and relative overrides

Only `study.experimentRoot` and the OCE repository code location are
machine-specific input anchors. No general filesystem destinations are
hard-coded in any workflow. Unless overridden, the input summary is
`Results/<subexperiment>/summary.mat` relative to the experiment root and
output is:

```text
Results/<subexperiment>/Inversions/<RayleighLamb|Plate>/<case>/
    inversion.mat
    inversion.fig
    inversion.tif
```

The case identifier is derived deterministically from the excitation mode,
Pulse period, reviewed condition ID and signed scan direction. **The bandwidth
is not part of this identifier**: a distinct fit/band for the same physical
case must use a new reviewed `study.outputTag` to avoid collisions. A caller or
agent can supply `study.outputRelativeFolder` to redirect output anywhere
**inside the same experiment root**. Both custom fields are optional and not
needed in the MATLAB Editor's user configuration section. For a nonstandard
summary location use `study.summaryRelativeFile`; absolute summary/output
overrides and parent-directory traversal are rejected. Generated outputs are
never overwritten. Updating `study.subexperimentId` recomputes default paths
instead of keeping destinations from the preceding study.

The layout above is unchanged for **manual single** inversions. The batch
runner instead uses an external `OCE_Inversions` directory by default,
next to `OCE_Experiments` under the same user-chosen parent directory:

```text
<user-chosen-parent>/OCE_Experiments/<experiment>/Results/...
<user-chosen-parent>/OCE_Inversions/<experiment>/<subexperiment>/
    RayleighLamb/<case>/inversion.{mat,fig,tif}
    Plate/<case>/inversion.{mat,fig,tif}
```

The batch never relocates or edits OCE `Results` inputs. Set
`inversions_root` (human Editor workflow) or `plan.inversionsRoot`
(programmatic API) to an **absolute** `OCE_Inversions` destination if desired.
This default applies only when `experimentRoot` is directly inside
`OCE_Experiments`; it uses
`fullfile(fileparts(fileparts(experimentRoot)),"OCE_Inversions")`.
For any other directory layout, supply an explicit absolute `inversions_root`
or `plan.inversionsRoot`. The parent directory can have any name.
Batch `outputRelativeFolder` overrides are interpreted relative to that
external root; manual single overrides remain relative to `experimentRoot`.
All output tags, no-overwrite checks, optional FIG/TIF and failure records
still apply. No existing inversion outputs are migrated.

## Human experiment-wide inversion batch

Open [run_experiment_inversion_batch.m](run_experiment_inversion_batch.m)
in **MATLAB Editor** and run its sections in order. Set `experiment_root`,
`oce_repository_root`, `condition_keys` (the exact recorded mechanical
metadata columns), the selected models/directions/repetitions, and the
model-specific reviewed physical inputs in section 1. For uniaxial-stretch
acquisitions `condition_keys="strain_percent"` is an example, not a value
inferred from a folder name.

Use the shared `material` and `geometry` configuration with explicit SI fields:
`density_kgpm3` (kg/m^3), `geometry.thickness_m` (current full m, a
placeholder replaced by OCE for median/per-acquisition geometry policies), and
`poisson_ratio` (dimensionless, RL only). Set the independent
`rl_mu_initial_guess_Pa` and `rl_mu_bounds_Pa`, and provide the model-specific
model-assumption justifications. The public RL fitting boundary maps those
unit-qualified inputs to its retained native mathematical parameter symbols;
Plate accepts the same density/thickness fields directly. Do not assign
placeholder values or infer physical parameters from paths.

For an experiment-wide batch, `thickness_policy="oce_median_per_case"`
is the default. Each acquisition with a selected fitting row contributes its
directional OCE thickness **once**, regardless of how many original frequency
rows it contains. The median is applied to all selected frequencies and
repetitions in one case. This is a deliberate uniform-plate approximation, not
a measurement of spatial thickness uniformity. The measured source values
remain in the saved assembly. Changing the geometry policy requires a new
output case; no existing inversion MAT/FIG/TIF is overwritten.

For clarity, `excitationMode` means QH/Pulse, native RL `branchName` means
A0/S0, and `review.modelBranch` is derived rather than entered twice.
`fit_frequency_selection`/`fit_frequency_hz` affect the fitting mask;
`plot_target_frequency_hz` only requests Pulse figure samples.
`full_band_reviewed=true` acknowledges use of all eligible fitting Hz, not
acceptance of invalid ridge bins or experimental A0 purity. Fields named
`*_model_assumptions_justification` document experimental hypotheses,
not a substitute for native support/acceptance diagnostics. The stable case
folder ID includes a source-condition fingerprint to distinguish different
literal strings, exponent signs and full-precision numeric values. Numeric
`strain_percent` is displayed with three significant digits (for example,
`Strain_3_44pct_<8-hex fingerprint>`); the fingerprint continues to use the
exact recorded double. This display rounding never changes condition selection
or the scientific input. Existing output directories are not renamed or
overwritten; differently named results are new output cases.

Section 2 locates `Results/<subexperiment>/summary.mat` files and uses
`oce.results.recoverSummaryObservations` to validate and discover existing
acquisitions. Recorded frequencies and repetitions are not treated as
mechanical conditions. Original Pulse periods are preserved verbatim. Current OCE integration
requires the recorded `rep_id` to convert to a finite positive integer
(`repetitionId`); alphabetic repetition labels are not supported by this
native metadata contract and are rejected rather than silently renumbered.
A missing selected repetition or signed direction is an error.

Section 3 constructs independent, reviewable `plan.cases` arrays for
RayleighLamb and Plate. The generated condition ID is a stable path label derived from
recorded mechanical keys and exact values (for example,
`Strain_0pct_<8-hex fingerprint>`); it does not depend on acquisition or Pulse-period
ordering. The eight-digit fragment is a condition fingerprint, not a Git commit. The exact recorded condition values remain unchanged in each case. `fit_frequency_selection="all"` requires the user to set
`full_band_reviewed=true`; the selection is never inferred or
optimized. The researcher must review each case, physics, and output paths
before enabling `run_batches=true` in section 4.

The script never implements fitting, OCE I/O schemas, mask selection,
renderers or a second batch engine. Outputs use the separate batch
inversion root and cannot overwrite previous inversions. Discovery reads
actual OCE sources, whereas the underlying `plan.execute=false` preview
checks only structural fields and output paths. The Editor Run Section
path is required for this human workflow.

## Programmable batch workflows

Add `workflows/inversion` to your MATLAB path explicitly for callable functions and initialize
Lamb and OCE as with the interactive drivers. The single programmable batch entry point is `runOceInversionBatch(plan,family)`,
where `family="RayleighLamb"` or `family="Plate"`. This avoids maintaining
two model-only forwarding wrappers; each case is still reviewed and executed
by its own native physical family.

Manual Editor section 4/5 produces a derived `review` variable. It must not
be copied back into `study.review`: that struct contains only editable review
sources and justifications. Re-running the physical review section is safe and
recomputes the effective model branch and thickness policy from the study inputs.

Both call the same `executeOceInversionStudy` as their scientific execution
owner; the Editor scripts use the same preparation, review, fit, save and plot
functions. These are callable MATLAB functions and do not invoke
`matlab.desktop.editor`. One `plan.cases` element represents **one
subexperiment / reviewed mechanical condition / period (Pulse) / signed
direction / model / frequency-selection choice**. Do not combine QH and Pulse
observations or different mechanical states without a separately reviewed
joint-fit contract.

A minimal calling pattern, after building each case from the model-specific
interactive section 1 (no absolute paths inside case definitions):

```matlab
plan = struct();
plan.experimentRoot = experimentRoot;       % Local experiment root supplied by caller
plan.oceRepositoryRoot = oceRepositoryRoot; % Local OCE checkout supplied by caller
% plan.inversionsRoot = "D:/OCE_Inversions"; % Optional absolute external root
plan.cases = [case1, case2];               % Explicit complete reviewed study structs
plan.execute = false;                     % Read-only plan; no MATLAB/OCE input reads
preview = runOceInversionBatch(plan,"RayleighLamb");
disp(preview.report);

% Only after reviewing selections and output destinations:
plan.execute = true;
plan.saveResult = true;
plan.exportFigure = true;
report = runOceInversionBatch(plan,"RayleighLamb");
disp(report.report);
```

For Plate call `runOceInversionBatch(plan,"Plate")` and supply
reviewed density, thickness policy and model-support evidence. The human
experiment-wide batch defaults to `thickness_policy="oce_median_per_case"`:
one median current full thickness across unique acquisitions represented in
the valid fitting mask, per condition/axis/signed direction. It retains all
selected frequency/repetition velocities and their original thickness records.
Both models use this single scalar geometry throughout their one joint fit.
`"oce_directional_per_acquisition"` remains a supported option; programmatic
plans must state their own reviewed policy. `plan.execute=true`
explicitly permits fresh native fits; set `plan.reuseOnly=true` to require
previously saved exact results instead. In reuse-only execution an existing
`inversion.mat` is loaded only after exact native request matching and current
source-hash verification; it is never overwritten. Its archived researcher
scientific review must match the current one before returning its saved record
or exporting any new figure linked to it. Changes to physical assumptions
must use a new reviewed output tag (or an in-memory figure with
`saveResult=false` that does not cite the archived MAT). An existing FIG/TIF remains
protected even when the MAT is reusable: select `plan.exportFigure=false` to
reuse without exporting, or use a new reviewed output tag for new figures.
Historic MAT selection fields are normalized only in the returned in-memory
record; their on-disk bytes and original field names are preserved.
An archived batch MAT retains source-file hashes relative to
`experimentRoot`, while `studyRecord.selection.outputBase="inversionsRoot"`
and `outputRelativeFolder` resolve the destination relative to the
configured external root. `inversion_failure.mat` uses the same output
location and marks its relative native reference with `nativeResultBase`.
No machine-specific output root is written to the MAT.

The default full MATLAB figure export
is hidden during batch execution; it saves FIG and TIF and closes the GUI.
 `plan.continueOnError=true` optionally collects failures rather than stopping
on the first exception. When saving is enabled, a failed attempted case records
`inversion_failure.mat` (reviewed request, error and portable source location)
without overwriting any previous output. A failure before fitting has no
native result. If fitting completes but saving or presentation fails, the
case has status `partial`: its native result and metrics remain in `results`
and the report. The failure record includes `completedThrough` and a relative
reference to any successfully saved inversion MAT. With `continueOnError=false`,
the original exception is still raised after recording the failure.

Each batch case **must** supply `fitFrequencySelection="interval"` with two Hz
bounds, or `"explicit"` with its reviewed original target requests. The
`"all"` mode is allowed only with
`case.fullBandReviewed=true`. These selections are *not* discovered,
optimized or repaired by the batch. Original estimator quality masks and
source-row identities are preserved. A new saved `studyRecord.selection`
also records `fullBandReviewed` when supplied; this acknowledges a human choice,
not automatic scientific validity. Pulse graphic frequency sampling remains
separate from fit eligibility. Fit acceptance is numerical and does not validate
A0 modal purity or eliminate need for bandwidth review. In a dry-run the
batch checks only its destination plan and mandatory selection fields; it does
not attest to OCE data completeness, thickness, solver convergence or valid
bands. Full native and OCE tests are required for scientific execution.

## Ownership

Human drivers coordinate; they do not implement mathematical solvers, OCE schema
I/O, masks, visualization renderers or a second inverse model. Shared source
selection and provenance belong to `prepareOceInversionObservations` and
`oceInversionProvenance` in this directory. OCE owns source validation and
recovery, Lamb fitting owns model-specific inverse physics, and
`visualization/` owns rendering and FIG/TIF export.

See the [OCE fitting and physical review contract](../docs/oce_study_contract.md).
The maintained regression gate covers native numerical equivalence and workflow
structure. Actual MATLAB Editor **Run Section** behavior must also be smoke-tested
interactively; headless synthetic fitting tests do not exercise the Editor.
