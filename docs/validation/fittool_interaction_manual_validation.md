# FitTool interaction manual validation

Use this reusable checklist after FitTool UI interaction changes. It complements
the automated runners and should be completed by a human tester. This file is a
template, not a persistent record of the latest validation run; completed results
belong in the pull-request description or other task history.

Use `PASS`, `FAIL`, or `N/A` in the Status column while performing a review.

| Step | Expected result | Status | Notes |
|---|---|---|---|
| 1. Load a `.txt` file. | Data table fills with `Frequency [Hz]`, `Phase speed [m/s]`, and `Use`; provenance is visible. |  |  |
| 2. Load a `.mat` file. | Column/source selection works and `FitToolLastOutput.experimentalDataMetadata` preserves MAT source metadata after fitting. |  |  |
| 3. Add row. | A new editable `[NaN, NaN, 1]` row appears. |  |  |
| 4. Edit row. | Plot refreshes when possible and metadata marks `wasManuallyEdited = true`. |  |  |
| 5. Delete row. | Selected rows are removed; empty selection does not error. |  |  |
| 6. Apply manual axes. | Plot uses the requested X/Y limits. |  |  |
| 7. Run fit. | Fit completes with existing optimizer/settings; manual axes persist. |  |  |
| 8. Review parameter table. | Only the fitted parameter is visible; fixed rows are not repeated. |  |  |
| 9. Review quality table. | A vertical `Metric | Value` table shows RMSE, MAE, R2, baseline comparison, warning, and identifiability once; unavailable AIC/BIC are hidden. |  |  |
| 10. Evaluate fitted curve. | A solver-evaluated requested curve is added without rerunning the optimizer. |  |  |
| 11. Inspect requested curve output. | `FitToolLastOutput.requestedCurve` contains frequency, Cp, valid mask, elapsed time, model, branch, execution profile, and route metadata. |  |  |
| 12. Change model. | Controls update; axis view state remains visual-only and does not change solver request fields. |  |  |
| 13. Restore defaults. | Physical/default controls restore according to model; axis controls are unaffected unless Auto axes is pressed. |  |  |
| 14. Confirm provenance. | `experimentalDataMetadata` preserves original source and records manual edits. |  |  |
| 15. Confirm readable plot text. | The title and legend use readable model, branch, and curve names rather than internal identifiers. |  |  |
