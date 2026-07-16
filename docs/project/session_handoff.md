# Session handoff

Updated: 2026-07-15

## Current operating contract

Start with:

```text
docs/repository/repository_structure.md
docs/repository/naming_strategy.md
docs/repository/maintained_entrypoints.md
docs/repository/validation_status.md
```

Then read the relevant model or workflow contract. Maintained code and tests
take precedence over operational context.

## Standard validation

```matlab
clear functions
rehash toolboxcache
startup

run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
```

Use the focused and extended commands listed in
`docs/repository/validation_status.md` when the changed surface requires them.

## Open product work

The bounded solver-side AE refinement question is documented in
`docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md`. It is not a
repository-hygiene task and must not be addressed through display smoothing.

No completed cleanup narrative or branch-specific instruction is maintained
in this handoff.
