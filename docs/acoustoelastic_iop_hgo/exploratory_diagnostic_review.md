### Exploratory diagnostic review

This document classifies retained exploratory acoustoelastic IOP/HGO scripts after the simple compatibility-alias cleanup and retained-diagnostic dependency review.

### Purpose

The goal is to distinguish:

```text
maintained public workflow
maintained diagnostic evidence
retained historical/exploratory diagnostic
archived exploratory diagnostic
candidate for future archival
```

### Current decision

The E1 direct-matrix exploratory group has been archived after preserving its conclusions in:

```text
docs/acoustoelastic_iop_hgo/direct_matrix_landscape_archive.md
```

The E2 A0-backward/tracking exploratory group has been archived after preserving its conclusions in:

```text
docs/acoustoelastic_iop_hgo/a0_backward_tracking_archive.md
```

Do not archive E3 in the same pass.

### Classification summary

| File | Classification | Reason | Current action |
|---|---|---|---|
| `run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma.m` | `ARCHIVED_EXPLORATORY_DIRECT_MODEL_CHECK` | Bypassed IOP/HGO and solved the direct alpha-beta-gamma matrix problem. Purpose and conclusions preserved in `direct_matrix_landscape_archive.md`. | Removed. |
| `diagnose_acoustoelastic_iop_hgo_matrix_variants.m` | `ARCHIVED_EXPLORATORY_MATRIX_CHECK` | Compared paper and corrected `M54` variants. Purpose and conclusions preserved in `direct_matrix_landscape_archive.md`. | Removed. |
| `diagnose_acoustoelastic_iop_hgo_dimensionless_A1.m` | `ARCHIVED_EXPLORATORY_DIMENSIONLESS_CHECK` | Recreated an Appendix-A1-style dimensionless diagnostic for the direct solver shape. Purpose and conclusions preserved in `direct_matrix_landscape_archive.md`. | Removed. |
| `diagnose_acoustoelastic_iop_hgo_residual_landscape.m` | `ARCHIVED_EXPLORATORY_LANDSCAPE_CHECK` | Mapped objective minima over dimensionless phase velocity and frequency. Purpose and conclusions preserved in `direct_matrix_landscape_archive.md`. | Removed. |
| `diagnose_acoustoelastic_iop_hgo_grid_convergence.m` | `ARCHIVED_EXPLORATORY_GRID_CONVERGENCE` | Checked Cp grid sensitivity and branch-map behavior. Purpose and conclusions preserved in `a0_backward_tracking_archive.md`. | Removed. |
| `compare_acoustoelastic_iop_hgo_tracking_strategies.m` | `ARCHIVED_EXPLORATORY_TRACKING_COMPARISON` | Compared global scan, predictive continuation, singular-vector tracking, A0High, and complex-C diagnostic routes. Purpose and conclusions preserved in `a0_backward_tracking_archive.md`. | Removed. |
| `run_acoustoelastic_iop_hgo_A0_backward.m` | `ARCHIVED_EXPLORATORY_A0_BACKWARD_EXAMPLE` | Demonstrated the earlier corrected-M54 A0 backward global-scan workflow. Purpose and conclusions preserved in `a0_backward_tracking_archive.md`. | Removed. |
| `sweep_acoustoelastic_iop_hgo_A0_backward.m` | `ARCHIVED_EXPLORATORY_A0_BACKWARD_SWEEP` | Historical A0 backward sweep. Purpose and conclusions preserved in `a0_backward_tracking_archive.md`. | Removed. |
| `run_acoustoelastic_iop_hgo_A0_complexC.m` | `RETAIN_EXPLORATORY_COMPLEX_C` | Tests complex phase-velocity continuation as a diagnostic route. Not part of official `atlasA0` output. | Keep for now. |

### Not maintained public workflows

The retained exploratory scripts above should not be presented as routine commands. Routine acoustoelastic workflows remain:

```matlab
run_atlas_branch
sweep_iop
sweep_mu
```

Maintained diagnostic evidence remains:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
```

### Relationship to current branch policy

The official branch policy remains:

```text
atlasA0
```

Retained exploratory diagnostics must not mutate or replace:

```matlab
result.Cp
result.validCp
```

and should not be used to promote:

```text
identityA0Diagnostic
raw_branch1
complex-C continuation
threshold-relaxed continuation
```

into official solver outputs.

### Archived exploratory groups

#### Group E1: Direct matrix and M54 evidence

Archived files:

```text
run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma.m
diagnose_acoustoelastic_iop_hgo_matrix_variants.m
diagnose_acoustoelastic_iop_hgo_dimensionless_A1.m
diagnose_acoustoelastic_iop_hgo_residual_landscape.m
```

Archive evidence:

```text
docs/acoustoelastic_iop_hgo/direct_matrix_landscape_archive.md
```

Reason:

```text
The direct matrix behavior, M54 variant reasoning, dimensionless diagnostic behavior, and residual landscape conclusions are now represented in documentation. The underlying solver/model options remain in the model implementation.
```

#### Group E2: Tracking and A0 backward evidence

Archived files:

```text
run_acoustoelastic_iop_hgo_A0_backward.m
sweep_acoustoelastic_iop_hgo_A0_backward.m
compare_acoustoelastic_iop_hgo_tracking_strategies.m
diagnose_acoustoelastic_iop_hgo_grid_convergence.m
```

Archive evidence:

```text
docs/acoustoelastic_iop_hgo/a0_backward_tracking_archive.md
```

Reason:

```text
The A0 backward route, historical sweep, tracking comparison, and grid-convergence conclusions are now represented in documentation. Current maintained workflows and diagnostics provide stronger coverage for atlasA0 behavior and modal ambiguity.
```

### Candidate future archival groups

#### Group E3: Complex-C continuation

```text
run_acoustoelastic_iop_hgo_A0_complexC.m
```

Suggested condition before archival:

```text
Decide whether complex-C continuation remains a future solver direction. If yes, keep. If no, document why it is diagnostic-only before archival.
```

### Required checks before archiving any exploratory group

For every candidate group:

```bash
git grep "<script_basename>"
git grep "<script_filename>"
```

Then run:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

If the candidate group has a maintained replacement entrypoint, run that maintained replacement as well.

### Current recommendation

Do not archive E3 until the E2 deletion batch has passed local validation and a clear decision has been made about whether complex-C continuation remains a future solver direction.
