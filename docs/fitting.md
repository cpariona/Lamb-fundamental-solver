# Dispersion fitting

`src/+lamb/+fitting/` owns inverse dispersion fitting. Each family follows:

```text
family fit API -> fit-problem construction -> shared optimization primitives
               -> family evaluator -> canonical forward model API
```

Fitting preserves residual definitions, weights, masks, free/fixed parameter
semantics, bounds, optimizer controls, stopping criteria, quality thresholds,
and family forward routes. It never duplicates equations or tracking.

FitTool accepts `.csv`, `.txt`, `.dat`, and `.mat` experimental data. Text files
expose only numeric or logical columns for selection. A MAT file may contain a
table, a numeric or logical matrix with at least two columns, or a scalar struct
with at least two compatible numeric or logical vectors.

The import adapter converts frequency to Hz and phase speed to m/s, removes
non-finite or non-positive rows, requires at least two valid rows, sorts by
ascending frequency, and collapses duplicate frequencies by their mean unless a
different supported policy is explicitly selected. Logical `Use` values within
a duplicate group are combined with `any`, and the normalized `validMask`
preserves the resulting `Use` selection. The canonical input fields are
`frequency_Hz`, `Cp_mps`, and `validMask`; `standardError_Cp_mps` is optional
and weighting is disabled unless explicitly requested.

Import provenance records file path and name, the MAT variable when applicable,
selected columns and names, source units, duplicate policy, and counts for
removed rows, collapsed duplicate rows, and output rows. Editing imported data
sets `wasManuallyEdited = true` while retaining the original provenance.

The editable table uses frequency in Hz, phase speed in m/s, and a `Use` column.
Axis limits are presentation state and never enter the fit request. Manual
limits persist until Auto is selected; Auto leaves the corresponding fields
blank, and zero is a valid explicit bound rather than a sentinel. File parsing
and normalization belong to `app/fitting/guiReadExperimentalFitFile.m` and
`app/fitting/guiPrepareExperimentalFitData.m`; `FitTool_GUI` owns interaction
and orchestration only.

Family parameterization, solver route, and limitations are documented in each
model's `fitting.md` file.

## Request and result contracts

A fit request carries `modelFamily`, `branchName`, `experimental`,
`fixedParams`, `freeParams`, `initialGuess`, `bounds`, `controls`, and
`options`. The result carries `bestParams`, fixed parameters, experimental and
fitted curves, residuals, valid mask, metrics, identifiability, optimizer
evidence, and the final model evaluation. The normalized GUI view may add full
and requested curves, route policy, quality, and summary tables.

The displayed full curve is an objective-consistent interpolation, not an
implicit dense solver call. A new forward solve occurs only when the user asks
to evaluate the fitted curve. Fixed parameters remain in metadata while the
visible summary emphasizes the fitted parameter.

## Family routes

- Rayleigh-Lamb fitting uses the canonical tracking owner also used by the
  public solver. Its experimental-frequency continuation grid intentionally
  does not route through the batch public API because that would change fitting
  semantics.
- mRLFE fitting routes through
  `lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest` and
  `lamb.models.mrlfe.mrlfeSolve`. Objective grids preserve experimental points
  and add bounded continuation points; explicitly requested curves use the
  selected numerical preset. A0Like uses `physicalTail`, S0Like uses `none`,
  and fallback remains disabled.
- AE fitting routes through
  `lamb.models.acoustoelastic_iop_hgo.aeSolveBranch`; atlas
  construction and branch selection remain model-owned.

Shared fitting primitives own residual calculation, fit metrics,
constant-speed comparison, physical-quality assessment, local sensitivity,
identifiability, and optimizer orchestration. Model builders own family bounds,
parameterization, and evaluator configuration. No fitting owner depends on
sweep defaults or sweep orchestration.

Maintained validation covers exact and perturbed single-parameter recovery,
fixed/hidden parameter handling, objective valid masks, and app routes. It does
not claim broad viscosity identifiability, general multiparameter recovery,
experimental accuracy, covariance estimation, or validated standard-error
weighting across all regimes.
