# Project context

`docs/project/` contains small operational context and reusable task templates.
It does not own technical contracts.

## Session start

Read:

1. `active_context.md`
2. `session_handoff.md`
3. `../repository/repository_structure.md`
4. `../repository/naming_strategy.md`
5. the relevant model or workflow document

Confirm the branch, base commit, objective, constraints, and validation scope
before modifying files.

## Session closeout

Update `session_handoff.md` only with current operating information. Update
`active_context.md` only when global architecture, public commands, or bounded
product work changes. Use an ADR only for a durable cross-cutting decision.

Completed migrations, cleanup evidence, timing snapshots, and branch-specific
instructions belong in Git or pull-request history.

## Authority

When sources disagree, use this order:

1. maintained code and tests;
2. repository, workflow, and model contracts;
3. accepted ADRs;
4. `active_context.md`;
5. `session_handoff.md`;
6. repeatable diagnostic evidence.

## Topic routing

| Topic | Authoritative start |
| --- | --- |
| Structure and dependencies | `../repository/repository_structure.md` |
| Naming | `../repository/naming_strategy.md` |
| Maintained entrypoints | `../repository/maintained_entrypoints.md` |
| Validation | `../repository/validation_status.md` |
| Tests | `../repository/test_suite_final_architecture.md` and `../repository/test_runner_ownership.md` |
| GUI | `../workflows/gui/adapter_architecture.md` |
| Fitting | `../workflows/fitting/architecture.md` |
| Sweeps | `../workflows/sweeps/parametric_sweeps.md` |
| Execution profiles | `../architecture/execution_profiles_surface_integration.md` |
| Rayleigh-Lamb | `../models/rayleigh_lamb/overview.md` |
| mRLFE | `../models/mrlfe/README.md` |
| AE IOP/HGO | `../models/acoustoelastic_iop_hgo/README.md` |
