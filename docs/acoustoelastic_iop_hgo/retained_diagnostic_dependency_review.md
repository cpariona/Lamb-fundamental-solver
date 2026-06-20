### Retained diagnostic dependency review

This document records the review performed after the simple compatibility-alias cleanup and local smoke-test validation.

### Scope

Reviewed retained acoustoelastic IOP/HGO scripts that still look similar to older long-name workflows, but are not simple aliases.

Main focus:

```text
track_raw_branch1
compare_atlasA0_vs_raw_branch1
validate_idA0_grid
validate_idA0_score_grid
retained long descriptive diagnostic implementations
retained exploratory basic examples
```

### Summary decision

The simple compatibility-alias cleanup is complete. The E1 direct-matrix exploratory group has now also been archived after preserving its conclusions in documentation.

Current conclusion:

```text
The remaining short wrappers are intentional.
The remaining long descriptive files contain implementation, heavy validation, retained exploratory diagnostic, or reproducibility logic.
The archived E1 exploratory files are documented in direct_matrix_landscape_archive.md.
```

### Raw-branch comparison pipeline

The dependency is real and should be retained for now.

Pipeline:

```text
diagnose_modal_atlas_lowfreq
  -> Results/ae_iop_hgo/modal_atlas_lowfreq

track_raw_branch1
  -> reads modal_atlas_lowfreq outputs
  -> writes Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv

compare_atlasA0_vs_raw_branch1
  -> reads Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv
  -> compares raw_branch1, atlasA0, and identityA0Diagnostic
```

Relevant files:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
examples/acoustoelastic_iop_hgo/diagnostics/track_raw_branch1.m
examples/acoustoelastic_iop_hgo/diagnostics/track_acoustoelastic_iop_hgo_raw_branch1_candidate.m
examples/acoustoelastic_iop_hgo/diagnostics/compare_atlasA0_vs_raw_branch1.m
```

Decision:

```text
KEEP track_raw_branch1
KEEP track_acoustoelastic_iop_hgo_raw_branch1_candidate.m
```

Reason:

```text
compare_atlasA0_vs_raw_branch1 still depends on raw_branch1_curve.csv.
Removing the generator would make the maintained comparison depend on an undocumented external artifact.
```

Future simplification option:

```text
Move raw-branch candidate extraction into an analysis helper, then let both track_raw_branch1 and compare_atlasA0_vs_raw_branch1 call the helper or share an explicit generated workspace contract.
```

Do not do this as a mechanical cleanup. It would change diagnostic workflow structure.

### Validation-grid wrappers

Reviewed wrappers:

```text
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_score_grid.m
```

Targets:

```text
examples/acoustoelastic_iop_hgo/diagnostics/validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_acoustoelastic_iop_hgo_branch_identity_score_grid.m
```

Decision:

```text
KEEP_AS_WRAPPER
```

Reason:

```text
The short wrappers are stable.
The targets are heavy validation implementations.
The targets already write to clean short result folders through aeOutputFolder.
Inlining or inverting these files would reduce one wrapper layer, but would not fix a current defect.
```

Future simplification option:

```text
Invert the wrappers only if the heavy validations are intentionally modified and run locally:
1. Move implementation into the short file.
2. Convert the descriptive file into an archived note or remove it after reference checks.
3. Run both heavy validations before committing.
```

### Retained modal-atlas implementations

Reviewed retained implementations:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
```

Decision:

```text
KEEP_AS_RETAINED_IMPLEMENTATION
```

Reason:

```text
They are implementation targets of the maintained short entrypoints.
They generate diagnostic evidence for modal-family ambiguity.
They already write to Results/ae_iop_hgo/modal_atlas and Results/ae_iop_hgo/modal_atlas_lowfreq through aeOutputFolder.
```

### Archived E1 exploratory diagnostics

The following direct-matrix exploratory scripts were archived after preserving their conclusions in `direct_matrix_landscape_archive.md`:

```text
examples/acoustoelastic_iop_hgo/basic/run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_dimensionless_A1.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_matrix_variants.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_residual_landscape.m
```

Decision:

```text
ARCHIVED_AFTER_DOCUMENTATION
```

Reason:

```text
These scripts isolated direct alpha-beta-gamma behavior, M54 variant checks, dimensionless A1-style diagnostics, and residual landscapes. Their conclusions are now preserved in documentation, and the underlying solver/model options remain in the implementation.
```

### Retained exploratory examples

Remaining long descriptive examples and diagnostics still present as exploratory or historical development scripts:

```text
examples/acoustoelastic_iop_hgo/basic/run_acoustoelastic_iop_hgo_A0_backward.m
examples/acoustoelastic_iop_hgo/basic/run_acoustoelastic_iop_hgo_A0_complexC.m
examples/acoustoelastic_iop_hgo/diagnostics/compare_acoustoelastic_iop_hgo_tracking_strategies.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_grid_convergence.m
examples/acoustoelastic_iop_hgo/sweeps/sweep_acoustoelastic_iop_hgo_A0_backward.m
```

Decision:

```text
KEEP_AS_EXPLORATORY_FOR_NOW
```

Reason:

```text
These are not simple aliases.
They encode remaining historical solver-development questions: A0 backward behavior, grid convergence, tracking-strategy comparison, historical sweep behavior, and complex-C continuation.
Some contain conclusions or visual checks that may still be useful for thesis traceability.
```

Caveat:

```text
These should not be presented as maintained public workflows.
They should remain outside routine execution and outside smoke-test expectations.
```

Future cleanup option:

```text
Archive or consolidate exploratory examples only after confirming their conclusions are fully represented in documentation.
```

Suggested future order:

```text
1. Review A0 backward, grid convergence, and tracking strategies together.
2. Review the A0 backward sweep after confirming it no longer supports retained sweep/truncation evidence.
3. Review complex-C continuation separately, because it may still be a future solver direction.
```

### Current action recommendation

Do not delete another exploratory group until the E1 deletion batch has passed local validation.

Recommended next step after validation:

```text
Review E2: A0 backward, grid convergence, tracking strategies, and historical A0 backward sweep.
```
