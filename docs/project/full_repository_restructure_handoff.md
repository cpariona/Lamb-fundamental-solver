# Full repository restructure handoff

The restructuring campaign targets one obvious architecture, one canonical
owner per responsibility, small public APIs, explicit configuration and result
contracts, and scientific behavior protected independently from repository
shape.

## Completed phases

1. Model boundaries and one-way dependencies.
2. Canonical APIs and configuration ownership.
3. Canonical scientific result contracts.
4. Shared fitting and sweep orchestration.
5. Physical organization of analysis and application code.
6. Representative examples/diagnostics and six-tier validation surface.

The six validation commands are documented in
`../repository/test_suite_final_architecture.md`. The current repository state
and next-phase boundary are documented in `active_context.md` and
`session_handoff.md`.

## Permanent rules

- GUI coordinates and presents; models calculate.
- Production does not depend on examples, diagnostics, or tests.
- Official outputs, quality, diagnostics, and effective configuration remain
  distinct.
- Obsolete implementations and completed investigations belong in Git history.
- Numerical baselines are not updated to make structural refactors pass.
- Performance evidence is descriptive and hardware-independent.
- Investigation-only files must start with `% TEMPORARY_DIAGNOSTIC` and be
  removed or explicitly promoted before integration.

Phase 7 may close remaining documentation/path consistency and prepare review;
it may not silently broaden APIs or alter scientific policy.
