# Active project context

Last reviewed: 2026-07-15
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Implementation branch: `refactor/mrlfe-line-and-repository-cleanup`
Audit head: `2cfe264625ab3f7485a06389d315190fe9a7b67e`

## Current state

The audited mRLFE architecture and repository-density cleanup is implemented.
`mrlfeSolve` remains the sole maintained public solver. Generic request
construction is centralized in `mrlfeBuildPublicSolveRequest`; GUI, SweepTool,
and FitTool retain thin translators and unchanged public behavior.

Public result fields own maintained facts. Raw internals are confined to the
explicit `debug.rawInternalResult` compatibility boundary, with the previous
diagnostics field retained as an alias. mRLFE owns its internal configuration;
Rayleigh-Lamb remains the intentional physical seed provider.

## Maintained references

```text
docs/models/mrlfe/public_api.md
docs/models/mrlfe/production_core.md
docs/models/mrlfe/fitting_workflow.md
docs/architecture/execution_profiles_surface_integration.md
docs/repository/mrlfe_line_and_repository_cleanup_report.md
```

## Constraints

- Preserve solver mathematics, presets, policies, numerical outputs, and
  surface defaults.
- Treat code/tests and the maintained contracts above as authoritative.
- Historical audits and retired diagnostics are available in Git history or
  the startup-excluded diagnostic archive, not on the active contract surface.
