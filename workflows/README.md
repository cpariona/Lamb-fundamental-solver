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
   **Do not treat numeric acceptance as experimental model validation.**
6. Fitting is disabled by default (`study.reuseOnly=true`). Only after
   inspecting the request set `study.reuseOnly=false` in the workspace, then
   run the corresponding fit section (RL section 6; Plate section 5).
7. Saving MAT and exporting FIG/TIF are independently disabled by default;
   select new output paths explicitly before running persistence sections.
   Optional `study.displayLabel` overrides the figure title; when empty, the
   drivers build a label from the already-reviewed sample, subexperiment,
   scan axis and signed direction. Source material and physical-support
   references remain mandatory, and the visualization layer keeps its strict
   provenance validation.

A failed or edited upstream section invalidates downstream workspace values.
Re-run dependent sections, not only the last fitting or export step.

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
