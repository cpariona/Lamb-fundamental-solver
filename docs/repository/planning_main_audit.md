# Planning versus main audit

Last reviewed: 2026-09-05.

## Scope

This audit records the final repository-level review after PR #135 merged the
structural-symmetry campaign into `planning/full-repository-restructure`.
It does not authorize or perform any change to `main`.

## Compared refs

```text
planning/full-repository-restructure
  b925cfc2ad6d1c29b75812141c84f16ee705baa2

main
  026994f86a2d1dfe5a740034d7a5fd81d4f08235
```

GitHub comparison at audit start:

```text
status      ahead
planning    286 commits ahead
planning    0 commits behind
merge base  026994f86a2d1dfe5a740034d7a5fd81d4f08235
```

Therefore `main` has no commits absent from planning and there is no history
divergence to reconcile before a final integration review.

## Validation evidence

The integrated structural tree passed all six maintained MATLAB runners before
PR #135 was merged:

| Runner | Tests | Status |
| --- | ---: | --- |
| `run_repository_hygiene_tests` | 8 | PASS |
| `run_quick_contract_tests` | 17 | PASS |
| `run_quick_smoke_tests` | 29 | PASS |
| `run_numerical_regression_tests` | 17 | PASS |
| `run_extended_integration_tests` | 40 | PASS |
| `run_performance_and_benchmark_tests` | 4 | PASS |

Total maintained tests: 115.

After the historical sweep-GUI characterization-test correction, extended
integration and performance/benchmark were rerun and passed. The correction was
limited to a stale test assumption about the generic sweep request envelope; no
production source or numerical policy changed. PR #135 then merged that
validated source tree into planning.

GitHub reports no CI/status checks on the planning merge commit. The local
MATLAB gate is therefore the authoritative execution evidence.

## Static integration review

The audit sampled the areas most likely to break after a repository-wide
restructure:

- repository root and maintained human entrypoints;
- `startup.m` and `configureProjectPath.m` path ownership;
- public RL, mRLFE, and AE model APIs;
- Main GUI launch path through `runApp`;
- maintained sweep and fitting entrypoints;
- model-family folder ownership and structural symmetry;
- maintained test ownership and the six runner surface;
- documentation describing production APIs and validation.

No functional blocker was found.

### Confirmed invariants

- Production startup exposed the then-maintained trees and only the six test
  launchers from `tests/runners/`; the canonical architecture now supersedes
  that transitional layout.
- Test bodies, examples, and executable diagnostics are not globally loaded by
  production startup.
- RL, mRLFE, and AE public model entrypoints exist at their documented owners.
- The only intentional cross-family scientific dependency remains the mRLFE
  seed use of the Rayleigh-Lamb solver.
- Generic frequency construction has neutral shared ownership.
- Main GUI, FitTool, and sensitivity studies reach mRLFE through its public route.
- One-dimensional sensitivity results retain the common `lamb.sweeps.runParametricSweep` shape;
  AE 2-D grids remain intentionally specialized.
- Maintained direct tests use runner-owned path setup and the global hygiene
  gate scans every tracked `test_*.m`.

## Post-merge finding

Three project-status documents still described PR #135 as future work after the
PR had already merged:

- `docs/repository/validation_status.md`
- `docs/project/active_context.md`
- `docs/project/session_handoff.md`

This is documentation-only debt. It is corrected on
`audit/planning-main-readiness`; no production or test source is changed by the
closeout branch.

## Readiness conclusion

After the closeout documentation is integrated into planning, no known
repository-level blocker remains for opening a final planning-to-main PR.

A final PR may be prepared only after explicit user authorization. Merging into
`main` likewise requires explicit user authorization and is outside the scope of
this audit.
