### Framework hygiene status

This document records the framework-structure status after closing the `atlasA0` solver optimization phase and the targeted naming cleanup.

### Overall status

The critical MATLAB naming risk is closed, but the broader framework cleanup is not fully closed.

```text
Solver status: closed for the current atlasA0 optimization phase
Critical naming status: closed; Over63Chars = 0 after targeted rename
Framework cleanup status: partially complete; structural cleanup backlog remains
Legacy status: accepted temporarily, but not automatically permanent
Recommended next work: cleanup backlog triage before modal-identity development
```

### Current structure

The active module layout is:

```text
analysis/acoustoelastic_iop_hgo/              reusable helpers
models/acoustoelastic_iop_hgo/                model and solver implementation
examples/acoustoelastic_iop_hgo/basic/        basic executable examples
examples/acoustoelastic_iop_hgo/sweeps/       sweep entrypoints
examples/acoustoelastic_iop_hgo/diagnostics/  diagnostics and validations
tests/acoustoelastic_iop_hgo/                 tests
docs/acoustoelastic_iop_hgo/                  module documentation
Results/ae_iop_hgo/<task>                     generated outputs
```

This structure should be preserved.

### Maintained layer

The maintained user-facing layer uses short task-oriented names.

Examples:

```matlab
run_atlas_branch
sweep_iop
sweep_mu
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
track_raw_branch1
```

This is the layer that should be used in examples, documentation, and future workflows.

### Legacy layer

The repository still contains descriptive legacy scripts with names such as:

```text
run_acoustoelastic_iop_hgo_...
sweep_acoustoelastic_iop_hgo_...
diagnose_acoustoelastic_iop_hgo_...
track_acoustoelastic_iop_hgo_...
```

These files are tolerated for compatibility and implementation history, but they should be triaged before being treated as permanent.

The mapping from short entrypoints to legacy files is maintained in:

```text
docs/acoustoelastic_iop_hgo/legacy_entrypoint_map.md
```

### Naming status

The previous known `namelengthmax` issue in the identity-A0 plausibility diagnostic has been resolved by renaming the implementation file to:

```text
diagnose_idA0_plausibility_impl.m
```

The preferred user-facing command remains:

```matlab
diagnose_idA0_plausibility
```

The post-renaming audit is recorded in:

```text
docs/acoustoelastic_iop_hgo/post_rename_audit.md
```

The current naming decision is:

```text
Over63Chars = 0
No immediate compatibility-driven renaming is required.
```

This does not imply that all legacy files are final. It only means that there is no remaining MATLAB `namelengthmax` blocker.

### Result path convention

New outputs should be written under:

```text
Results/ae_iop_hgo/<task>
```

New scripts should use:

```matlab
aeOutputFolder(launchFolder, taskName)
```

Legacy result folders may remain available for fallback, but new work should not add new `Results/acoustoelastic_iop_hgo_*` output roots.

### Remaining cleanup signals

The current audit still reports structural cleanup signals, including:

```text
WritesLegacyResults > 0
MutatesOfficialCp > 0
IsLegacyLongName > 0
Over45Chars > 0
```

These flags require triage. Some are acceptable compatibility behavior, while others may indicate obsolete or simplifiable code.

The active backlog is recorded in:

```text
docs/acoustoelastic_iop_hgo/structural_cleanup_backlog.md
```

### What is considered closed

The following items are closed:

1. `atlasA0` optimization for the current conservative production policy.
2. The identity-A0 plausibility filename exceeding MATLAB `namelengthmax`.
3. Documentation indexing for the post-renaming audit.

### What is not yet closed

The following items are not yet closed:

1. Legacy result-path usage across older scripts.
2. Classification of legacy scripts into keep, wrap-only, consolidate, or delete.
3. Review of scripts flagged by `MutatesOfficialCp`.
4. Optional simplification of historical diagnostics that are no longer needed.
5. Verification that maintained entrypoints cover all workflows that should remain supported.

### Cleanup policy

Future cleanup should start from the audit reports, not from manual inspection alone.

Use dedicated commits for:

1. path-output cleanup;
2. wrapper/legacy mapping cleanup;
3. legacy deletion or archival only after reference checks;
4. non-numerical report-column cleanup;
5. optional helper extraction from diagnostics into `analysis/acoustoelastic_iop_hgo/`.

Each commit should keep MATLAB logic changes minimal and should pass:

```matlab
test_acoustoelastic_iop_hgo_short_entrypoints
```

For deletions or consolidation, also run:

```bash
git grep "<candidate_name>"
```

### Current conclusion

The framework is stable enough to build on, but the broader cleanup is not complete.

The correct closure statement is: critical renaming is closed; structural cleanup remains open and should be handled through the cleanup backlog before starting a larger modal-identity development phase.
