# Codex task template

## Repository

`cpariona/Lamb-fundamental-solver`

## Branch

- Do not work directly on `main`.
- Use one feature branch per task.
- Base the branch on updated `origin/main` unless instructed otherwise.

## Objective

Describe the concrete outcome.

## Required reading

- `docs/project/README.md`
- `docs/project/active_context.md`
- `docs/project/session_handoff.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- Task-specific contracts:

## Allowed scope

List the folders and files that may change.

## Forbidden changes

- No direct work on `main`.
- No PR or merge unless explicitly requested.
- No broad restructuring outside the objective.
- No solver, GUI, or validation behavior changes unless the task requires them.
- No documentation deletion without reference checks and validation.

## Implementation requirements

- Preserve repository structure and naming contracts.
- Prefer existing adapters, helpers, and model APIs.
- Keep changes focused.
- Do not claim tests passed unless they were executed.

## Validation

- Run focused tests or checks appropriate to the changed files.
- For documentation-only changes, run `git diff --check` and route/link searches.
- Record exact commands and results.

## Git checks

```bash
git status -sb
git diff --stat
git diff --check
git diff
```

## Commit/push rules

- Use one or two coherent commits.
- Report exact SHAs.
- Push only if requested.
- Do not open a PR or merge unless explicitly requested.

## Expected final report

- Branch and base SHA.
- Commits and final SHA.
- Files created and changed.
- Validation executed.
- Known open issues.
- Final working tree status.
