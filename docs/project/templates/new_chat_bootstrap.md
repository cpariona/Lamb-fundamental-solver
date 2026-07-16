# New chat bootstrap

Use this template when starting a new technical planning chat without a selected
implementation objective.

## Paste-ready prompt

```text
I want to continue technical work in the repository:

cpariona/Lamb-fundamental-solver

The latest repository-wide cleanup, structure, naming, documentation, and
hygiene work was merged into main through PR #119. I have not selected the next
technical objective yet.

In this conversation I want to:

1. recover the current project state correctly;
2. identify open technical areas;
3. distinguish completed work from active or provisional work;
4. select the next objective;
5. define a branch and concrete scope only after that selection.

Before proposing changes:

1. Verify the real repository state and confirm that local main matches
   origin/main.
2. Read, in this order:

- docs/project/README.md
- docs/project/active_context.md
- docs/project/session_handoff.md
- docs/repository/repository_structure.md
- docs/repository/naming_strategy.md

3. Read only the additional model, workflow, architecture, or validation
   contracts required to understand the open areas.
4. Summarize:

- current project state;
- recently completed capabilities;
- known cross-cutting limitations;
- current architectural decisions;
- open technical areas;
- possible next objectives;
- risks and dependencies of each option.

Do not modify files or create branches yet.

After the summary, recommend at most three possible objectives, ordered by
priority, and wait for my decision.

Subsequent working rules:

- one new branch per task;
- start from updated origin/main;
- never work directly on main;
- keep changes small and localized;
- preserve contracts, naming, structure, and ownership;
- define validation before implementation;
- do not open a PR until validation is complete;
- I will perform the merge manually.
```

## Required reading

The persistent context files are:

1. `docs/project/README.md`
2. `docs/project/active_context.md`
3. `docs/project/session_handoff.md`
4. `docs/repository/repository_structure.md`
5. `docs/repository/naming_strategy.md`

Then read task-specific documents only as needed:

- GUI: `docs/workflows/gui/adapter_architecture.md`
- Fitting: `docs/workflows/fitting/architecture.md`
- Sweeps: `docs/workflows/sweeps/parametric_sweeps.md`
- Execution profiles: `docs/architecture/execution_profiles_surface_integration.md`
- Model-specific work: the relevant `docs/models/<model_family>/` entrypoint
- Validation and compatibility debt: `docs/repository/validation_status.md`

Do not paste long prior conversations. Use the active context, handoff, and
linked contracts as the project memory.
