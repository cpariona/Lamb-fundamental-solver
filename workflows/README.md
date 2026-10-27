# Human research workflows

`workflows/inversion/` contains the maintained MATLAB Editor drivers for applying
native Lamb inverse models to reviewed OCE acquisitions. This directory is
**opt-in**: ordinary `startup` intentionally does not add workflows to the path.

| Open in MATLAB Editor | Scientific fitting owner |
| --- | --- |
| [run_rl_oce_inversion.m](inversion/run_rl_oce_inversion.m) | Rayleigh–Lamb A0/S0, native nonlinear fitting |
| [run_ae_plate_oce_inversion.m](inversion/run_ae_plate_oce_inversion.m) | Prestressed Plate A0, native linear SVD fitting |

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
6. Fitting is disabled by default (`study.reuseOnly=true`). Only after
   inspecting the request set `study.reuseOnly=false` in the workspace, then
   run the corresponding fit section (RL section 6; Plate section 5).
7. Saving MAT and exporting FIG/TIF are independently disabled by default.
   When enabled, paths are automatically resolved under the experiment root
   (see next section); absolute paths are not accepted as overrides.
   Optional `study.displayLabel` and `study.displaySubtitle` override
   figure text only when nonempty. Otherwise, the workflow builds a label
   from sample/subexperiment/signed direction and leaves native model-specific
   title/subtitle defaults in place. Source material and physical-support
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

## Human experiment-wide inversion batch

Open [run_experiment_inversion_batch.m](inversion/run_experiment_inversion_batch.m)
in **MATLAB Editor** and run its sections in order. Set `experiment_root`,
`oce_repository_root`, `condition_keys` (the exact recorded mechanical
metadata columns), the selected models/directions/repetitions, and the
model-specific reviewed physical inputs in section 1. For uniaxial-stretch
acquisitions `condition_keys="strain_percent"` is an example, not a value
inferred from a folder name.

Use the shared `material` and `geometry` configuration with explicit SI fields:
`density_kgpm3` (kg/m^3), `geometry.thickness_m` (current full m, only a
scalar reference for the directional-OCE thickness policy), and
`poisson_ratio` (dimensionless, RL only). Set the independent
`rl_mu_initial_guess_Pa` and `rl_mu_bounds_Pa`, and provide the model-specific
physical-support references. The public RL fitting boundary maps those
unit-qualified inputs to its retained native mathematical parameter symbols;
Plate accepts the same density/thickness fields directly. Do not assign
placeholder values or infer physical parameters from paths.

Section 2 locates `Results/<subexperiment>/summary.mat` files and uses
`oce.results.recoverSummaryObservations` to validate and discover existing
acquisitions. Recorded frequencies and repetitions are not treated as
mechanical conditions. Original Pulse periods are preserved verbatim.
A missing selected repetition or signed direction is an error.

Section 3 constructs independent, reviewable `plan.cases` arrays for
RayleighLamb and Plate. The generated condition ID is a stable unit-free path label derived from
recorded mechanical keys and literal values (for example,
`strain_percent_0`); it does not depend on acquisition or Pulse-period
ordering. The exact recorded condition values remain unchanged in each case. `frequency_selection="all"` requires the user to set
`approved_all_frequencies=true`; the selection is never inferred or
optimized. The researcher must review each case, physics, and output paths
before enabling `run_batches=true` in section 4.

The script never implements fitting, OCE I/O schemas, mask selection,
renderers or a second batch engine. Outputs follow the existing experiment
path policy and cannot overwrite previous inversions. Discovery reads
actual OCE sources, whereas the underlying `plan.execute=false` preview
checks only structural fields and output paths. The Editor Run Section
path is required for this human workflow.

## Programmable batch workflows

Add `workflows/inversion` to your MATLAB path explicitly and initialize
Lamb and OCE as with the interactive drivers. The single programmable batch entry point is `runOceInversionBatch(plan,family)`,
where `family="RayleighLamb"` or `family="Plate"`. This avoids maintaining
two model-only forwarding wrappers; each case is still reviewed and executed
by its own native physical family.

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
reviewed density, thickness policy and model-support evidence. The default
uses the OCE signed-direction full thickness for each selected observation.
The recorded scalar `physical.thickness_m` is a non-operative reference
under this policy; constant-thickness studies remain available explicitly. `plan.execute=true`
explicitly permits fresh native fits; set `plan.reuseOnly=true` to require
previously saved exact results instead. The default full MATLAB figure export
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
source-row identities are preserved. Pulse graphic frequency sampling remains
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
