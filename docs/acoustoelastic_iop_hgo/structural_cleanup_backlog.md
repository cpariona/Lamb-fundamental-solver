### Structural cleanup backlog

This document records remaining cleanup work after the targeted identity-A0 plausibility renaming pass and later archived-diagnostic cleanup passes.

### Summary

The critical MATLAB filename issue is resolved, but the repository still contains cleanup candidates.

The latest operational cleanup audit is recorded in:

```text
docs/acoustoelastic_iop_hgo/structural_audit_refresh.md
```

Older audit counters were:

```text
Over63Chars = 0
Over45Chars = 22
IsLegacyLongName = 26
WritesLegacyResults = 35
WritesShortResults = 11
UsesAeOutputFolder = 11
UsesAeResolveResultFile = 7
MutatesOfficialCp = 5
```

Those values are stale after archived-diagnostic deletions and the modal-atlas output-path migrations. Use `structural_audit_refresh.md` for current cleanup decisions.

### Interpretation

`Over63Chars = 0` means there is no remaining known `namelengthmax` blocker.

The other flags do not automatically mean errors. They identify files that need classification.

### Cleanup categories

Use these categories for each flagged script.

```text
KEEP
WRAP_ONLY
CONSOLIDATE
DELETE_AFTER_REFERENCE_CHECK
MIGRATE_OUTPUT_PATH
REVIEW_MUTATION_FLAG
FALSE_POSITIVE_TEST_FIXTURE
KEEP_OFFICIAL_ASSIGNMENT
KEEP_SOLVER_ASSIGNMENT
KEEP_DIAGNOSTIC_SOLVER_VALIDCP
DIRECT_MAINTAINED_ENTRYPOINT
LEGACY_ALIAS_TO_SHORT
DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION
DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION_WITH_LAUNCH_FOLDER_PRESERVATION
COMPATIBILITY_ALIAS_CANDIDATE
RETAIN_FOR_COMPARISON_REPRODUCIBILITY
ARCHIVED_REMOVED
```

### Priority 1: output path cleanup

Many scripts matched `WritesLegacyResults` in the old audit.

Current triage from the refreshed audit:

```text
true legacy output writes requiring immediate migration
  none identified in maintained modal-atlas paths after cleanup

compatibility fallback reads
  track_acoustoelastic_iop_hgo_raw_branch1_candidate.m

documentation or migration notes
  remaining Results/acoustoelastic_iop_hgo... references in docs

tests or compatibility behavior
  keep until candidate-specific review
```

Do not change official numerical outputs while doing this cleanup.

Completed output-path cleanup actions:

```text
examples/acoustoelastic_iop_hgo/basic/run_atlas_branch.m
  DIRECT_MAINTAINED_ENTRYPOINT
  Now calls solveAcoustoelasticIOPHGOAtlasBranch directly and writes under Results/ae_iop_hgo/atlas_branch.

examples/acoustoelastic_iop_hgo/basic/run_acoustoelastic_iop_hgo_atlas_branch.m
  LEGACY_ALIAS_TO_SHORT
  Now delegates to run_atlas_branch for compatibility.

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
  DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION_WITH_LAUNCH_FOLDER_PRESERVATION
  Now delegates directly to diagnose_acoustoelastic_iop_hgo_modal_atlas without temporary patching.

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  MIGRATE_OUTPUT_PATH
  Now writes to Results/ae_iop_hgo/modal_atlas through aeOutputFolder.

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
  DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION_WITH_LAUNCH_FOLDER_PRESERVATION
  Now delegates directly to diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas without temporary patching.

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
  MIGRATE_OUTPUT_PATH
  Now writes to Results/ae_iop_hgo/modal_atlas_lowfreq through aeOutputFolder.
```

### Priority 2: mutation flag review completed

The old audit reported `MutatesOfficialCp = 5`.

These files were reviewed in:

```text
docs/acoustoelastic_iop_hgo/official_cp_mutation_review.md
```

Classification:

```text
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticAtlasBranch.m              KEEP_OFFICIAL_ASSIGNMENT
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticDispersion.m               KEEP_SOLVER_ASSIGNMENT
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticComplexCDispersion.m       KEEP_DIAGNOSTIC_SOLVER_VALIDCP

tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_branch_persistence_refinement.m   FALSE_POSITIVE_TEST_FIXTURE
tests/acoustoelastic_iop_hgo/test_ae_analyze_truncation_recovery.m                         FALSE_POSITIVE_TEST_FIXTURE
```

Conclusion:

```text
No code change is required for the current MutatesOfficialCp flags.
The flags are either legitimate solver-result construction, diagnostic-solver validCp construction, or synthetic test fixtures.
```

### Priority 3: legacy script classification

Legacy descriptive scripts should not be removed just because they are long.

Each legacy script should be classified as:

- required implementation target of a short wrapper;
- historical diagnostic still referenced by documentation;
- obsolete diagnostic superseded by a maintained short entrypoint;
- safe removal candidate after reference checks.

### Priority 4: wrapper consolidation

Short wrappers are useful, but wrappers that only call legacy scripts may eventually point to shorter implementation files when the implementation is still maintained.

This should be done case by case, not as a broad rename sweep.

### Wrapper consolidation and archived-diagnostic cleanup status

A conservative wrapper inspection of `examples/acoustoelastic_iop_hgo/basic/`, `examples/acoustoelastic_iop_hgo/sweeps/`, and `examples/acoustoelastic_iop_hgo/diagnostics/` found no missing `aeRunLegacyScript` targets in the maintained short-wrapper layer.

Converted earlier to direct maintained implementations, with the legacy descriptive file changed to a compatibility alias:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_sweep_reliability.m
  CONVERT_SHORT_TO_DIRECT
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_sweep_reliability.m
  LEGACY_ALIAS_TO_SHORT

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_idA0_score.m
  CONVERT_SHORT_TO_DIRECT
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_branch_identity_score.m
  LEGACY_ALIAS_TO_SHORT

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_atlas_truncation.m
  CONVERT_SHORT_TO_DIRECT
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_atlasA0_truncation_cause.m
  LEGACY_ALIAS_TO_SHORT

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
  DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION_WITH_LAUNCH_FOLDER_PRESERVATION
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  MIGRATE_OUTPUT_PATH

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
  DIRECT_DELEGATION_TO_MIGRATED_IMPLEMENTATION_WITH_LAUNCH_FOLDER_PRESERVATION
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
  MIGRATE_OUTPUT_PATH
```

Archived executable diagnostics removed after reference checks and retained documentation coverage:

```text
compare_branch_policies.m
compare_acoustoelastic_iop_hgo_branch_policies.m
diagnose_branch_policy.m
diagnose_acoustoelastic_iop_hgo_branch_policy.m
diagnose_truncation_cases.m
diagnose_acoustoelastic_iop_hgo_truncation_cases.m
diagnose_landscape_failure.m
diagnose_acoustoelastic_iop_hgo_failure_landscape.m
diagnose_branch_persistence.m
diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement.m
diagnose_atlas_resolution.m
diagnose_acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity.m
```

Remaining wrappers and reasons:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_idA0_plausibility.m
  KEEP_AS_WRAPPER: target is the renamed implementation file, not a legacy descriptive script.

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_identityA0_plausibility.m
  COMPATIBILITY_ALIAS_CANDIDATE: older identityA0-facing name; review references before deletion.

examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_score_grid.m
  KEEP_AS_WRAPPER: targets exist and write to clean output helpers; the implementations are heavy validation grids.

examples/acoustoelastic_iop_hgo/diagnostics/track_raw_branch1.m
  RETAIN_FOR_COMPARISON_REPRODUCIBILITY: required while compare_atlasA0_vs_raw_branch1 consumes raw_branch1_curve.csv.
```

Wrapper consolidation is partially complete; legacy cleanup remains open.

### Priority 5: documentation consistency

Documentation should distinguish:

```text
critical renaming closed
structural cleanup open
solver optimization closed
modal-identity research open
```

Avoid using a single phrase such as `framework closed` without specifying which layer is closed.

### Required checks before removing any file

For each removal candidate:

```bash
git grep "<candidate_basename>"
git grep "<candidate_filename>"
```

Then run:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
```

### Recommended next cleanup order

1. Review and delete Group A simple compatibility aliases from `structural_audit_refresh.md` only after candidate-specific `git grep` checks.
2. Update docs that still mention deleted aliases as runnable commands.
3. Run `test_acoustoelastic_iop_hgo_short_entrypoints` and `run_all_smoke_tests`.
4. Only then consider the Group B identity-A0 compatibility alias.
5. Keep validation-grid wrappers and `track_raw_branch1` for now.

### Current decision

Do not start a broad deletion pass.

The next safe cleanup step is the focused deletion-review pass for Group A simple compatibility aliases listed in `structural_audit_refresh.md`.
