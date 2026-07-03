# Documentation index

This folder is organized by active documentation, model-family documentation, and archived implementation history.

## Active repository-level references

```text
docs/repository/repository_structure.md
docs/repository/naming_strategy.md
docs/repository/validation_status.md
docs/repository/maintained_entrypoints.md
docs/repository/matlab_dependency_audit.md
docs/repository/repository_hygiene_plan.md
docs/repository/docs_foundation_cleanup_audit.md
```

## Active topic folders

```text
docs/workflows/fitting/
docs/workflows/gui/
docs/workflows/sweeps/
docs/models/rayleigh_lamb/
docs/models/mrlfe/
docs/models/acoustoelastic_iop_hgo/
```

## Active fitting documentation

```text
docs/workflows/fitting/README.md
docs/workflows/fitting/architecture.md
docs/workflows/fitting/validation_suite.md
docs/models/mrlfe/fitting_workflow.md
docs/models/rayleigh_lamb/fitting_workflow.md
docs/models/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Active GUI documentation

```text
docs/workflows/gui/adapter_architecture.md
docs/workflows/gui/integration_audit.md
docs/workflows/gui/main_pending_cleanup.md
docs/workflows/gui/mrlfe_atlas_policy_integration.md
docs/architecture/execution_profiles_surface_integration.md
docs/validation/execution_profile_end_to_end_validation.md
docs/validation/execution_profile_manual_validation.md
docs/validation/execution_profile_diagnostics_validation.md
docs/validation/mrlfe_execution_profile_benchmark.md
```

## Active sweep documentation

```text
docs/workflows/sweeps/parametric_sweeps.md
docs/workflows/sweeps/sweep_tool_usage.md
docs/models/mrlfe/current_sweeps.md
docs/models/acoustoelastic_iop_hgo/active/sweep_workflow.md
```

## Model-family documentation

```text
docs/models/rayleigh_lamb/overview.md
docs/models/rayleigh_lamb/public_api.md
docs/models/rayleigh_lamb/fitting_workflow.md
docs/models/mrlfe/README.md
docs/models/mrlfe/fitting_workflow.md
docs/models/mrlfe/fittool_grid_path_sensitivity.md
docs/models/mrlfe/current_sweeps.md
docs/models/mrlfe/diagnostics/README.md
docs/models/mrlfe/diagnostics/tracker_diagnostic_summary.md
docs/models/mrlfe/atlas_policy_notes.md
docs/models/acoustoelastic_iop_hgo/README.md
docs/models/acoustoelastic_iop_hgo/documentation_index.md
```

## Cleanup planning

```text
docs/architecture/execution_profiles_cleanup.md
docs/repository/repository_hygiene_plan.md
docs/repository/docs_foundation_cleanup_audit.md
docs/repository/docs_redundancy_audit.md
docs/repository/matlab_dependency_audit.md
docs/models/mrlfe/docs_cleanup_audit.md
```

Use these documents before deleting, archiving, or consolidating documentation, examples, diagnostics, or tests.

## Archived documentation

```text
docs/archive/fitting_phase_logs.md
docs/archive/fitting_phases/
docs/models/mrlfe/archive/
docs/models/acoustoelastic_iop_hgo/archive/
```

Historical phase logs and exploratory notes are retained for traceability. They are not active API or workflow references.

## Cleanup policy

Root-level `docs/*.md` should be limited to repository-wide references and this index. Topic-specific documents should live under their topic folder. Historical implementation logs should live under `docs/archive/` or the model-specific `archive/` folder.
