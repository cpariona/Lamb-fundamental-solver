# Validation status

Last reviewed: 2026-09-05.

## Current gate

Working branch: `numerical-solver-alignment/ae-performance-optimization`.
Integration target: `planning/full-repository-restructure` at base
`60dad1ff17a19eaeca7eb9efaf949cb37b2463c5`.
`main` remains untouched.

The final integration gate is pending a fresh run of all six canonical runners
after cleanup. Numerical regression and extended integration already passed
after the accepted AE production optimizations.

| Tier | Direct tests | Current status |
| --- | ---: | --- |
| run_repository_hygiene_tests | 7 | rerun required after cleanup |
| run_quick_contract_tests | 16 | rerun required after cleanup |
| run_quick_smoke_tests | 29 | rerun required after cleanup |
| run_numerical_regression_tests | 17 | PASS before final cleanup; rerun required |
| run_extended_integration_tests | 40 | PASS before final cleanup; rerun required |
| run_performance_and_benchmark_tests | 4 | rerun required after cleanup |

There are 113 maintained tests and six flat runners. Every maintained test is
owned directly by exactly one runner; `tests/README.md` is the authoritative
summary.

## mRLFE numerical alignment

The mRLFE optimization was merged into planning through PR #131. Fast now uses
a 100-point coarse Cp scan and a 260-point rescue scan only when candidate
discovery requires it, followed by selected-candidate continuous refinement.
The completed validation showed preserved masks/candidate behavior across the
screened matrix and substantially reduced Fast runtime. All six runners passed
before that merge.

## AE numerical alignment

AE preserves the maintained scientific lifecycle:

```text
SVD atlas -> discrete minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement of the selected branch on the true SVD objective
```

The accepted optimization changes only repeated computation inside atlas
construction:

- Cp-dependent acoustoelastic roots and fluid state are computed once per atlas
  Cp sample and reused across frequencies;
- Cp-dependent algebraic coefficients are cached;
- repeated `sinh`/`cosh` evaluations within one matrix construction are reused;
- diagnostic/modal outputs are not assembled when a caller requests only the
  scalar objective.

The characteristic matrix, three-output SVD definition, objective definition,
`atlasA0` selection, Fast 300-point atlas, and protected continuous refinement
remain unchanged. Temporary diagnostics measured zero objective-map difference
and zero selected branch/rank/discrete-Cp difference between the legacy and
optimized exact paths. Those temporary benchmark/diagnostic scripts are no
longer tracked.

An adaptive coarse-density AE route was investigated but rejected. In a
33-case matrix with 180-point coarse and 300-point reference atlases, 19 coarse
cases were unsafe and the proposed `ValidFraction < 1` rescue rule missed 10 of
them. No coarse/rescue density behavior was promoted.

## Cleanup

All temporary AE investigation scripts and ad hoc numerical performance
benchmarks created during the numerical-alignment campaign have been removed.
The former mRLFE benchmark-specific contract test was removed as redundant with
`validateExecutionProfileMatrix`, which remains the maintained cross-surface
execution-profile validator.

`tests/tooling` now contains only:

- `configureTestPath.m`;
- `measureTestRuntime.m`;
- `validateExecutionProfileMatrix.m`.

Maintained scientific AE diagnostics under `analysis/diagnostics/` and model
identity diagnostics were retained because they have distinct supported
responsibilities and are covered by repository contracts. Generated result
files remain outside tracked source.

## Final integration requirement

Before opening the AE integration PR, run:

```matlab
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

No numerical tolerance or scientific golden should be changed to satisfy this
final gate.
