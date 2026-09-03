# Validation status

## Maintained commands

```matlab
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

The suite contains 114 tests with one explicit owner each. There are exactly
six runner implementations, no root-level wrappers, no dynamic runner
dispatcher, and no generated test-inventory CSVs.

## Phase 6 validation

The Phase 6 closeout on branch
`restructure/phase-06-validation-surface-cleanup` exercised all six tiers after
reducing examples, diagnostics, and test orchestration:

- repository hygiene, quick contracts, quick smoke, extended integration, and
  performance/benchmarks passed;
- numerical regression completed RL, mRLFE, result-schema, policy, and AE
  synthetic evidence before stopping at the known AE snapshot;
- AE synthetic atlasA0 fitting recovered `mu` with relative error
  `5.06201e-08`;
- mRLFE production covered 24 Fast and 6 Dense cases with maximum absolute
  Delta-Cp `0 m/s`, maximum relative difference `0`, and identical masks;
- FitTool, SweepTool, and Main GUI each covered 24 cases with maximum absolute
  Delta-Cp `0 m/s`, maximum relative difference `0`, and identical masks;
- Main GUI versus SweepTool and FitTool both reported maximum Cp difference
  `0`;
- mRLFE fitting retained objective evaluation counts `11`, `8`, `7`, and `7`;
- the performance layer passed with production medians from `0.8465 s` to
  `0.8885 s`; these timings are descriptive machine-local evidence.

The lightweight numerical regression retains one known baseline failure:
`AE IOP/HGO atlasA0 Cp snapshot changed.` Phase 6 does not update that golden,
change scientific code, or relax its `1e-12` tolerance. The runner places this
known snapshot test last so the other numerical evidence is produced first.

## Permanent repository contracts

- only the documented source, application, analysis, example, test, and docs
  areas are tracked;
- production and analysis code do not depend on examples or tests;
- model code does not depend on analysis or application code;
- Markdown links and documented exact paths resolve;
- every maintained MATLAB entrypoint has one tracked definition;
- generated results, figures, MAT files, CSV inventories, and diagnostic
  scratch artifacts are not tracked;
- every test is named by exactly one of the six canonical runners.

## Compatibility debt

| Exception | Owner | Reason retained | Removal condition |
| --- | --- | --- | --- |
| `robustness` request/control alias | app profile normalization | existing callers may still emit the established field | remove after all producers use only `executionProfile` and external migration is complete |
| `aeResolveResultFile` legacy-result fallback | AE analysis IO | permits explicit reading of previously generated workspaces | remove after required external inputs have migrated to canonical result roots |

No additional compatibility alias is authorized by this table.
