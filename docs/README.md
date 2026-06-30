# Documentation index

This folder is organized by active documentation, model-family documentation, and archived implementation history.

## Active repository-level references

```text
docs/repository_structure.md
docs/naming_strategy.md
docs/validation_status.md
docs/maintained_entrypoints.md
docs/repository_hygiene_plan.md
docs/docs_foundation_cleanup_audit.md
```

## Active topic folders

```text
docs/fitting/
docs/gui/
docs/sweeps/
docs/rayleigh_lamb/
docs/mrlfe/
docs/acoustoelastic_iop_hgo/
```

## Active fitting documentation

```text
docs/fitting/README.md
docs/fitting/architecture.md
docs/fitting/validation_suite.md
docs/mrlfe/fitting_workflow.md
docs/rayleigh_lamb/fitting_workflow.md
docs/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Active GUI documentation

```text
docs/gui/adapter_architecture.md
docs/gui/integration_audit.md
docs/gui/main_pending_cleanup.md
docs/acoustoelastic_iop_hgo/active/main_gui_integration_closure.md
```

## Active sweep documentation

```text
docs/sweeps/parametric_sweeps.md
docs/sweeps/sweep_tool_usage.md
docs/mrlfe/current_sweeps.md
docs/acoustoelastic_iop_hgo/active/sweep_workflow.md
```

## Model-family documentation

```text
docs/rayleigh_lamb/overview.md
docs/rayleigh_lamb/public_api.md
docs/rayleigh_lamb/fitting_workflow.md
docs/mrlfe/README.md
docs/acoustoelastic_iop_hgo/README.md
docs/acoustoelastic_iop_hgo/documentation_index.md
```

## Cleanup planning

```text
docs/repository_hygiene_plan.md
docs/docs_foundation_cleanup_audit.md
```

Use these documents before deleting, archiving, or consolidating documentation, examples, diagnostics, or tests.

## Archived documentation

```text
docs/archive/fitting_phase_logs.md
docs/archive/fitting_phases/
docs/acoustoelastic_iop_hgo/archive/
```

Historical phase logs and exploratory notes are retained for traceability. They are not active API or workflow references.

## Cleanup policy

Root-level `docs/*.md` should be limited to repository-wide references and this index. Topic-specific documents should live under their topic folder. Historical implementation logs should live under `docs/archive/` or the model-specific `archive/` folder.
