# Active project context

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Integration branch: `planning/full-repository-restructure`
Working branch: `numerical-solver-alignment/ae-performance-optimization`
Planning base: `60dad1ff17a19eaeca7eb9efaf949cb37b2463c5`.
`main` remains untouched by the numerical-alignment work.

## Architecture

Models own physics, tracking, numerical configuration, quality, and scientific
results. Analysis owns fitting, sweeps, plotting, IO, and maintained diagnostic
interpretation. App is surface-first: main, fitting, sweep, shared.
The dependency mRLFE -> RL is restricted to seed construction; RL never calls
mRLFE. Human interfaces consume the same maintained scientific owners.

Production startup loads root/models/analysis/app plus only the six test
launchers. Test bodies and tooling load explicitly and runners restore the
caller path. Examples and maintained scientific diagnostics are opt-in.

There are 113 maintained tests and exactly six runners. Authoritative ownership
is in `tests/README.md`; architecture is in
`docs/repository/repository_structure.md`.

## Numerical alignment status

### mRLFE

mRLFE Fast optimization was merged into planning through PR #131. Fast uses a
100-point coarse Cp scan with 260-point rescue only when candidate discovery
requires it, followed by maintained selected-candidate continuous refinement.
Temporary optimization diagnostics/benchmarks created during that campaign
have been removed.

### AE

AE retains the protected lifecycle:

```text
full discrete atlas -> minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement of the selected branch on the true SVD objective
```

The AE working branch only optimizes repeated computation inside atlas
construction. Cp-dependent root/fluid state and algebraic coefficients are
reused across frequencies, repeated hyperbolic evaluations are avoided, and
unused diagnostic outputs are skipped when callers request only the objective.
The internal state helper is `aeComputeAcoustoelasticCpState`.

The matrix, three-output SVD definition, `atlasA0` policy, Fast 300-point atlas,
and protected continuous refinement are unchanged.

A coarse/rescue AE atlas-density strategy was investigated and rejected: a
33-case matrix produced 10 false negatives with the proposed validity trigger.
No adaptive-density behavior was promoted to production.

## Cleanup

All temporary AE investigation scripts and ad hoc numerical benchmarks have
been removed. The obsolete mRLFE benchmark-specific test was removed because
its functional execution-profile contract is already covered by
`validateExecutionProfileMatrix`.

`tests/tooling` contains only:

- `configureTestPath.m`;
- `measureTestRuntime.m`;
- `validateExecutionProfileMatrix.m`.

Maintained scientific diagnostics are retained only where they have a distinct
supported responsibility.

## Validation

The complete post-cleanup gate passed on 2026-09-05:

- `run_repository_hygiene_tests` — PASS
- `run_quick_contract_tests` — PASS
- `run_quick_smoke_tests` — PASS
- `run_numerical_regression_tests` — PASS
- `run_extended_integration_tests` — PASS
- `run_performance_and_benchmark_tests` — PASS

No tolerance or scientific golden was changed for this gate.

## Immediate next step

Review the working-branch diff against `planning/full-repository-restructure`
and open an integration PR targeting that planning branch. Do not merge into
`main` without explicit authorization. Keep Issue #130 open until AE integration
and numerical-alignment closeout are complete.
