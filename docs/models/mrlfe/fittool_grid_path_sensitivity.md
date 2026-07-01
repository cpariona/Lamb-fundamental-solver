# mRLFE FitTool grid/path sensitivity

During FitTool UI review, mRLFE fitting was internally consistent at the experimental frequencies: re-evaluating the fitted parameters on the same frequency grid reproduced the saved fitted values.

A separate dense solver re-evaluation on a different plotting grid can deviate from those fit-consistent values. One observed case near 1.78 kHz showed a dense-minus-fit difference of about 0.14 m/s.

This indicates grid/path sensitivity in the mRLFE atlas branch tracking, especially near low frequency for the A0-like zero-viscosity adaptive route. It is not, by itself, a FitTool fitting error.

Current FitTool policy:

- The primary plotted fit curve remains fit-consistent.
- Dense solver re-evaluation is stored as diagnostic metadata.
- The status line reports a dense/grid mismatch when the diagnostic difference exceeds the configured threshold.

Relevant diagnostic fields:

- `normalized.fullCurve.denseSolver.maxAbsDenseMinusFit_mps`
- `normalized.fullCurve.denseSolver.hasGridMismatch`
- `normalized.fullCurve.denseSolver.warningMessage`

Follow-up work:

- Audit mRLFE atlas tracking for grid/path dependence.
- Add focused sparse-grid versus dense-grid diagnostics.
- Decide whether dense curves should be anchored to experimental frequencies.
- Consolidate obsolete mRLFE tests and docs after the FitTool route stabilizes.
