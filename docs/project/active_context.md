# Active project context

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Integration branch: `planning/full-repository-restructure`
Integrated numerical-alignment HEAD: `9386901d857148e546401a3ba2830023d61e7ea9`.
`main` remains untouched.

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

Issue #130 is complete at the implementation/integration level.

### mRLFE

PR #131 is integrated into planning. Fast uses a 100-point coarse Cp scan with
a 260-point rescue only when candidate discovery requires it, followed by
selected-candidate continuous refinement. The former Fast Cp waviness was
identified as scan-grid quantization and corrected without plotting-side
smoothing.

### AE

PR #132 is integrated into planning. AE retains the protected lifecycle:

```text
full discrete atlas -> minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement of the selected branch on the true SVD objective
```

Cp-dependent root/fluid state and algebraic coefficients are reused across
frequencies, repeated hyperbolic evaluations are avoided, and unused diagnostic
outputs are skipped when callers request only the objective.
The internal state helper is `aeComputeAcoustoelasticCpState`.

The characteristic matrix, three-output SVD definition, `atlasA0` policy, Fast
300-point atlas, fallback behavior, and protected continuous refinement are
unchanged. The investigated coarse/rescue atlas-density scheme was rejected
after 10 false negatives in the 33-case screening; it did not enter production.

## Cleanup and validation

Temporary AE/mRLFE investigation scripts and ad hoc numerical benchmarks have
been removed. `tests/tooling` contains only:

- `configureTestPath.m`;
- `measureTestRuntime.m`;
- `validateExecutionProfileMatrix.m`.

The complete post-cleanup gate passed on 2026-09-05:

- `run_repository_hygiene_tests` — PASS
- `run_quick_contract_tests` — PASS
- `run_quick_smoke_tests` — PASS
- `run_numerical_regression_tests` — PASS
- `run_extended_integration_tests` — PASS
- `run_performance_and_benchmark_tests` — PASS

No tolerance or scientific golden was changed for this gate.

## Immediate next step

There is no remaining numerical-alignment implementation task under Issue #130.
`planning/full-repository-restructure` is the current integrated repository
state. A final planning-versus-`main` review/integration is a separate action and
must not be performed without explicit user authorization.
