# FitTool interaction manual validation

Use this checklist after FitTool UI interaction changes. It complements the
automated runners and should be filled by a human tester.

| Step | Expected result | Status | Notes |
|---|---|---|---|
| 1. Load a `.txt` file. | Data table fills with `Frequency [Hz]`, `Phase speed [m/s]`, and `Use`; provenance is visible. | Not tested |  |
| 2. Load a `.mat` file. | Column/source selection works and `FitToolLastOutput.experimentalDataMetadata` preserves MAT source metadata after fitting. | Not tested |  |
| 3. Add row. | A new editable `[NaN, NaN, 1]` row appears. | Not tested |  |
| 4. Edit row. | Plot refreshes when possible and metadata marks `wasManuallyEdited = true`. | Not tested |  |
| 5. Delete row. | Selected rows are removed; empty selection does not error. | Not tested |  |
| 6. Apply manual axes. | Plot uses the requested X/Y limits. | Not tested |  |
| 7. Run fit. | Fit completes with existing optimizer/settings; manual axes persist. | Not tested |  |
| 8. Review parameter table. | Only the fitted parameter is visible; fixed rows are not repeated. | Not tested |  |
| 9. Review quality table. | A vertical `Metric | Value` table shows RMSE, MAE, R2, baseline comparison, warning, and identifiability once; unavailable AIC/BIC are hidden. | Not tested |  |
| 10. Evaluate fitted curve. | A solver-evaluated requested curve is added without rerunning the optimizer. | Not tested |  |
| 11. Inspect requested curve output. | `FitToolLastOutput.requestedCurve` contains frequency, Cp, valid mask, elapsed time, model, branch, execution profile, and route metadata. | Not tested |  |
| 12. Change model. | Controls update; axis view state remains visual-only and does not change solver request fields. | Not tested |  |
| 13. Restore defaults. | Physical/default controls restore according to model; axis controls are unaffected unless Auto axes is pressed. | Not tested |  |
| 14. Confirm provenance. | `experimentalDataMetadata` preserves original source and records manual edits. | Not tested |  |
| 15. Confirm readable plot text. | The title and legend use readable model, branch, and curve names rather than internal identifiers. | Not tested |  |
