# Project handoff index

## Purpose

`docs/project/` contains the operational project state used to start and close
development sessions. It does not replace technical contracts in
`docs/repository/`, `docs/workflows/`, `docs/models/`, or accepted ADRs.

Use this folder to answer:

- what is active now;
- what was last completed;
- what remains open;
- what to read next.

## Start of a session

Read these in order:

1. `docs/project/active_context.md`
2. `docs/project/session_handoff.md`
3. `docs/repository/repository_structure.md`
4. `docs/repository/naming_strategy.md`
5. task-specific documentation

Then confirm the current branch, last known good commit, active constraints,
and next action before modifying files.

For repository-cleanup tasks, also read before changing anything:

```text
docs/repository/maintained_entrypoints.md
docs/repository/validation_status.md
```

For test-suite audit or cleanup tasks, also read:

```text
docs/repository/test_runner_ownership.md
tests/README.md
docs/project/templates/codex_task.md
```

A cleanup audit is a candidate inventory, not permission for bulk deletion.
Codex or any other agent must create a dedicated feature branch from updated
`origin/main`, verify dependencies for every candidate, and preserve maintained
behavior.

## End of a session

Update `docs/project/session_handoff.md` at the end of every relevant
development session.

Update `docs/project/active_context.md` only when the global state, current
phase, or cross-cutting limitations change.

Create or modify ADRs only when a durable architectural decision is made.

For cleanup sessions, update existing durable contracts and the handoff. Use Git
history for task-specific deletion evidence instead of adding a permanent phase
report.

## Document authority

When documents disagree, use this order:

1. maintained code and tests;
2. active `repository/`, `workflows/`, and `models/` contracts;
3. accepted ADRs;
4. `docs/project/active_context.md`;
5. `docs/project/session_handoff.md`;
6. audits and diagnostic evidence;
7. `archive/`.

If the handoff contradicts an active contract, the contract prevails. If an old
audit contradicts current code or tests, do not treat the audit as current
state.

## Topic-specific reading

| Topic | Start with |
| --- | --- |
| Repository cleanup | `docs/repository/maintained_entrypoints.md`; `docs/repository/validation_status.md`; `docs/repository/repository_structure.md` |
| Test-suite ownership | `docs/repository/test_runner_ownership.md`; `tests/README.md`; `docs/repository/maintained_entrypoints.md`; `docs/repository/validation_status.md` |
| GUI | `docs/workflows/gui/adapter_architecture.md`; `docs/architecture/execution_profiles_surface_integration.md` |
| Fitting | `docs/workflows/fitting/architecture.md`; `docs/workflows/fitting/validation_suite.md` |
| Sweeps | `docs/workflows/sweeps/parametric_sweeps.md`; `docs/workflows/sweeps/sweep_tool_usage.md` |
| Execution profiles | `docs/architecture/execution_profiles_surface_integration.md`; `docs/validation/execution_profile_end_to_end_validation.md` |
| Rayleigh-Lamb | `docs/models/rayleigh_lamb/overview.md`; `docs/models/rayleigh_lamb/public_api.md`; `docs/models/rayleigh_lamb/fitting_workflow.md` |
| mRLFE | `docs/models/mrlfe/README.md`; `docs/models/mrlfe/public_api.md`; `docs/models/mrlfe/production_core.md`; `docs/models/mrlfe/fitting_workflow.md` |
| AE IOP/HGO | `docs/models/acoustoelastic_iop_hgo/README.md`; `docs/models/acoustoelastic_iop_hgo/active/public_api.md`; `docs/models/acoustoelastic_iop_hgo/active/branch_policy.md` |
