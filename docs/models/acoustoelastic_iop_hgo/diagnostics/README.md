# AE IOP/HGO diagnostic documentation

This folder contains diagnostic evidence that supports, but does not itself define, the maintained AE IOP/HGO solver policy.

## Maintained evidence

| Document | Executable evidence | Unique current value |
| --- | --- | --- |
| `atlas_vs_raw_branch1_diagnostic.md` | `compare_atlasA0_vs_raw_branch1`, `validate_atlas_raw_grid`, `diagnose_raw_branch_corner` | Defines the raw-branch comparison and difficult-corner interpretation. |
| `branch_families_diagnostic.md` | `diagnose_branch_families` | Records why coverage alone does not resolve modal-family ambiguity. |
| `atlasA0_truncation_cause_diagnostic.md` | `diagnose_atlas_truncation` | Distinguishes terminal truncation from internal gaps and defines causal outputs. |
| `identityA0_diagnostic_policy.md` | solver option plus focused test | Defines the diagnostic-only output schema and safety rule. |
| `branch_identity_score_diagnostic.md` | `diagnose_idA0_score` | Defines the score components and candidate classes. |
| `branch_identity_score_grid_validation.md` | `validate_idA0_score_grid` | Preserves the 110-case score-validation interpretation. |
| `identityA0_diagnostic_grid_validation.md` | `validate_idA0_grid` | Preserves official-field parity and candidate-extension evidence. |
| `identityA0_physical_plausibility_diagnostic.md` | `diagnose_idA0_plausibility` | Defines plausibility classes and the low-mu/high-IOP caution boundary. |

## Policy

These documents are retained only because each has a surviving repeatable owner
and a distinct interpretation. The production policy is defined only in
`../active/branch_policy.md`.

The diagnostic identity builder and scorer are located under
`models/acoustoelastic_iop_hgo/results/`. This placement removes the former
production-model dependency on `analysis/` while retaining their diagnostic
classification. They are executed only for an explicit
`identityA0Diagnostic` request and cannot replace official `atlasA0` output.
