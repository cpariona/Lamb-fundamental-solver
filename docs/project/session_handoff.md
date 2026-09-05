# Integration handoff

Last reviewed: 2026-09-05

Repository: `cpariona/Lamb-fundamental-solver`
Integration branch: `planning/full-repository-restructure`
Working branch: `numerical-solver-alignment/ae-performance-optimization`
Planning base: `60dad1ff17a19eaeca7eb9efaf949cb37b2463c5`.
Validated working HEAD before this handoff update: `e378eb97f95467c0bc50d273c939d52589c98afe`.
`main` has not been modified by this numerical-alignment campaign.

## Completed numerical work

### mRLFE

mRLFE optimization is already integrated into planning through PR #131.
The maintained Fast route uses a 100-point coarse Cp scan, a 260-point dense
rescue only when candidate discovery requires it, and selected-candidate
continuous refinement. The completed validation preserved the screened
scientific behavior while substantially reducing Fast runtime.

Temporary mRLFE optimization diagnostics and ad hoc benchmarks created during
the campaign are no longer tracked. The retained
`analysis/diagnostics/mrlfe/summarizeMRLFETrackingQuality.m` is a maintained
scientific utility that predates/is independent of the temporary optimization
tooling.

### AE

The current branch optimizes AE atlas construction without changing scientific
selection behavior. Production changes are limited to:

- computing Cp-dependent acoustoelastic roots/fluid state once per atlas Cp and
  reusing them across frequencies;
- caching Cp-dependent algebraic coefficients;
- reusing repeated hyperbolic evaluations within matrix assembly;
- skipping modal/diagnostic output construction when callers request only the
  scalar objective.

The new internal helper follows the repository naming contract:
`aeComputeAcoustoelasticCpState`.

The following remain unchanged:

- Fast/Balanced/Robust AE atlas densities, including Fast = 300 points;
- characteristic matrix and three-output SVD definition;
- discrete local-minimum discovery;
- branch linking/splitting;
- official `atlasA0` selection;
- bounded continuous refinement on the true SVD objective;
- fallback and requested-grid policies.

Temporary diagnostics verified zero objective-map, branch-rank, and discrete-Cp
difference for the exact optimization path. A proposed AE coarse/rescue density
scheme was explicitly rejected: in the 33-case matrix, 19 coarse cases differed
from the 300-point reference and a `ValidFraction < 1` trigger missed 10 of
them. No adaptive-density behavior entered production.

## Repository cleanup

Temporary AE diagnostics and ad hoc numerical benchmarks have been removed.
The obsolete mRLFE benchmark-specific contract was removed because the
maintained cross-surface validator already covers execution-profile behavior.
`tests/tooling` contains only maintained path/runtime/profile-validation tools.
There are 113 maintained tests across the same six canonical runners.

## Final validation

On 2026-09-05 the user ran the complete gate after the naming fix and cleanup.
All six canonical runners passed:

1. `run_repository_hygiene_tests` — PASS
2. `run_quick_contract_tests` — PASS
3. `run_quick_smoke_tests` — PASS
4. `run_numerical_regression_tests` — PASS
5. `run_extended_integration_tests` — PASS
6. `run_performance_and_benchmark_tests` — PASS

No scientific golden or numerical tolerance was changed to obtain this result.

## Next action

The AE branch is ready for integration review. In the next session:

1. read this file and `docs/project/active_context.md`;
2. inspect the current branch HEAD and compare it against
   `planning/full-repository-restructure`;
3. inspect Issue #130 and relevant open PRs;
4. verify that only intended AE exact-performance changes, cleanup, and handoff
   documentation differ;
5. open a PR from `numerical-solver-alignment/ae-performance-optimization` into
   `planning/full-repository-restructure`;
6. do not target or merge into `main` without explicit user authorization.

Issue #130 should remain open until the AE integration is completed and the
numerical-alignment campaign is formally closed.
