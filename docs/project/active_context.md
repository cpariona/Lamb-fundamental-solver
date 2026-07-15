# Active project context

Last reviewed: 2026-07-15
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Implementation branch: `refactor/correct-repository-layer-structure`
Phase 1 source: `a126cd41f0040b922b40e851957af0ada71d3023`
Origin main: `bf79cb468de66b76dbfe0e52ef8389e9ca0d025e`

## Current state

Repository structure Phase 2 is complete on top of the Phase 1 deletion head.
The maintained layers remain `analysis/`, `app/`, `docs/`, `examples/`,
`models/`, and `tests/`; no root-level `shared/` source layer was created.

`aeRunSweep` is now owned by AE analysis. Cross-model sweep infrastructure is
grouped under `analysis/sweeps/`. Model-specific profile/surface translation is
owned by `app/adapters/`; FitTool visual construction is under `app/fitting/`;
interactive sweep UI is under `app/sweep/`. MATLAB command names remain stable
through recursive startup paths, and no path-only wrappers were added.

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
- Phase 3 naming normalization has not started.
- Keep retained long AE diagnostic implementation names unchanged until a
  dedicated naming task authorizes renames.
