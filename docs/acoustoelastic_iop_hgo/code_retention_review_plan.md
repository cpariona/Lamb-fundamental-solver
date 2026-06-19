### Acoustoelastic IOP/HGO code retention review plan

This document defines a conservative strategy for deciding which acoustoelastic IOP/HGO scripts should remain actively maintained, which should be archived as historical research evidence, and which may eventually be deleted.

### Motivation

The acoustoelastic IOP/HGO module now contains several layers of code created during solver development:

```text
stable solver/API code;
maintained examples and sweeps;
regression tests;
exploratory diagnostics;
legacy descriptive scripts;
historical validation scripts;
documentation snapshots.
```

Many diagnostics were necessary while selecting and validating the `atlasA0` policy, checking the `identityA0Diagnostic` branch, comparing raw branch candidates, and diagnosing low-stiffness/high-IOP ambiguity.

Now that the conservative production policy is established, not every diagnostic needs to remain a maintained user-facing entrypoint.

### Principle

Do not keep code only because it was once useful.

Do not delete code only because it is long, old, or diagnostic.

Classify each file by current role.

### Retention categories

Use the following categories.

```text
CORE_API
  Stable solver/model/helper code used by examples, GUI, future solvers, or tests.
  Keep.

PUBLIC_EXAMPLE
  Short executable example for normal user workflows.
  Keep.

PUBLIC_SWEEP
  Short executable sweep used for current analysis or thesis workflows.
  Keep.

REGRESSION_TEST
  Automated test that protects solver behavior, API behavior, or known bug fixes.
  Keep unless it is redundant and covered by a better test.

DIAGNOSTIC_MAINTAINED
  Diagnostic still useful for current solver interpretation or thesis analysis.
  Keep, but document expected use.

DIAGNOSTIC_ARCHIVE
  Diagnostic that already answered a historical question and is no longer part of routine work.
  Move out of the maintained entrypoint list. Keep temporarily for traceability.

KEEP_FOR_THESIS_ANALYSIS
  Diagnostic is not a routine workflow but may still support interpretation, figures, or thesis discussion.
  Keep outside the primary maintained list.

KEEP_AS_COMPATIBILITY
  Short or long script exists mainly to avoid breaking older commands.
  Keep until references are checked and the command is no longer needed.

DELETE_CANDIDATE_AFTER_GREP
  Superseded, unreferenced, redundant, or broken script that no longer contributes to tests, documentation, or current analysis.
  Delete only after reference checks and local tests.

DELETED_AFTER_TESTS
  Archived diagnostic removed after the maintained test layer was reduced and local tests passed.
```

### Initial high-level classification

#### Keep as core maintained layer

```text
models/acoustoelastic_iop_hgo/**
analysis/acoustoelastic_iop_hgo/aeOutputFolder.m
analysis/acoustoelastic_iop_hgo/aeResolveResultFile.m
analysis/acoustoelastic_iop_hgo/aeRunSweep.m
analysis/acoustoelastic_iop_hgo/aeSummarizeSweep.m
analysis/acoustoelastic_iop_hgo/aeClassifyAmbiguityRegime.m
analysis/acoustoelastic_iop_hgo/aeScoreBranchIdentityCandidates.m
analysis/acoustoelastic_iop_hgo/aeBuildIdentityA0DiagnosticBranch.m
analysis/acoustoelastic_iop_hgo/aeDiagnoseAtlasA0TruncationCause.m
analysis/acoustoelastic_iop_hgo/aeAnalyzeBranchPersistenceCandidates.m
analysis/acoustoelastic_iop_hgo/aeRefineAtlasA0BranchPersistence.m
```

Rationale: these are implementation or reusable analysis helpers. They support current short entrypoints, tests, or documented solver behavior.

#### Keep as public workflows

```text
examples/acoustoelastic_iop_hgo/basic/run_atlas_branch.m
examples/acoustoelastic_iop_hgo/sweeps/sweep_iop.m
examples/acoustoelastic_iop_hgo/sweeps/sweep_mu.m
```

Rationale: these are current user-facing workflows.

#### Keep as regression tests

```text
tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_branch_policy_aliases.m
tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_constitutive_identity.m
tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_strictA0_smoke.m
tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy.m
tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_short_entrypoints.m
tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_branch_persistence_refinement.m
```

Rationale: current test count is not excessive. These protect API behavior, policy aliases, diagnostic non-mutation of official outputs, and known wrapper issues.

#### Candidate maintained diagnostics

These diagnostics remain useful for explaining current solver behavior or the final ambiguity boundary.

```text
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
```

Rationale: they document why `atlasA0` is conservative, where it truncates, and why the low-mu/high-IOP corner remains ambiguous.

### Historical diagnostic retention matrix

This is the explicit classification pass for short historical diagnostics that were moved out of the primary maintained-entrypoint list.

| Entrypoint | Classification | Rationale | Action |
|---|---|---|---|
| `compare_branch_policies` | `DIAGNOSTIC_ARCHIVE` | Useful during branch-policy selection; current policy is now `atlasA0`. | Keep as historical evidence for now; not a routine workflow. |
| `diagnose_branch_policy` | `KEEP_AS_COMPATIBILITY` | Thin compatibility command around branch-policy comparison history. | Keep until branch-policy historical scripts are reviewed together. |
| `diagnose_atlas_resolution` | `DIAGNOSTIC_ARCHIVE` | Resolution sensitivity already informed atlas settings; expensive to run. | Keep as archive; delete only after documentation captures necessary conclusions. |
| `diagnose_idA0_score` | `KEEP_FOR_THESIS_ANALYSIS` | May still help explain identity-score behavior and why diagnostic branches are not official outputs. | Keep outside primary maintained list. |
| `validate_idA0_grid` | `KEEP_FOR_THESIS_ANALYSIS` | Heavy grid validation; supports documentation that `identityA0Diagnostic` preserves official outputs. | Keep, but not as a routine workflow. |
| `validate_idA0_score_grid` | `KEEP_FOR_THESIS_ANALYSIS` | Heavy score-grid validation; may support methodological discussion. | Keep, but not as a routine workflow. |
| `diagnose_modal_atlas` | `KEEP_FOR_THESIS_ANALYSIS` | Useful visual/diagnostic evidence for modal-family ambiguity; now writes to short output path. | Keep for thesis-level interpretation; not routine. |
| `diagnose_modal_atlas_lowfreq` | `KEEP_FOR_THESIS_ANALYSIS` | Useful for low-frequency modal-family interpretation; now writes to short output path. | Keep for thesis-level interpretation; not routine. |
| `track_raw_branch1` | `DIAGNOSTIC_ARCHIVE` | Raw branch1 was useful for comparison but is not official output. | Keep until raw-branch historical docs are consolidated. |
| `diagnose_truncation_cases` | `DELETED_AFTER_TESTS` | Superseded by `diagnose_atlas_truncation` and retained documentation. | Removed with legacy implementation. |
| `diagnose_landscape_failure` | `DELETED_AFTER_TESTS` | Superseded by `diagnose_atlas_truncation` and retained failure-landscape documentation. | Removed with legacy implementation. |
| `diagnose_branch_persistence` | `DIAGNOSTIC_ARCHIVE` | Branch-persistence ideas contributed to truncation interpretation; may be redundant now. | Keep temporarily; candidate for archive/deletion review with truncation diagnostics. |

### First deletion batch

The first deletion batch removed:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_truncation_cases.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_truncation_cases.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_landscape_failure.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_failure_landscape.m
```

Replacement or retained evidence:

```text
diagnose_atlas_truncation
docs/acoustoelastic_iop_hgo/atlasA0_truncation_validation.md
docs/acoustoelastic_iop_hgo/atlasA0_truncation_cause_diagnostic.md
```

### Test-reference cleanup status

`tests/run_all_smoke_tests.m` was reduced to the primary maintained API, workflows, diagnostic evidence, and tests. It no longer protects historical diagnostics or legacy aliases.

`tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_short_entrypoints.m` separates:

```text
maintainedNames
historicalNames
```

Historical names are validated only if they are still present. This preserves wrapper-target checks while allowing future deletion of archived diagnostics.

### Recommended retention workflow

#### Phase 1: freeze maintained surface

The primary maintained acoustoelastic surface is:

```text
run_atlas_branch
sweep_iop
sweep_mu
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
```

Everything outside this list is either `DIAGNOSTIC_ARCHIVE`, `KEEP_FOR_THESIS_ANALYSIS`, `KEEP_AS_COMPATIBILITY`, `DELETED_AFTER_TESTS`, or `DELETE_CANDIDATE_AFTER_GREP` unless there is a specific reason to keep it maintained.

#### Phase 2: keep historical diagnostics out of the primary maintained-entrypoint list

Do not delete first. First update documentation so users are not encouraged to run old diagnostics routinely.

Examples:

```text
compare_branch_policies
validate_idA0_grid
validate_idA0_score_grid
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
track_raw_branch1
```

#### Phase 3: deletion pass

Only after a script is moved out of maintained status:

```bash
git grep "<script_basename>"
git grep "<script_filename>"
```

If only documentation references remain, choose either:

```text
archive in docs and delete code;
or keep code as historical diagnostic with no maintained guarantee.
```

#### Phase 4: test and commit in small batches

For every deletion batch:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

If a deleted script had a legacy alias or wrapper relationship, run the relevant maintained entrypoint before deletion.

### Suggested deletion policy

Use small batches and keep the history auditable.

### Current recommendation

The first archived diagnostic deletion batch has been applied.

Recommended next concrete step:

```text
Run test_acoustoelastic_iop_hgo_short_entrypoints and run_all_smoke_tests locally.
Then review remaining DIAGNOSTIC_ARCHIVE entries before deleting more code.
```
