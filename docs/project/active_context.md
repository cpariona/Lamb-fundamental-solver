# Active project context

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Integration branch: `planning/full-repository-restructure`
Working branch: `numerical-solver-alignment/ae-performance-optimization`
Planning base: `60dad1ff17a19eaeca7eb9efaf949cb37b2463c5`.
`main` remains untouched by the numerical-alignment work.

## Architecture

Models own physics, tracking, numerical configuration, quality, and scientific
results. Analysis owns fitting, sweeps, plotting, IO, and diagnostic
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

mRLFE Fast optimization was merged into planning through PR #131. Fast uses a
100-point coarse Cp scan with 260-point rescue only when candidate discovery
requires it, followed by the maintained selected-candidate continuous
refinement. The six validation runners passed before merge.

AE retains the protected lifecycle:

```text
full discrete atlas -> minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement of the selected branch on the true SVD objective
```

The AE working branch only optimizes repeated computation inside atlas
construction. Cp-dependent root/fluid state and algebraic coefficients are
reused across frequencies, repeated hyperbolic evaluations are avoided, and
unused diagnostic outputs are skipped when callers request only the objective.
The matrix, SVD definition, `atlasA0` policy, Fast 300-point atlas, and protected
continuous refinement are unchanged.

A coarse/rescue AE atlas-density strategy was investigated and rejected: a
33-case matrix produced 10 false negatives with the proposed validity trigger.
No adaptive-density behavior was promoted to production.

## Cleanup and validation

All temporary AE investigation scripts and ad hoc numerical benchmarks have
been removed. `tests/tooling` now contains only path configuration, runtime
measurement, and the maintained cross-surface execution-profile validator.
The benchmark-specific mRLFE test was removed because its functional contract
is already covered by `validateExecutionProfileMatrix`.

Numerical regression and extended integration passed after the exact AE
optimizations. A final run of all six canonical runners is required after this
cleanup before opening the integration PR.
