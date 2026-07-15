# Final MATLAB test-suite architecture

Last reviewed: 2026-07-15. Base: `1b31814b8c5e7ff1b8cb68829b919585eb893ac1`.

## Goals and ownership

Every maintained test has exactly one direct canonical owner. Aggregates call
owners, not sibling tests. Runtime is descriptive evidence and never a failure
threshold. Public wrappers and historical commands remain compatible.

Final static state: 159 tracked MATLAB files, 104 tests, 43 runner
implementations, 9 wrappers, 3 helpers, 205 graph edges, 104 canonical owners,
0 manual-only tests, 0 unowned tests, 0 multiple owners, 0 sibling direct
overlaps, and 0 runner cycles.

## Tiers

| Tier | Command | Tests | Policy |
| --- | --- | ---: | --- |
| Quick contract | `run_quick_contract_tests` | 14 | paths, schemas, metadata, invalid inputs, imports, pure helpers |
| Quick smoke | `run_quick_smoke_tests` | 47 | quick contracts plus bounded GUI/AE/mRLFE representative execution |
| Numerical regression | `run_numerical_regression_tests` | 14 | deterministic numerical evidence without multi-profile preset characterization or mRLFE fitting-grid studies |
| Extended integration | `run_extended_integration_tests` | 43 | matrices, fitting validation, consumer characterization, and moved mRLFE fitting/preset coverage |
| Performance | `run_performance_and_benchmark_tests` | 2 | descriptive timing only |
| Diagnostics | `run_execution_profile_diagnostics_tests` | 2 | formatting plus bounded mRLFE benchmark contract |

Repeated setup is guarded with `isempty(which('mrlfeSolve'))`: a cold direct
command still runs `startup`, while nested runners and tests reuse the active
repository path. Assertions, solver grids, tolerances, physics, and production
defaults are unchanged.

## Public and historical commands

The nine compatibility wrappers and standalone `run_main_gui_export_tests`
remain public. `run_all_smoke_tests` remains the historical broad aggregate; it
is not the quick gate. Its 54-test transitive coverage is unchanged. Focused
historical execution-profile aggregate names also remain resolvable.

## Runtime evidence

On MATLAB R2024b/PCWIN64, committed before-runtimes were 134.42 s, 352.14 s,
and 256.08 s. After setup isolation and tier correction, measured runtimes were
32.101 s, 76.053 s, and 36.158 s respectively. The after-runs occurred while a
separate long-lived MATLAB session was active, so they are conservative and not
cross-machine thresholds. Child evidence is in
`analysis/test_inventory/quick_runtime_contributions.csv`.

The dominant prior costs were repeated `startup`, the 14-test mRLFE smoke
owner, and `test_mrlfe_production_core_presets`. The preset execution and the
mRLFE fitting regression owner moved to extended. Lightweight preset-grid,
result-schema, public validation, and representative model solves remain in
quick/regression.

## Benchmark policy

`benchmarkMRLFEExecutionProfiles` supports `Mode="contract"` and `Mode="full"`.
Contract mode is a bounded 18-row structural matrix. Full mode adds S0Like and
warmups and remains descriptive/manual. Both report direct Fast/Balanced/Robust
preset metadata; VsFast differences and validity differences are diagnostics,
not equality assertions. No timing threshold is enforced.

## Runner consolidation

`run_mrlfe_public_characterization_tests` was consolidated into the coherent
public command `run_mrlfe_public_contract_tests`. Other single-test owners were
retained where they enforce a real tier boundary: result schema, requested
curve, production performance, and focused characterization. The target count
was not forced because removing those owners would blur quick, numerical,
extended, and performance semantics or break historical commands.

## mRLFE folder decision

Physical subdivision of `tests/models/mrlfe/` is deferred. Canonical ownership
and documentation now provide stable navigation; moving 36 maintained tests
would create exact-path and documentation churn without changing ownership.
Reconsider one family at a time only if unique basenames, exact-path consumers,
and owner boundaries remain stable and a navigation problem is demonstrated.

## Command by scenario

| Scenario | Command | Expected scope | Observed runtime | When to use |
| --- | --- | --- | ---: | --- |
| Documentation only | `git diff --check` plus link searches | no MATLAB behavior | n/a | prose-only changes |
| Path/helper | `run_quick_contract_tests` | 14 contracts | 32.101 s | path or helper edits |
| GUI adapter | `run_quick_smoke_tests` plus focused GUI owner | routine surfaces | 76.053 s quick | adapter changes |
| Model numerical | `run_numerical_regression_tests` plus model owner | deterministic models | 36.158 s | solver-facing changes |
| Fitting | `run_fit_validation_tests` | full recovery/QC | recorded per run | fitting changes |
| Execution profile | `run_execution_profile_end_to_end_tests` and diagnostics | matrix plus benchmark contract | extended | profile changes |
| Pre-PR focused | quick contract + quick smoke + numerical | routine gates | about 144 s combined here | normal branch closeout |
| Full extended | focused children of `run_extended_integration_tests` | matrices and characterization | multi-minute | scope-driven validation |
| Manual diagnostics | `run_execution_profile_diagnostics_tests` | formatting/structural benchmark | bounded | diagnostics changes |
| Benchmark characterization | `benchmarkMRLFEExecutionProfiles('Mode',"full")` | 36 descriptive rows | machine-specific | explicit benchmark work |

Validation cadence: run quick gates for every maintained code change, focused
owners for the changed surface, extended blocks before integration when their
contracts are affected, and performance/full benchmark only for explicit
performance or profile characterization work.
