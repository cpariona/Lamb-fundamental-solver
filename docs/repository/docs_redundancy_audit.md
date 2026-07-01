# Documentation redundancy audit

## Scope

This audit tracks documentation files that may be duplicated, stale, overly detailed for their current role, or candidates for archival. It does not authorize deletion by itself.

The current `docs/` layout is:

```text
docs/
├── archive/
├── models/
│   ├── acoustoelastic_iop_hgo/
│   ├── mrlfe/
│   └── rayleigh_lamb/
├── repository/
└── workflows/
    ├── fitting/
    ├── gui/
    └── sweeps/
```

## Cleanup rule

Use a three-step process:

```text
1. classify
2. cross-check references
3. then archive or delete only with validation evidence
```

Do not delete documentation only because it is old, long, or rarely read.

## Classification labels

| Label | Meaning | Allowed immediate action |
|---|---|---|
| Active contract | Current user-facing or developer-facing source of truth. | Keep; shorten only if duplicated elsewhere. |
| Active index | Navigation document that points to maintained references. | Keep concise; avoid duplicating contracts. |
| Diagnostic evidence | Numerical or workflow evidence that justifies policy decisions. | Keep unless superseded and cited elsewhere. |
| Audit / retention record | Maintainer-facing cleanup or dependency record. | Keep or move to archive; do not treat as user workflow. |
| Archive candidate | Probably historical or superseded, but not yet fully checked. | Mark only; no deletion. |
| Delete candidate | Fully superseded and reference-checked. | Delete only after a focused PR and validation. |

## Current active documentation spine

### Repository-level spine

```text
docs/README.md
docs/repository/repository_structure.md
docs/repository/maintained_entrypoints.md
docs/repository/repository_hygiene_plan.md
docs/repository/naming_strategy.md
docs/repository/validation_status.md
```

`docs/repository/docs_foundation_cleanup_audit.md` remains a historical cleanup record and should not be expanded into a general policy document.

### Workflow spine

```text
docs/workflows/fitting/README.md
docs/workflows/fitting/architecture.md
docs/workflows/fitting/validation_suite.md
docs/workflows/gui/adapter_architecture.md
docs/workflows/gui/integration_audit.md
docs/workflows/sweeps/parametric_sweeps.md
docs/workflows/sweeps/sweep_tool_usage.md
```

`docs/workflows/gui/main_pending_cleanup.md` should be reviewed after GUI cleanup work. It may be an archive candidate if the pending items were closed.

### Model-family spine

```text
docs/models/rayleigh_lamb/overview.md
docs/models/rayleigh_lamb/public_api.md
docs/models/rayleigh_lamb/fitting_workflow.md

docs/models/mrlfe/README.md
docs/models/mrlfe/fitting_workflow.md
docs/models/mrlfe/atlas_policy_notes.md
docs/models/mrlfe/current_sweeps.md
docs/models/mrlfe/diagnostics/README.md

docs/models/acoustoelastic_iop_hgo/README.md
docs/models/acoustoelastic_iop_hgo/documentation_index.md
docs/models/acoustoelastic_iop_hgo/active/public_api.md
docs/models/acoustoelastic_iop_hgo/active/branch_policy.md
docs/models/acoustoelastic_iop_hgo/active/sweep_workflow.md
docs/models/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Initial redundancy findings

### Repository docs

| File | Current classification | Finding | Proposed next action |
|---|---|---|---|
| `docs/README.md` | Active index | Correct high-level index after layout move. | Keep short. |
| `docs/repository/repository_structure.md` | Active contract/index | Structure map; should remain current after layout changes. | Review for stale folders, then keep. |
| `docs/repository/maintained_entrypoints.md` | Active contract | Required by tests and useful for API surface. | Keep. |
| `docs/repository/repository_hygiene_plan.md` | Active policy | Maintains cleanup policy. | Keep; link this audit. |
| `docs/repository/docs_foundation_cleanup_audit.md` | Audit / retention record | Historical cleanup record. | Keep as audit record; avoid expanding. |

### mRLFE docs

| File | Current classification | Finding | Proposed next action |
|---|---|---|---|
| `docs/models/mrlfe/README.md` | Active index | Already concise after prior cleanup. | Keep. |
| `docs/models/mrlfe/fitting_workflow.md` | Active contract | Main FitTool route contract. | Keep. |
| `docs/models/mrlfe/atlas_policy_notes.md` | Diagnostic / policy evidence | Detailed atlas-policy evidence. | Keep; do not duplicate in README. |
| `docs/models/mrlfe/docs_cleanup_audit.md` | Audit / retention record | Historical audit sequence. | Keep; may move to archive later after no active references depend on it. |
| `docs/models/mrlfe/archive/pending_cleanup.md` | Archive record | Historical cleanup status. | Keep archived unless fully superseded and reference-checked. |

### Acoustoelastic IOP/HGO docs

| File group | Current classification | Finding | Proposed next action |
|---|---|---|---|
| `README.md` + `documentation_index.md` | Active indexes | There is intentional overlap: README is user-facing, index is curated maintainer map. | Keep both, but keep README short. |
| `active/public_api.md` | Active contract | Public API contract. | Keep. |
| `active/branch_policy.md` | Active policy | Official atlasA0 policy. | Keep. |
| `active/solver_optimization_status.md` | Active policy/evidence | May overlap with branch policy and diagnostics. | Review for shortening only after technical AE audit. |
| `active/solver_pending_work.md` | Active planning | Useful if still current. | Review after AE technical diagnostic. |
| `active/framework_hygiene_status.md` | Audit / maintenance record | Maintainer-facing, not user workflow. | Candidate to move under `audits/` after reference check. |
| `active/main_gui_integration_closure.md` | Closure record | Reads like completed phase closure, not active workflow. | Candidate to move under `archive/` after GUI reference check. |
| `audits/*.md` | Audit / retention records | Many are historical maintenance records. | Keep for now; possible future archive consolidation. |
| `diagnostics/*.md` | Diagnostic evidence | Retain until AE physical/numerical audit decides what evidence remains relevant. | Do not delete now. |
| `archive/*.md` | Archive records | Already archived. | Keep. |

## Files not recommended for deletion in this pass

Do not delete these in the current pass:

```text
docs/models/acoustoelastic_iop_hgo/diagnostics/*.md
docs/models/acoustoelastic_iop_hgo/audits/*.md
docs/models/mrlfe/docs_cleanup_audit.md
docs/repository/docs_foundation_cleanup_audit.md
docs/archive/fitting_phases/*.md
```

Reason: these files are historical or evidentiary. Some may eventually be archived or consolidated, but deletion requires exact reference checks and a focused validation pass.

## Immediate safe actions

The safe actions for this branch are limited to:

```text
1. Fix stale links created or exposed by the docs layout move.
2. Add this audit file.
3. Update indexes so future cleanup uses this audit.
```

No documentation deletion is recommended in the first redundancy-audit pass.

## Validation

For this pass, run:

```matlab
clear; clc; close all;
startup
run_all_smoke_tests
```

If any test reads documentation paths directly, update those references rather than deleting the tests.
