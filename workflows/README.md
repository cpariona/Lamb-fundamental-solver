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
   Optional `study.displayLabel` overrides the figure title; when empty, the
   drivers build a label from the already-reviewed sample, subexperiment,
   scan axis and signed direction. Source material and physical-support
   references remain mandatory, and the visualization layer keeps its strict
   provenance validation.

A failed or edited upstream section invalidates downstream workspace values.
Re-run dependent sections, not only the last fitting or export step.


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

## Programmable batch workflows

Add `workflows/inversion` to your MATLAB path explicitly and initialize
Lamb and OCE as with the interactive drivers. Entry points:

- `run_rl_oce_inversion_batch(plan)`
- `run_ae_plate_oce_inversion_batch(plan)`

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
preview = run_rl_oce_inversion_batch(plan);
disp(preview.report);

% Only after reviewing selections and output destinations:
plan.execute = true;
plan.saveResult = true;
plan.exportFigure = true;
report = run_rl_oce_inversion_batch(plan);
disp(report.report);
```

For Plate call `run_ae_plate_oce_inversion_batch(plan)` and supply
reviewed density, thickness policy and model-support evidence. The default
uses the OCE signed-direction full thickness for each selected observation.
The recorded scalar `physical.thickness_m` is a non-operative reference
under this policy; constant-thickness studies remain available explicitly. `plan.execute=true`
explicitly permits fresh native fits; set `plan.reuseOnly=true` to require
previously saved exact results instead. The default full MATLAB figure export
is hidden during batch execution; it saves FIG and TIF and closes the GUI.
`plan.continueOnError=true` optionally collects failures rather than stopping
on the first exception.

Each batch case **must** supply `frequencySelection="interval"` with two Hz
bounds, or `"explicit"` with its reviewed original target requests. The
`"all"` mode is allowed only with
`case.approvedAllFrequencies=true`. These selections are *not* discovered,
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
