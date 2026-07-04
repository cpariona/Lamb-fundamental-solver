# Architecture decision records

This folder records durable cross-cutting architectural decisions.

An ADR is a short decision record. It explains the context, the chosen rule, the
consequences, rejected alternatives, and links to the active contracts or
validation evidence.

## When to create an ADR

Create an ADR when a decision affects multiple modules, future feature work, or
the interpretation of existing contracts.

## When not to create an ADR

Do not create an ADR for ordinary implementation details, temporary session
state, historical logs, validation output, or topic-specific documentation that
belongs under `docs/workflows/` or `docs/models/`.

## Status values

- Proposed
- Accepted
- Superseded
- Rejected

## ADR format

```markdown
# ADR-XXX: Title

Status:
Date:
Last reviewed:

## Context

## Decision

## Consequences

## Alternatives

## References
```

## Index

| ADR | Status | Decision |
| --- | --- | --- |
| `ADR-001-gui-adapter-boundary.md` | Accepted | GUI surfaces delegate through app adapters and do not implement solver physics. |
| `ADR-002-execution-profile-semantics.md` | Accepted | `executionProfile` expresses numerical effort and robustness, separate from route, branch, optimizer, and physical settings. |
