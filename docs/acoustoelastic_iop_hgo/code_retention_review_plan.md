### Acoustoelastic IOP/HGO code retention review plan

This document records the current retention policy for the acoustoelastic IOP/HGO module after the `atlasA0` policy closure and archived-diagnostic cleanup passes.

### Retention principle

Do not keep code only because it was once useful.

Do not delete code only because it is long, old, or diagnostic.

Classify each file by current role and remove archived diagnostics only in small batches after reference checks and local tests.

### Active retained layers

#### Core API and helpers

Keep the solver/model implementation and reusable helpers under:

```text
models/acoustoelastic_iop_hgo/**
analysis/acoustoelastic_iop_hgo/**
```

Important retained helpers include:

```matlab
aeOutputFolder
aeResolveResultFile
aeRunSweep
aeSummarizeSweep
aeScoreBranchIdentityCandidates
aeBuildIdentityA0DiagnosticBranch
aeDiagnoseAtlasA0TruncationCause
aeAnalyzeBranchPersistenceCandidates
aeRefineAtlasA0BranchPersistence
aeClassifyAmbiguityRegime
```

#### Public workflows

```matlab
run_atlas_branch
sweep_iop
sweep_mu
```

#### Maintained diagnostic evidence

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
```

#### Regression tests

```matlab
test_acoustoelastic_iop_hgo_branch_policy_aliases
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
test_acoustoelastic_iop_hgo_short_entrypoints
test_acoustoelastic_iop_hgo_branch_persistence_refinement
test_ae_analyze_truncation_recovery
```

### Historical diagnostic retention matrix

| Entrypoint | Classification | Rationale | Action |
|---|---|---|---|
| `compare_branch_policies` | `DELETED_AFTER_TESTS` | Branch-policy selection is closed; `atlasA0` policy is documented. | Removed with aliases. |
| `diagnose_branch_policy` | `DELETED_AFTER_TESTS` | Thin alias around removed branch-policy comparison. | Removed with legacy alias. |
| `diagnose_atlas_resolution` | `DELETED_AFTER_TESTS` | Resolution-sensitivity conclusions are retained in `docs/acoustoelastic_iop_hgo/atlasA0_truncation_cause_diagnostic.md`; executable batch was expensive and no longer part of the maintained surface. | Removed with legacy alias. |
| `diagnose_idA0_score` | `KEEP_FOR_THESIS_ANALYSIS` | Helps explain identity-score behavior and diagnostic-only branches. | Keep outside primary maintained list. |
| `validate_idA0_grid` | `KEEP_FOR_THESIS_ANALYSIS` | Heavy grid validation for `identityA0Diagnostic` official-output preservation. | Keep outside routine workflow. |
| `validate_idA0_score_grid` | `KEEP_FOR_THESIS_ANALYSIS` | Heavy score-grid validation for branch-identity scoring. | Keep outside routine workflow. |
| `diagnose_modal_atlas` | `KEEP_FOR_THESIS_ANALYSIS` | Useful evidence for modal-family ambiguity. | Keep outside routine workflow. |
| `diagnose_modal_atlas_lowfreq` | `KEEP_FOR_THESIS_ANALYSIS` | Useful low-frequency modal-family interpretation. | Keep outside routine workflow. |
| `track_raw_branch1` | `RETAIN_FOR_COMPARISON_REPRODUCIBILITY` | Produces `Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv`, which is the input consumed by `compare_atlasA0_vs_raw_branch1`. | Keep until the maintained comparison no longer depends on this generated curve. |
| `diagnose_truncation_cases` | `DELETED_AFTER_TESTS` | Superseded by `diagnose_atlas_truncation` and retained truncation docs. | Removed with legacy implementation. |
| `diagnose_landscape_failure` | `DELETED_AFTER_TESTS` | Superseded by `diagnose_atlas_truncation` and retained failure-landscape docs. | Removed with legacy implementation. |
| `diagnose_branch_persistence` | `DELETED_AFTER_TESTS` | Executable diagnostic superseded; reusable helper behavior remains tested. | Removed with legacy implementation. |

### Removed archived diagnostics

The following historical executable diagnostics were removed from `examples/acoustoelastic_iop_hgo/diagnostics/`:

```text
compare_branch_policies.m
compare_acoustoelastic_iop_hgo_branch_policies.m
diagnose_branch_policy.m
diagnose_acoustoelastic_iop_hgo_branch_policy.m
diagnose_atlas_resolution.m
diagnose_acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity.m
diagnose_truncation_cases.m
diagnose_acoustoelastic_iop_hgo_truncation_cases.m
diagnose_landscape_failure.m
diagnose_acoustoelastic_iop_hgo_failure_landscape.m
diagnose_branch_persistence.m
diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement.m
```

Replacement or retained evidence:

```text
docs/acoustoelastic_iop_hgo/phase_closure_atlasA0.md
docs/acoustoelastic_iop_hgo/solver_optimization_status.md
diagnose_atlas_truncation
docs/acoustoelastic_iop_hgo/atlasA0_truncation_validation.md
docs/acoustoelastic_iop_hgo/atlasA0_truncation_cause_diagnostic.md
docs/acoustoelastic_iop_hgo/branch_persistence_refinement.md
```

The branch-persistence executable diagnostic was removed, but the reusable helper behavior remains in:

```matlab
aeAnalyzeBranchPersistenceCandidates
aeRefineAtlasA0BranchPersistence
test_acoustoelastic_iop_hgo_branch_persistence_refinement
```

### Raw branch tracker retention note

`compare_atlasA0_vs_raw_branch1` is maintained diagnostic evidence. It reads:

```text
Results/ae_iop_hgo/raw_branch1/raw_branch1_curve.csv
```

`track_raw_branch1` is the retained generator for that file. It remains historical and diagnostic-only, but should not be deleted while `compare_atlasA0_vs_raw_branch1` depends on the raw-branch curve input.

### Test policy

`run_all_smoke_tests` verifies only the maintained API, public workflows, maintained diagnostic evidence, and tests.

`test_acoustoelastic_iop_hgo_short_entrypoints` requires maintained short entrypoints and may optionally validate retained historical wrappers if present.

For every future deletion batch, run:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

### Current recommendation

Do not delete `track_raw_branch1` yet.

The next cleanup target should be selected from the remaining retained historical diagnostics only after focused reference checks and confirmation that the relevant conclusions are represented in retained documentation.
