# Active project context

Last reviewed: 2026-07-15
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Implementation branch: `refactor/normalize-maintained-naming`
Phase 1 source: `a126cd41f0040b922b40e851957af0ada71d3023`
Phase 2 source: `6a59d9952af3d8bf848eba231e75ddf2bde0e70d`
Origin main: `bf79cb468de66b76dbfe0e52ef8389e9ca0d025e`

## Current state

Repository naming Phase 3 is complete on top of the Phase 2 layer-ownership
head. Maintained examples and diagnostics use verb-based canonical names,
mRLFE model internals use the `mrlfe*` prefix, and task-oriented route cleanup
test names now express continuing route-integrity invariants.

The AE diagnostic short names are the substantive implementations; no
forwarding aliases remain. The established long AE scientific/programmatic
helpers remain explicit naming exceptions. Execution-profile helper names
remain unchanged because they already expose model or GUI ownership.

`docs/repository/naming_strategy.md` is the authoritative naming contract, and
`test_repository_naming_contract` enforces filename/function agreement,
forbidden example terms, prefix rules, documented definitions, and removed-name
absence.

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

- Preserve solver mathematics, numerical presets, tolerances, and public data schemas.
- Use Git history for old command names and completed investigations.
- Do not add compatibility aliases without the documented external-use exception.
- Keep the Phase 2 architectural layers unchanged.
