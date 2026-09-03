### atlasA0 truncation-cause diagnostic

This diagnostic investigates why the maintained `atlasA0` branch becomes invalid at high frequency in selected acoustoelastic IOP/HGO cases.

The diagnostic is read-only. It does not modify:

- `result.phaseVelocity_mps`
- `result.validMask`
- `options.atlasBranchPolicy`

The official branch policy remains:

`options.atlasBranchPolicy = "atlasA0";`

### Result-location policy

The diagnostic should be launched from the folder where generated outputs should be stored. For example, if MATLAB is currently in `E:\`, outputs are written under short result folders such as:

`E:\Results\ae_iop_hgo\atlas_truncation`

The repository only needs to be available through `startup`.

### Main helper

The causal diagnostic helper is:

`analysis/diagnostics/acoustoelastic_iop_hgo/aeDiagnoseAtlasA0TruncationCause.m`

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

Use the maintained entrypoint:

`diagnose_atlas_truncation`

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

### Validation snapshot after terminal-break correction

The corrected helper distinguishes terminal truncation from internal gaps. Historical numeric checks from the originally uploaded workspace were (not a current-regime guarantee):

| Case | Last official valid [kHz] | First terminal missing [kHz] | First internal gap [kHz] | Has internal gap | Diagnostic accepted points | Diagnostic extension [kHz] |
|---|---:|---:|---:|---:|---:|---:|
| `iop_20mmHg` | 18.4563 | 19.3876 | NaN | false | 7 | 16.5437 |
| `iop_25mmHg` | 15.9224 | 16.7258 | NaN | false | 1 | 0.8034 |
| `mu_25kPa` | 9.2649 | 9.7324 | 8.8199 | true | 0 | 0 |

The maintained conclusion is that truncation must be classified using the
local candidate evidence, not treated automatically as physical mode
disappearance. This diagnostic does not justify replacing `atlasA0`.
