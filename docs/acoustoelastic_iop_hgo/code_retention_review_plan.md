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

LEGACY_ALIAS
  Long descriptive script retained only for backward compatibility.
  Keep only if referenced, recently used, or safer than deletion.

DELETE_CANDIDATE
  Superseded, unreferenced, redundant, or broken script that no longer contributes to tests, documentation, or current analysis.
  Delete only after reference checks and local tests.
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
diagnose_branch_persistence
diagnose_idA0_plausibility
```

Rationale: they document why `atlasA0` is conservative, where it truncates, and why the low-mu/high-IOP corner remains ambiguous.

#### Candidate archive diagnostics

These may no longer need to remain in the maintained entrypoint list if their conclusions are already captured in documentation.

```text
compare_branch_policies
diagnose_branch_policy
diagnose_atlas_resolution
diagnose_idA0_score
validate_idA0_grid
validate_idA0_score_grid
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
track_raw_branch1
diagnose_truncation_cases
diagnose_landscape_failure
```

Rationale: these are more exploratory, expensive, historical, or redundant after the policy closure. They should be reviewed before deletion. Some may still be useful as archived analyses.

### Recommended retention workflow

#### Phase 1: freeze maintained surface

Create a shorter public list:

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

Everything outside this list becomes either `DIAGNOSTIC_ARCHIVE`, `LEGACY_ALIAS`, or `DELETE_CANDIDATE` unless there is a specific reason to keep it maintained.

#### Phase 2: move historical diagnostics out of the maintained entrypoint list

Do not delete first. First update documentation so users are not encouraged to run old diagnostics.

Examples:

```text
compare_branch_policies
validate_idA0_grid
validate_idA0_score_grid
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
track_raw_branch1
```

#### Phase 3: add an archive section

Add a documentation section called:

```text
Historical diagnostics retained for traceability
```

This allows keeping scripts temporarily without treating them as active public API.

#### Phase 4: deletion pass

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

#### Phase 5: test and commit in small batches

For every deletion batch:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
```

If a deleted script had a legacy alias or wrapper relationship, run the relevant maintained entrypoint before deletion.

### Suggested deletion policy

Do not delete in the same commit where a file is first reclassified.

Use two commits:

```text
Commit 1: reclassify as archived or delete candidate in docs.
Commit 2: delete after reference checks and tests.
```

This keeps the history auditable.

### Current recommendation

Do not attempt a complete repository-wide cleanup in one pass.

Recommended next concrete step:

```text
Update docs/maintained_entrypoints.md to distinguish:
  1. maintained public workflows;
  2. maintained diagnostic evidence;
  3. historical diagnostics retained for traceability;
  4. legacy aliases.
```

Then remove historical diagnostics from the primary maintained-entrypoint list before deleting any code.
