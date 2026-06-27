# AE IOP/HGO diagnostic documentation

This folder contains diagnostic evidence that supports, but does not itself define, the maintained AE IOP/HGO solver policy.

## Branch-policy diagnostics

```text
branch_policy_numerical_review.md
atlas_vs_raw_branch1_diagnostic.md
branch_families_diagnostic.md
atlasA0_truncation_cause_diagnostic.md
atlasA0_truncation_validation.md
```

The numerical review protocol is:

```text
branch_policy_numerical_review.md
```

Use it to interpret `atlasA0`, `identityA0Diagnostic`, `raw_branch1`, and `branch_families` evidence without prematurely changing the production solver policy.

## Identity-A0 diagnostics

```text
identityA0_diagnostic_policy.md
identityA0_diagnostic_grid_validation.md
identityA0_physical_plausibility_diagnostic.md
branch_identity_score_diagnostic.md
branch_identity_score_grid_validation.md
```

## Wrapper and output diagnostics

```text
modal_atlas_wrapper_review.md
validation_grid_wrapper_review.md
official_cp_mutation_review.md
output_path_audit.md
retained_diagnostic_dependency_review.md
```

## Policy

Diagnostics may be detailed and historical. They should not be presented as the first entrypoint for normal users. If a diagnostic conclusion becomes part of maintained behavior, summarize that conclusion in `../active/branch_policy.md` or `../active/solver_optimization_status.md`.
