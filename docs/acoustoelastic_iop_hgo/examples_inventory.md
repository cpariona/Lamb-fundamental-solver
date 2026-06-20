### Current acoustoelastic IOP/HGO examples inventory

This document records the final post-cleanup inventory of executable files under:

```text
examples/acoustoelastic_iop_hgo/
```

It separates public workflows, maintained diagnostic evidence, retained historical diagnostics, and temporary investigation diagnostics.

### Summary

After the compatibility-alias cleanup and exploratory archival passes E1-E3, no long exploratory example scripts remain as retained public or semi-public workflows.

Current retained executable layers:

```text
1. Public workflows
2. Maintained diagnostic evidence
3. Temporary investigation diagnostics
4. Historical diagnostics retained for thesis/traceability
5. Long implementation targets for short wrappers
```

The raw-branch extraction logic has been moved to:

```text
analysis/acoustoelastic_iop_hgo/aeExtractRawBranch1Candidate.m
```

No additional mechanical file deletion is recommended from this inventory pass.

### Basic examples

#### Public workflow

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `basic/run_atlas_branch.m` | `PUBLIC_WORKFLOW` | Writes to `Results/ae_iop_hgo/atlas_branch` through the maintained atlas solver workflow. | Keep. |

Notes:

```text
All old long-name basic exploratory examples have been archived.
No basic alias file remains.
```

### Sweeps

#### Public workflows

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `sweeps/sweep_iop.m` | `PUBLIC_WORKFLOW` | Writes to `Results/ae_iop_hgo/iop_sweep`. | Keep. |
| `sweeps/sweep_mu.m` | `PUBLIC_WORKFLOW` | Writes to `Results/ae_iop_hgo/mu_sweep`. | Keep. |

Notes:

```text
Legacy sweep aliases and historical A0-backward sweep examples have been archived.
No sweep alias file remains.
```

### Maintained diagnostic evidence

These diagnostics support the current `atlasA0` policy, ambiguity interpretation, or official-vs-diagnostic branch comparisons.

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `diagnostics/compare_atlasA0_vs_raw_branch1.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Reads `Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv` when present; otherwise regenerates it from `modal_atlas_lowfreq` using `aeExtractRawBranch1Candidate`. Writes to `Results/ae_iop_hgo/atlas_vs_raw_branch1`. | Keep. |
| `diagnostics/validate_atlas_raw_grid.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/atlas_vs_raw_branch1_grid`. | Keep. |
| `diagnostics/diagnose_raw_branch_corner.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/raw_branch_corner`. | Keep. |
| `diagnostics/diagnose_branch_families.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/branch_families`. | Keep. |
| `diagnostics/diagnose_sweep_reliability.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/sweep_reliability`. Requires sweep workspaces. | Keep. |
| `diagnostics/diagnose_atlas_truncation.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE` | Writes to `Results/ae_iop_hgo/atlas_truncation`. Requires sweep workspaces. | Keep. |
| `diagnostics/diagnose_idA0_plausibility.m` | `MAINTAINED_DIAGNOSTIC_EVIDENCE_WRAPPER` | Delegates to `diagnose_idA0_plausibility_impl.m`; requires `idA0_grid` workspace. | Keep. |
| `diagnostics/diagnose_idA0_plausibility_impl.m` | `MAINTAINED_DIAGNOSTIC_IMPLEMENTATION` | Writes to `Results/ae_iop_hgo/idA0_plausibility`. | Keep as implementation target. |

### Temporary investigation diagnostics

These scripts exist to investigate current solver-interface behavior. They must be promoted, migrated, deleted, or archived after their conclusions are captured.

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `diagnostics/diagnose_grid_start_sensitivity.m` | `TEMPORARY_INVESTIGATION_DIAGNOSTIC` | Writes to `Results/ae_iop_hgo/grid_start_sensitivity`. Tests atlasA0 sensitivity to frequency start and output density. | Review after solver fix; do not keep indefinitely as temporary code. |

### Historical diagnostics retained for traceability

These scripts are retained because they support thesis traceability or heavy validation, but they are not routine workflows.

| File | Classification | Output behavior | Action |
|---|---|---|---|
| `diagnostics/diagnose_idA0_score.m` | `HISTORICAL_DIAGNOSTIC_RETAINED` | Writes to `Results/ae_iop_hgo/idA0_score`. Requires sweep workspaces. | Keep. |
| `diagnostics/validate_idA0_grid.m` | `HEAVY_VALIDATION_WRAPPER` | Delegates to long validation implementation. | Keep. |
| `diagnostics/validate_idA0_score_grid.m` | `HEAVY_VALIDATION_WRAPPER` | Delegates to long validation implementation. | Keep. |
| `diagnostics/diagnose_modal_atlas.m` | `HISTORICAL_DIAGNOSTIC_WRAPPER` | Delegates to modal-atlas implementation while preserving launch folder. | Keep. |
| `diagnostics/diagnose_modal_atlas_lowfreq.m` | `HISTORICAL_DIAGNOSTIC_WRAPPER` | Delegates to low-frequency modal-atlas implementation while preserving launch folder. | Keep. |
| `diagnostics/track_raw_branch1.m` | `REPRODUCIBILITY_ENTRYPOINT` | Calls `aeExtractRawBranch1Candidate` and writes `Results/ae_iop_hgo/raw_branch1`. | Keep. |

### Long implementation targets retained by design

These long descriptive files remain because they contain implementation logic for short entrypoints.

| File | Classification | Reason | Action |
|---|---|---|---|
| `diagnostics/diagnose_acoustoelastic_iop_hgo_modal_atlas.m` | `LONG_IMPLEMENTATION_TARGET` | Implementation for `diagnose_modal_atlas`. Generates modal-family ambiguity evidence. | Keep. |
| `diagnostics/diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m` | `LONG_IMPLEMENTATION_TARGET` | Implementation for `diagnose_modal_atlas_lowfreq`. Generates low-frequency modal-atlas evidence. | Keep. |
| `diagnostics/validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid.m` | `LONG_HEAVY_VALIDATION_IMPLEMENTATION` | Implementation for `validate_idA0_grid`. Writes to clean short path. | Keep. |
| `diagnostics/validate_acoustoelastic_iop_hgo_branch_identity_score_grid.m` | `LONG_HEAVY_VALIDATION_IMPLEMENTATION` | Implementation for `validate_idA0_score_grid`. Writes to clean short path. | Keep. |

### Archived categories no longer present in examples

The following categories have been removed from `examples/acoustoelastic_iop_hgo/` after preserving their conclusions in documentation or moving implementation logic into `analysis/`:

```text
simple compatibility aliases
old branch-policy comparison diagnostics
old truncation/failure-landscape/persistence executable diagnostics
E1 direct-matrix exploratory diagnostics
E2 A0-backward/tracking exploratory diagnostics
E3 complex-C example diagnostic
raw_branch1 long implementation script
```

Relevant archive and review documents:

```text
docs/acoustoelastic_iop_hgo/legacy_entrypoint_map.md
docs/acoustoelastic_iop_hgo/code_retention_review_plan.md
docs/acoustoelastic_iop_hgo/direct_matrix_landscape_archive.md
docs/acoustoelastic_iop_hgo/a0_backward_tracking_archive.md
docs/acoustoelastic_iop_hgo/complex_c_continuation_archive.md
docs/acoustoelastic_iop_hgo/retained_diagnostic_dependency_review.md
```

### Deletion recommendation

Do not delete more files from `examples/acoustoelastic_iop_hgo/` based only on name similarity.

The next possible cleanup actions are design decisions, not mechanical cleanup:

```text
1. Decide whether to consolidate heavy validation wrappers into their short files.
2. Decide whether modal-atlas long implementations should remain script implementations or be migrated into helper functions.
3. Decide whether diagnose_grid_start_sensitivity should be promoted, migrated, archived, or deleted after solver-interface conclusions are documented.
```

Each action requires its own focused design and validation pass.

### Validation command

After any future change in this module, run:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

After raw-branch helper changes, also run:

```matlab
diagnose_modal_atlas_lowfreq
track_raw_branch1
compare_atlasA0_vs_raw_branch1
```
