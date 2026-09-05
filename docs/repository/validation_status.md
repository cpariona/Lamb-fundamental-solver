# Validation status

Last reviewed: 2026-09-05.

## Current gate

Working branch: `numerical-solver-alignment/ae-performance-optimization`.
Integration target: `planning/full-repository-restructure` at base
`60dad1ff17a19eaeca7eb9efaf949cb37b2463c5`.
`main` remains untouched.

The final post-cleanup integration gate passed on 2026-09-05.

| Tier | Direct tests | Current status |
| --- | ---: | --- |
| run_repository_hygiene_tests | 7 | PASS |
| run_quick_contract_tests | 16 | PASS |
| run_quick_smoke_tests | 29 | PASS |
| run_numerical_regression_tests | 17 | PASS |
| run_extended_integration_tests | 40 | PASS |
| run_performance_and_benchmark_tests | 4 | PASS |

There are 113 maintained tests and six flat runners. Every maintained test is
owned directly by exactly one runner; `tests/README.md` is the authoritative
summary.

## mRLFE numerical alignment

The mRLFE optimization was merged into planning through PR #131. Fast now uses
a 100-point coarse Cp scan and a 260-point rescue scan only when candidate
discovery requires it, followed by selected-candidate continuous refinement.
The completed validation preserved the screened scientific behavior while
substantially reducing Fast runtime. All six runners passed before that merge.

Temporary mRLFE optimization diagnostics and ad hoc benchmarks created during
the campaign are no longer tracked. The retained tracking-quality summary is a
maintained scientific diagnostic, not temporary benchmark tooling.

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

The internal state owner is `aeComputeAcoustoelasticCpState`, consistent with
the AE naming contract.

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

Maintained scientific diagnostics under `analysis/diagnostics/` and model
identity diagnostics were retained because they have distinct supported
responsibilities and are covered by repository contracts. Generated result
files remain outside tracked source.

## Integration readiness

The working branch is ready for PR review into
`planning/full-repository-restructure`. Before merging, inspect the branch diff
and confirm that it contains only the intended exact AE performance changes,
cleanup, and current project documentation. Do not target or merge into `main`
without explicit authorization.
