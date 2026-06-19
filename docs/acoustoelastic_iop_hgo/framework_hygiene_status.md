### Framework hygiene status

This document records the framework-structure status after closing the `atlasA0` solver optimization phase.

### Overall status

The framework is in a usable and maintainable state.

```text
Solver status: closed for the current atlasA0 optimization phase
Framework status: mixed but controlled
Naming status: maintained short layer plus legacy descriptive layer
Recommended next work: light hygiene only, not solver retuning
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

This is acceptable as long as the legacy scripts are treated as compatibility or implementation-history files, not as the preferred user-facing interface.

The mapping from short entrypoints to legacy files is maintained in:

```text
docs/acoustoelastic_iop_hgo/legacy_entrypoint_map.md
```

### Naming risk

The main known naming risk is the legacy file whose basename is longer than MATLAB's usual `namelengthmax = 63`:

```text
diagnose_idA0_plausibility_impl.m
```

Do not use it as a direct command. Prefer:

```matlab
diagnose_idA0_plausibility
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

### What is considered clean enough

The framework is considered clean enough for continued development if:

1. Maintained short entrypoints remain documented and pass the path smoke test.
2. New user-facing scripts use short names.
3. New outputs use `Results/ae_iop_hgo/<task>`.
4. Legacy scripts are not expanded unless required for compatibility.
5. Diagnostics do not mutate official solver outputs.

### What should not be done now

Do not perform a large deletion or rename sweep at this stage.

Avoid:

- deleting legacy scripts without a clear replacement check;
- renaming legacy files that may still be referenced by wrappers;
- changing production solver policy as part of hygiene cleanup;
- mixing framework cleanup with modal-identity research.

### Recommended cleanup policy

Use small PRs with one purpose each:

1. Documentation and index cleanup.
2. Wrapper/legacy mapping cleanup.
3. Non-numerical report-column cleanup.
4. Optional helper extraction from diagnostics into `analysis/acoustoelastic_iop_hgo/`.

Each PR should keep MATLAB logic changes minimal and should pass:

```matlab
test_acoustoelastic_iop_hgo_short_entrypoints
```

### Current conclusion

The framework is stable enough to build on.

The next major phase, if needed, should be modal-identity enhancement rather than additional residual-tracking tuning or broad framework restructuring.
