# Active project context

Last reviewed: 2026-07-15
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Implementation branch: `cleanup/remove-obsolete-repository-content`
Base: `bf79cb468de66b76dbfe0e52ef8389e9ca0d025e`

## Current state

Repository cleanup Phase 1 is complete. The branch removes 37 tracked files and
6,241 physical lines while keeping the top-level `analysis/`, `app/`, `docs/`,
`examples/`, `models/`, and `tests/` organization unchanged.

Completed audits, timing snapshots, archive scripts, one obsolete mRLFE policy
diagnostic, four AE forwarding aliases, superseded diagnostic helpers, and
verified orphan utilities are absent. Retained AE diagnostic implementations
keep their existing names. No maintained solver, GUI, fitting, sweep, or test
runner entrypoint was renamed.

## Maintained references

```text
docs/repository/repository_structure.md
docs/repository/naming_strategy.md
docs/repository/maintained_entrypoints.md
docs/repository/validation_status.md
docs/repository/test_suite_final_architecture.md
docs/repository/test_runner_ownership.md
```

## Constraints

- Preserve solver mathematics, numerical presets, tolerances, and public APIs.
- Use Git history for completed audits and investigations.
- Phase 2 structural moves and Phase 3 naming normalization have not started.
- Keep retained long AE diagnostic implementation names unchanged until a
  dedicated naming task authorizes renames.
