# ADR-001: GUI adapter boundary

Status: Accepted
Date: 2026-07-04
Last reviewed: 2026-07-04

## Context

The repository has interactive GUI surfaces for main forward modeling, sweeps,
and fitting. Active workflow documentation already defines app-layer adapters
and maintained model APIs as the boundary between GUI interaction and numerical
model behavior.

## Decision

GUI surfaces orchestrate input and presentation.

They call app-layer dispatchers and adapters.

They do not implement solver physics or fitting algorithms directly.

Example scripts are not backend dependencies.

## Consequences

- `FitTool_GUI`, `SweepTool_GUI`, and Main GUI remain interaction surfaces.
- Solver changes occur in model layers.
- Adapters normalize requests and results.
- Tests should reflect app and model boundaries.

## Alternatives

- Put fitting or solver behavior directly in GUI callbacks.
- Use example scripts as GUI backends.
- Treat diagnostic-only branches as production GUI outputs.

These alternatives are rejected because they blur ownership and make validation
harder to maintain.

## References

- `docs/repository/repository_structure.md`
- `docs/workflows/gui/adapter_architecture.md`
- `docs/workflows/fitting/architecture.md`
