# Acoustoelastic IOP/HGO documentation index

This index covers the active operational contracts and the diagnostic evidence
that supports the maintained `atlasA0` policy. Completed audits, closure notes,
and retired investigations are preserved in Git history.

## Folder structure

```text
active/       current API, policy, workflow, and naming contracts
diagnostics/  repeatable diagnostic procedures and scientific evidence
```

## Reading order

For normal use:

```text
1. README.md
2. active/public_api.md
3. active/branch_policy.md
4. active/solver_optimization_status.md
5. active/solver_pending_work.md
6. active/sweep_workflow.md
7. active/fitting_workflow.md
8. active/naming_and_paths_convention.md
```

For branch-policy reasoning:

```text
1. active/branch_policy.md
2. active/solver_optimization_status.md
3. diagnostics/branch_policy_numerical_review.md
4. diagnostics/atlas_vs_raw_branch1_diagnostic.md
5. diagnostics/branch_families_diagnostic.md
6. diagnostics/identityA0_diagnostic_policy.md
```

## Active operational documentation

| Document | Role |
|---|---|
| `active/public_api.md` | Public API, workflows, diagnostics, and validation entrypoints. |
| `active/branch_policy.md` | Official atlas-A0 selection policy. |
| `active/sweep_workflow.md` | Maintained sweep workflow. |
| `active/fitting_workflow.md` | Maintained atlasA0 fitting workflow. |
| `active/naming_and_paths_convention.md` | Current names and output-path convention. |
| `active/solver_optimization_status.md` | Current solver status and ambiguity boundary. |
| `active/solver_pending_work.md` | Exact unresolved solver-side numerical work. |

## Diagnostic evidence

| Document | Role |
|---|---|
| `diagnostics/branch_policy_numerical_review.md` | Protocol for interpreting branch-policy evidence. |
| `diagnostics/atlas_vs_raw_branch1_diagnostic.md` | Official atlasA0 versus diagnostic raw-branch comparison. |
| `diagnostics/branch_families_diagnostic.md` | Competing branch-family evidence. |
| `diagnostics/atlasA0_truncation_cause_diagnostic.md` | Current truncation-cause procedure and evidence. |
| `diagnostics/identityA0_diagnostic_policy.md` | Diagnostic-only identity-A0 policy. |
| `diagnostics/identityA0_diagnostic_grid_validation.md` | Identity-A0 grid-validation procedure. |
| `diagnostics/identityA0_physical_plausibility_diagnostic.md` | Identity-A0 plausibility evidence. |
| `diagnostics/branch_identity_score_diagnostic.md` | Branch-identity score interpretation. |
| `diagnostics/branch_identity_score_grid_validation.md` | Branch-identity score grid validation. |

## Update policy

When executable AE examples or diagnostics change, update:

```text
active/public_api.md
README.md
docs/repository/maintained_entrypoints.md
```

When solver policy changes, update `active/branch_policy.md` and
`active/solver_optimization_status.md`. When fitting, sweep, or output-path
behavior changes, update the corresponding active workflow or naming contract.
