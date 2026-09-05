# Validation status

Last reviewed: 2026-09-05.

## Current integrated state

Integration branch: `planning/full-repository-restructure`.
Numerical-alignment integration HEAD: `9386901d857148e546401a3ba2830023d61e7ea9`.
`main` remains untouched.

The final post-cleanup numerical-alignment gate passed on 2026-09-05 before PR
#132 integration. The merge preserved the validated production tree.

| Tier | Direct tests | Current status |
| --- | ---: | --- |
| run_repository_hygiene_tests | 7 | PASS |
| run_quick_contract_tests | 16 | PASS |
| run_quick_smoke_tests | 29 | PASS |
| run_numerical_regression_tests | 17 | PASS |
| run_extended_integration_tests | 40 | PASS |
| run_performance_and_benchmark_tests | 4 | PASS |

There are 113 maintained tests and six flat runners. Every maintained test is
owned directly by exactly one runner; `tests/README.md` is authoritative.

## mRLFE numerical alignment

PR #131 is integrated into planning. Fast uses a 100-point coarse Cp scan and a
260-point rescue scan only when candidate discovery requires it, followed by
selected-candidate continuous refinement. The Fast waviness source was
scan-grid quantization; the correction preserves branch identity without
plotting-side smoothing.

Temporary optimization diagnostics and ad hoc benchmarks are not tracked.

## AE numerical alignment

PR #132 is integrated into planning. AE preserves the maintained lifecycle:

```text
SVD atlas -> discrete minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement of the selected branch on the true SVD objective
```

Accepted performance changes only remove repeated exact computation during atlas
construction:

- Cp-dependent acoustoelastic roots and fluid state are computed once per atlas
  Cp sample and reused across frequencies;
- Cp-dependent algebraic coefficients are cached;
- repeated `sinh`/`cosh` evaluations within one matrix construction are reused;
- diagnostic/modal outputs are not assembled when only the scalar objective is
  requested.

The internal state owner is `aeComputeAcoustoelasticCpState`.

The characteristic matrix, three-output SVD definition, objective definition,
`atlasA0` selection, Fast 300-point atlas, fallback policies, and protected
continuous refinement are unchanged. Temporary validation measured zero
objective-map difference and zero selected branch/rank/discrete-Cp difference
between the legacy and optimized exact paths.

The proposed AE coarse/rescue density route was rejected. In the 33-case matrix,
19 coarse cases differed from the 300-point reference and the proposed rescue
trigger missed 10 of them. No adaptive-density behavior entered production.

## Cleanup

All temporary AE/mRLFE numerical-alignment diagnostics and ad hoc performance
benchmarks have been removed. The redundant mRLFE benchmark-specific contract
was removed because `validateExecutionProfileMatrix` already owns that
cross-surface execution-profile contract.

`tests/tooling` contains only:

- `configureTestPath.m`;
- `measureTestRuntime.m`;
- `validateExecutionProfileMatrix.m`.

Maintained scientific diagnostics remain only where they have a distinct
supported responsibility. Generated result files remain outside tracked source.

## Integration status

Numerical solver alignment is complete in `planning/full-repository-restructure`.
No numerical golden or tolerance was weakened. Further integration into `main`
is a separate repository-level decision and requires explicit user authorization.
