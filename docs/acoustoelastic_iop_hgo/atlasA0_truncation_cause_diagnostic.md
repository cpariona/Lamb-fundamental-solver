### atlasA0 truncation-cause diagnostic

This diagnostic investigates why the maintained `atlasA0` branch becomes invalid at high frequency in selected acoustoelastic IOP/HGO cases.

The diagnostic is read-only. It does not modify:

- `result.Cp`
- `result.validCp`
- `options.atlasBranchPolicy`

The official branch policy remains:

`options.atlasBranchPolicy = "atlasA0";`

### Result-location policy

The diagnostic should be launched from the folder where generated outputs should be stored. For example, if MATLAB is currently in `E:\`, outputs are written under:

`E:\Results\acoustoelastic_iop_hgo_atlasA0_truncation_cause`

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

### Runnable diagnostic script

Run:

`diagnose_acoustoelastic_iop_hgo_atlasA0_truncation_cause`

The script loads the maintained IOP and shear-modulus sweep workspaces from the launch-folder `Results` tree and analyzes:

- `iop_20mmHg`
- `iop_25mmHg`
- `mu_25kPa`

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

The dominant case label is selected from the missing-frequency rows in the local diagnostic window.

### Output files

The script writes:

- per-case truncation-cause summary CSV files;
- per-case local-cause tables;
- per-case atlas-resolution sensitivity plans;
- a combined summary table;
- a workspace MAT file;
- local landscape plots under the `plots` subfolder.

### Atlas-resolution sensitivity plan

The first implementation records the rerun plan rather than executing all sensitivity cases automatically. The plan covers:

`options.atlasNumYPoints = [1000 1500 2000 3000];`

`options.atlasTopNMinima = [18 24 32];`

This avoids expensive automatic sweeps during the first causal diagnostic pass. A later issue can turn the plan into a full batch rerun once the causal table is validated.

### Expected interpretation from issue #48

Starting expectations are:

| Case | Expected causal pattern |
|---|---|
| `iop_20mmHg` | Long diagnostic continuation exists, but it uses lower-rank minima; likely branch competition rather than simple absence of minima. |
| `iop_25mmHg` | Only one accepted continuation point; likely weak partial continuation. |
| `mu_25kPa` | No accepted continuation; likely not solved by threshold relaxation or branch persistence. |

These interpretations remain diagnostic. They do not justify replacing `atlasA0`.
