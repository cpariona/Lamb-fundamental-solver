### Structural cleanup backlog

This document records remaining cleanup work after the targeted identity-A0 plausibility renaming pass, archived-diagnostic cleanup passes, exploratory archival passes, and raw-branch helper extraction.

### Summary

The critical MATLAB filename issue is resolved. Simple aliases, exploratory examples, and the raw-branch long implementation script have been cleaned up.

The latest operational cleanup audit is recorded in:

```text
docs/acoustoelastic_iop_hgo/structural_audit_refresh.md
```

The curated documentation map is recorded in:

```text
docs/acoustoelastic_iop_hgo/documentation_index.md
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

Those values are stale after archived-diagnostic deletions, modal-atlas output-path migrations, exploratory archival passes, and raw-branch helper extraction. Use `structural_audit_refresh.md` and `examples_inventory.md` for current cleanup decisions.

### Interpretation

`Over63Chars = 0` means there is no remaining known `namelengthmax` blocker.

Other historical flags do not automatically mean errors. They identify files that needed classification at the time of the audit.

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
RETAIN_FOR_COMPARISON_REPRODUCIBILITY
HELPER_BACKED_REPRODUCIBILITY
ARCHIVED_REMOVED
```

### Closed cleanup work

The following cleanup categories are closed:

```text
critical namelengthmax rename
simple compatibility-alias deletion
standard modal-atlas output-path migration
low-frequency modal-atlas output-path migration
archived branch-policy/truncation/failure/persistence executable diagnostics
exploratory archival groups E1-E3
raw_branch1 helper extraction
curated documentation index creation
```

### Output path status

Current maintained output root:

```text
Results/ae_iop_hgo/<task>
```

The raw-branch extraction logic now lives in:

```text
analysis/acoustoelastic_iop_hgo/aeExtractRawBranch1Candidate.m
```

Current raw-branch flow:

```text
diagnose_modal_atlas_lowfreq
  -> Results/ae_iop_hgo/modal_atlas_lowfreq

aeExtractRawBranch1Candidate
  -> Results/ae_iop_hgo/raw_branch1

track_raw_branch1
  -> calls aeExtractRawBranch1Candidate

compare_atlasA0_vs_raw_branch1
  -> reads raw_branch1_curve.csv when available
  -> regenerates raw_branch1_curve.csv through aeExtractRawBranch1Candidate when missing
```

Compatibility fallback reads may remain for historical results, but new code should not add new `Results/acoustoelastic_iop_hgo_*` output roots.

### Priority 1: mutation flag review completed

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

### Priority 2: retained wrapper classification

Remaining wrappers and reasons:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_idA0_plausibility.m
  KEEP_AS_WRAPPER
  Target is diagnose_idA0_plausibility_impl.m.
  Requires the idA0_grid workspace produced by validate_idA0_grid.

examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_score_grid.m
  KEEP_AS_WRAPPER
  Targets exist and write to clean output helpers.
  Implementations are heavy validation grids.

examples/acoustoelastic_iop_hgo/diagnostics/track_raw_branch1.m
  HELPER_BACKED_REPRODUCIBILITY
  Calls aeExtractRawBranch1Candidate.
  Kept as an explicit short entrypoint for raw_branch1 evidence generation.
```

### Priority 3: retained long implementation targets

Do not delete the following solely because they are long:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_acoustoelastic_iop_hgo_branch_identity_score_grid.m
```

They are retained modal-atlas or heavy-validation implementations.

### Candidate future cleanup groups

#### Group C: heavy validation wrapper consolidation

Candidates:

```text
validate_idA0_grid.m
validate_idA0_score_grid.m
validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid.m
validate_acoustoelastic_iop_hgo_branch_identity_score_grid.m
```

Current decision:

```text
Do not consolidate until these heavy validations are intentionally run and verified locally.
```

Required validation if changed:

```matlab
validate_idA0_grid
validate_idA0_score_grid
test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

#### Group D: modal-atlas helper extraction

Candidates:

```text
diagnose_modal_atlas.m
diagnose_modal_atlas_lowfreq.m
diagnose_acoustoelastic_iop_hgo_modal_atlas.m
diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
```

Current decision:

```text
Do not consolidate by deletion.
A future pass should extract reusable modal-atlas helpers into analysis/acoustoelastic_iop_hgo/ first.
```

Required validation if changed:

```matlab
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

### Documentation consistency

Documentation should distinguish:

```text
critical renaming closed
simple alias cleanup closed
exploratory archival closed
raw-branch helper extraction closed
solver optimization closed for current atlasA0 policy
modal-identity research open
heavy wrapper/modal-atlas refactor optional
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
run_all_smoke_tests
```

For raw-branch changes, also run:

```matlab
diagnose_modal_atlas_lowfreq
track_raw_branch1
compare_atlasA0_vs_raw_branch1
```

### Recommended next cleanup order

1. Pull the latest commits locally.
2. Run `test_acoustoelastic_iop_hgo_short_entrypoints` and `run_all_smoke_tests`.
3. Keep validation-grid wrappers and modal-atlas implementation targets unless intentionally refactoring them.
4. Next cleanup should focus on documentation consistency or a fresh local grep audit, not immediate deletion of implementation files.

### Current decision

Do not start a broad deletion pass.

The simple compatibility-alias cleanup, exploratory archival passes, raw-branch helper extraction, and documentation index creation are complete. Remaining executable wrappers and long implementation files are intentional and should not be deleted as duplicates without a separate design decision.
