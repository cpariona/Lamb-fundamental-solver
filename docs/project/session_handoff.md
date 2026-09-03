# Session handoff

Updated: 2026-09-03

## Repository state

- Default branch: `main`
- Planning branch: `planning/full-repository-restructure`
- Active branch: `restructure/phase-06-validation-surface-cleanup`
- Phase 6 base: Phase 5 commit `c70d3cc`

## Completed architecture

Phases 1-3 established one-way model dependencies, small public APIs, explicit
configuration ownership, and canonical result contracts. Phase 4 consolidated
fitting and sweep workflows. Phase 5 organized `analysis/` by workflow and
`app/` by human surface.

Phase 6 reduces examples and diagnostics to representative maintained commands,
removes completed investigation artifacts, and replaces wrapper/focused runner
graphs with six explicit tiers. The suite contains 114 tests with exactly one
direct runner owner each. Test tooling is separate and generated ownership CSVs
are absent.

## Validation boundary

Run, in order:

```matlab
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

The numerical tier is expected to report the existing
`AE IOP/HGO atlasA0 Cp snapshot changed.` difference only; its golden and
`1e-12` tolerance are unchanged. RL, mRLFE, synthetic fitting, sweep, GUI, and
Delta-Cp characterization evidence must remain independently visible.

## Next work

Phase 7 is limited to final consistency review and integration preparation.
Do not merge a partially validated restructuring into `main`.
