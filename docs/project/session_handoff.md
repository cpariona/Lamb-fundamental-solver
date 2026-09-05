# Integration handoff

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Integration branch: `planning/full-repository-restructure`
Planning HEAD after numerical-alignment integration: `9386901d857148e546401a3ba2830023d61e7ea9`.
`main` has not been modified by the numerical-alignment campaign.

## Numerical-alignment campaign

Issue #130 is complete at the implementation/integration level.

### mRLFE

Integrated through PR #131. The maintained Fast route uses a 100-point coarse
Cp scan, a 260-point rescue only when candidate discovery requires it, and
selected-candidate continuous refinement. The scan-grid waviness source was
identified as quantization and corrected without plotting-side smoothing.

### AE

Integrated through PR #132. AE keeps the protected scientific lifecycle:

```text
full discrete atlas -> minima -> branch linking -> atlasA0 selection
-> bounded continuous refinement on the true SVD objective
```

The accepted optimization changes only repeated exact computation during atlas
construction: Cp-dependent roots/fluid state and algebraic coefficients are
reused across frequencies, repeated hyperbolic evaluations are reused, and
modal/diagnostic outputs are skipped when only the scalar objective is needed.

Unchanged scientific behavior includes:

- Fast/Balanced/Robust atlas densities, including Fast = 300 points;
- characteristic matrix and three-output SVD definition;
- discrete local-minimum discovery;
- branch linking/splitting and official `atlasA0` selection;
- fallback/requested-grid policies;
- bounded selected-branch continuous refinement.

The investigated coarse/rescue AE density strategy was rejected after the
33-case screening produced 10 false negatives. No adaptive-density behavior
entered production.

## Repository cleanup

Temporary AE/mRLFE optimization diagnostics and ad hoc numerical benchmarks
were removed. `tests/tooling` contains only maintained path/runtime/profile
validation tooling. There are 113 maintained tests across six canonical
runners.

## Validation

The final post-cleanup gate on 2026-09-05 passed all six canonical runners:

1. `run_repository_hygiene_tests` — PASS
2. `run_quick_contract_tests` — PASS
3. `run_quick_smoke_tests` — PASS
4. `run_numerical_regression_tests` — PASS
5. `run_extended_integration_tests` — PASS
6. `run_performance_and_benchmark_tests` — PASS

No scientific golden or numerical tolerance was changed. PR #132 merged the
validated AE tree into planning without additional production changes.

## Next action

`planning/full-repository-restructure` is now the authoritative integrated state
for the completed repository restructuring plus numerical-solver alignment.

No further numerical-alignment development is pending under Issue #130.
The next repository-level step, only with explicit user authorization, is to
review the complete planning branch against `main` and decide whether/how to
integrate it. Do not modify or merge into `main` without that authorization.
