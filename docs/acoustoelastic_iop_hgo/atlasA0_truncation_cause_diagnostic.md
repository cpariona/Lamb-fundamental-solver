### atlasA0 truncation-cause diagnostic

This diagnostic investigates why the maintained `atlasA0` branch becomes invalid at high frequency in selected acoustoelastic IOP/HGO cases.

The diagnostic is read-only. It does not modify:

- `result.Cp`
- `result.validCp`
- `options.atlasBranchPolicy`

The official branch policy remains:

`options.atlasBranchPolicy = "atlasA0";`

### Result-location policy

The diagnostic should be launched from the folder where generated outputs should be stored. For example, if MATLAB is currently in `E:\`, outputs are written under short result folders such as:

`E:\Results\ae_iop_hgo\atlas_truncation`

The repository only needs to be available through `startup`.

### Main helper

The causal diagnostic helper is:

`analysis/acoustoelastic_iop_hgo/aeDiagnoseAtlasA0TruncationCause.m`

It returns:

- `diagnosis.summary`
- `diagnosis.localCauseTable`
- `diagnosis.persistence`
- `diagnosis.recovery`
- `diagnosis.atlasResolutionPlan`

### Terminal truncation versus internal gaps

The diagnostic separates two different failure patterns:

- `FirstInternalGap*`: first missing point between the first and last official valid points;
- `FirstTerminalMissing*`: first missing point after the last official valid point.

The dominant causal diagnosis is centered on `FirstTerminalMissing*`, because the target is high-frequency truncation rather than isolated internal gaps.

This distinction matters for `mu_25kPa`, where an internal gap appears before the last official valid point. The corrected diagnostic reports that internal gap separately and then analyzes the terminal break after the last official valid frequency.

### Runnable causal diagnostic script

Use the short entrypoint:

`diagnose_atlas_truncation`

Legacy descriptive implementation:

`diagnose_acoustoelastic_iop_hgo_atlasA0_truncation_cause`

The script loads the maintained IOP and shear-modulus sweep workspaces from the launch-folder `Results` tree. It checks short sweep paths first and then legacy sweep paths.

It analyzes:

- `iop_20mmHg`
- `iop_25mmHg`
- `mu_25kPa`

Preferred output folder:

`Results/ae_iop_hgo/atlas_truncation`

### Local cause labels

The helper classifies local truncation behavior with labels such as:

- `official_valid`
- `no_minimum_available`
- `nearest_minimum_too_far`
- `candidate_low_rank`
- `accepted_diagnostic_candidate`
- `crowded_minima_landscape`
- `objective_not_distinct`
- `branch_id_discontinuity`
- `unclassified_tracker_rejection`

The dominant case label is selected from the missing-frequency rows in the local diagnostic window around the terminal break.

### Output files for causal diagnostic

The short-path script writes:

- per-case summary CSV files: `<case>_summary.csv`
- per-case local-cause tables: `<case>_local_cause.csv`
- per-case atlas-resolution plans: `<case>_resolution_plan.csv`
- combined summary table: `atlas_truncation_summary.csv`
- workspace: `atlas_truncation_workspace.mat`
- local landscape plots under the `plots` subfolder.

### Atlas-resolution sensitivity batch

A second diagnostic script reruns the three target cases with controlled atlas settings.

Use the short entrypoint:

`diagnose_atlas_resolution`

Legacy descriptive implementation:

`diagnose_acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity`

It writes outputs under:

`Results/ae_iop_hgo/atlas_resolution`

The batch evaluates:

`options.atlasNumYPoints = [1000 1500 2000 3000];`

`options.atlasTopNMinima = [18 24 32];`

for each of:

- `iop_20mmHg`
- `iop_25mmHg`
- `mu_25kPa`

The output table reports, per case and atlas setting:

- valid points and valid fraction;
- last official valid frequency;
- first terminal missing frequency;
- first internal gap frequency;
- diagnostic accepted points;
- diagnostic extension;
- median accepted diagnostic rank;
- dominant cause label;
- y-boundary status;
- start-filter and fallback flags.

This batch is still diagnostic only. It does not change the official solver output.

### Focused failure-landscape diagnostic

Use the short entrypoint:

`diagnose_landscape_failure`

Legacy descriptive implementation:

`diagnose_acoustoelastic_iop_hgo_failure_landscape`

It inspects the objective landscape around the terminal failure of:

- `iop_25mmHg`
- `mu_25kPa`

The script scans `y = Cp / sqrt(alpha/rho)` and computes local minima of `objectiveAcoustoelasticResidual`. The diagnostic reports the deepest minimum, the minimum nearest to the previous valid Cp, nearest-minimum rank, relative distance to the previous Cp, objective ratio, and local crowding.

Outputs are written under:

`Results/ae_iop_hgo/landscape_failure`

### Validation snapshot after terminal-break correction

The corrected helper distinguishes terminal truncation from internal gaps. Current numeric checks from the uploaded workspace are:

| Case | Last official valid [kHz] | First terminal missing [kHz] | First internal gap [kHz] | Has internal gap | Diagnostic accepted points | Diagnostic extension [kHz] |
|---|---:|---:|---:|---:|---:|---:|
| `iop_20mmHg` | 18.4563 | 19.3876 | NaN | false | 7 | 16.5437 |
| `iop_25mmHg` | 15.9224 | 16.7258 | NaN | false | 1 | 0.8034 |
| `mu_25kPa` | 9.2649 | 9.7324 | 8.8199 | true | 0 | 0 |

### Atlas-resolution sensitivity validation

The resolution-sensitivity batch shows that truncation is not controlled by a single monotonic resolution parameter.

| Case | Best setting by valid points | Best valid points | Best last valid [kHz] | Baseline `1000/18` valid points | Main sensitivity observation |
|---|---|---:|---:|---:|---|
| `iop_20mmHg` | `atlasNumYPoints=1000`, `atlasTopNMinima=32` | 120 | 35.0000 | 107 | Increasing `atlasTopNMinima` can fully remove terminal truncation, but the response is non-monotonic with `atlasNumYPoints`. |
| `iop_25mmHg` | `atlasNumYPoints=3000`, `atlasTopNMinima=24` | 112 | 30.1948 | 104 | Higher resolution improves coverage, but no tested setting reaches full 35 kHz coverage. |
| `mu_25kPa` | `atlasNumYPoints=1500`, `atlasTopNMinima=32` | 95 | 10.2235 | 92 | The branch remains strongly truncated under all tested atlas settings. |

Dominant cause labels across the batch:

| Case | Dominant labels observed | Interpretation |
|---|---|---|
| `iop_20mmHg` | `nearest_minimum_too_far`, `candidate_low_rank`, `crowded_minima_landscape`, `no_truncation` | The branch can be recovered by storing more minima, but branch identity remains sensitive. This points to branch competition/tracker selection rather than a pure lack of atlas resolution. |
| `iop_25mmHg` | mostly `nearest_minimum_too_far`, with some `candidate_low_rank` and `crowded_minima_landscape` | The branch improves but remains incomplete; continuity thresholds and branch competition both matter. |
| `mu_25kPa` | mostly `nearest_minimum_too_far`; one `candidate_low_rank`, one `crowded_minima_landscape`, one `unclassified_tracker_rejection` | This case is not solved by atlas resolution or top-N minima alone; it likely needs deeper inspection of the objective landscape or model regime. |

Current conclusion: `iop_20mmHg` is sensitive to how many local minima are retained, `iop_25mmHg` is partially resolution-sensitive, and `mu_25kPa` is not meaningfully fixed by the tested atlas settings.

### Focused failure-landscape validation

The focused landscape workspace shows that the continuation neighborhood is not empty. Instead, the objective landscape contains many competing minima near the previous valid Cp.

| Case | Last official valid [kHz] | First terminal missing [kHz] | Inspected frequencies | Missing inspected frequencies | Median nearest relative distance | Median nearest rank | Max crowding within 5% Cp | Top minima rows |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `iop_25mmHg` | 15.9224 | 16.7258 | 7 | 5 | 0.000783 | 35.0 | 26 | 84 |
| `mu_25kPa` | 9.2649 | 9.7324 | 7 | 6 | 0.001033 | 25.5 | 24 | 84 |

Interpretation:

- The nearest continuation minimum is extremely close in phase velocity to the previous valid Cp for both cases.
- However, that nearest minimum is low-rank in the landscape: median rank is about 35 for `iop_25mmHg` and 25.5 for `mu_25kPa`.
- The local region is strongly crowded: 24-26 minima lie within 5% of the previous valid Cp.
- Therefore, the main failure is not lack of a nearby local minimum. It is branch identity ambiguity in a highly crowded objective landscape.

### Expected interpretation from issue #48

Starting expectations are:

| Case | Expected causal pattern |
|---|---|
| `iop_20mmHg` | Long diagnostic continuation exists, but it uses lower-rank minima; likely branch competition rather than simple absence of minima. |
| `iop_25mmHg` | Only one accepted continuation point; likely weak partial continuation. |
| `mu_25kPa` | No accepted continuation; likely not solved by threshold relaxation or branch persistence. |

These interpretations remain diagnostic. They do not justify replacing `atlasA0`.
