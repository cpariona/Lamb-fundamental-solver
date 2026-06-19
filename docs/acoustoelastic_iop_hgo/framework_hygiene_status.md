### Framework hygiene status

This document records the framework-structure status after closing the `atlasA0` solver optimization phase and the targeted naming cleanup.

### Overall status

The framework hygiene pass is closed for the current acoustoelastic IOP/HGO phase.

```text
Solver status: closed for the current atlasA0 optimization phase
Framework status: closed for current hygiene pass
Naming status: maintained short layer plus accepted legacy descriptive layer
Renaming status: targeted rename completed; no broad rename recommended
Recommended next work: future modal-identity phase, not residual-tracking retuning
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

### Accepted legacy layer

The repository still contains descriptive legacy scripts with names such as:

```text
run_acoustoelastic_iop_hgo_...
sweep_acoustoelastic_iop_hgo_...
diagnose_acoustoelastic_iop_hgo_...
track_acoustoelastic_iop_hgo_...
```

This is acceptable. These scripts are compatibility or implementation-history files, not the preferred user-facing interface.

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

The audit decision is:

```text
Over63Chars = 0
No additional broad renaming is recommended.
```

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

### Closure criteria

This framework hygiene pass is considered closed because:

1. Maintained short entrypoints are documented.
2. The path smoke test passes locally.
3. New acoustoelastic docs are indexed from `docs/acoustoelastic_iop_hgo/README.md` and `docs/maintained_entrypoints.md`.
4. The known `namelengthmax` issue has been removed.
5. The remaining long descriptive names are accepted as legacy, not active renaming targets.
6. Diagnostics remain diagnostic-only and do not define production output policy.

### What should not be done in this closed pass

Do not perform a broad deletion or rename sweep at this stage.

Avoid:

- deleting legacy scripts without a clear replacement check;
- renaming legacy files that may still be referenced by wrappers;
- changing production solver policy as part of hygiene cleanup;
- mixing framework cleanup with modal-identity research.

### Future cleanup policy

Future cleanup should start from the audit reports, not from manual inspection alone.

Use small, dedicated commits for:

1. documentation/index cleanup;
2. wrapper/legacy mapping cleanup;
3. non-numerical report-column cleanup;
4. optional helper extraction from diagnostics into `analysis/acoustoelastic_iop_hgo/`.

Each commit should keep MATLAB logic changes minimal and should pass:

```matlab
test_acoustoelastic_iop_hgo_short_entrypoints
```

### Current conclusion

The framework is stable enough to build on.

The current hygiene and renaming phase is closed. The next major phase, if needed, should be modal-identity enhancement rather than additional residual-tracking tuning or broad framework restructuring.
