### Structural cleanup backlog

This document records remaining cleanup work after the targeted identity-A0 plausibility renaming pass.

### Summary

The critical MATLAB filename issue is resolved, but the repository still contains cleanup candidates.

Current audit signals:

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
```

### Priority 1: output path cleanup

Many scripts still match `WritesLegacyResults`.

This should be triaged into:

1. true legacy output writes that should be migrated to `aeOutputFolder`;
2. compatibility fallback reads through `aeResolveResultFile`;
3. text-only documentation references;
4. tests that intentionally verify legacy compatibility.

Do not change official numerical outputs while doing this cleanup.

Initial cleanup action completed:

```text
examples/acoustoelastic_iop_hgo/basic/run_atlas_branch.m
  DIRECT_MAINTAINED_ENTRYPOINT
  Now calls solveAcoustoelasticIOPHGOAtlasBranch directly and writes under Results/ae_iop_hgo/atlas_branch.

examples/acoustoelastic_iop_hgo/basic/run_acoustoelastic_iop_hgo_atlas_branch.m
  LEGACY_ALIAS_TO_SHORT
  Now delegates to run_atlas_branch for compatibility.
```

### Priority 2: mutation flag review completed

The audit reports `MutatesOfficialCp = 5`.

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

Legacy descriptive scripts should not be deleted just because they are long.

Each legacy script should be classified as:

- required implementation target of a short wrapper;
- historical diagnostic still referenced by documentation;
- obsolete diagnostic superseded by a maintained short entrypoint;
- safe deletion candidate after `git grep` reference checks.

### Priority 4: wrapper consolidation

Short wrappers are useful, but wrappers that only call legacy scripts should eventually point to shorter implementation files when the implementation is still maintained.

This should be done case by case, not as a broad rename sweep.


### Wrapper consolidation pass: diagnostics partial

A conservative wrapper inspection of `examples/acoustoelastic_iop_hgo/basic/`, `examples/acoustoelastic_iop_hgo/sweeps/`, and `examples/acoustoelastic_iop_hgo/diagnostics/` found no missing `aeRunLegacyScript` targets in the maintained short-wrapper layer.

Converted to direct maintained implementations, with the legacy descriptive file changed to a compatibility alias:

```text
examples/acoustoelastic_iop_hgo/diagnostics/compare_branch_policies.m
  CONVERT_SHORT_TO_DIRECT
examples/acoustoelastic_iop_hgo/diagnostics/compare_acoustoelastic_iop_hgo_branch_policies.m
  LEGACY_ALIAS_TO_SHORT

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

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_branch_persistence.m
  CONVERT_SHORT_TO_DIRECT
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement.m
  LEGACY_ALIAS_TO_SHORT

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_atlas_resolution.m
  CONVERT_SHORT_TO_DIRECT
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity.m
  LEGACY_ALIAS_TO_SHORT
```

Deferred wrappers and reasons:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_idA0_plausibility.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_identityA0_plausibility.m
  KEEP_AS_WRAPPER: target is the renamed implementation file, not a legacy descriptive script.

examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_score_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/track_raw_branch1.m
  TOO_RISKY_DEFER: target exists and uses clean output helpers, but the implementation is large enough to defer to a focused pass.

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_truncation_cases.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_landscape_failure.m
  TOO_RISKY_DEFER: target exists and uses clean output helpers, but the diagnostic implementation is long/heavy.

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
  KEEP_AS_WRAPPER: target exists but has additional result-copy compatibility behavior in the short wrapper.

examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
  TOO_RISKY_DEFER: wrapper edits a temporary copy of a long legacy diagnostic rather than using a simple `aeRunLegacyScript` target.
```

No files were deleted in this pass. Wrapper consolidation is partially complete; legacy cleanup still open.

### Priority 5: documentation consistency

Documentation should distinguish:

```text
critical renaming closed
structural cleanup open
solver optimization closed
modal-identity research open
```

Avoid using a single phrase such as `framework closed` without specifying which layer is closed.

### Required checks before deleting any file

For each deletion candidate:

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

1. Separate true legacy output writes from compatibility references.
2. Convert maintained short wrappers to short implementation files only when needed.
3. Delete only obsolete scripts that are unreferenced and superseded.
4. Update `legacy_entrypoint_map.md` after each consolidation.

### Current decision

Do not start a broad deletion pass yet.

The next safe cleanup step is output-path triage for files flagged as `WritesLegacyResults`, starting with maintained short entrypoints that still depend on legacy bridges.
