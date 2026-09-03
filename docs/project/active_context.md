# Active project context

Last reviewed: 2026-09-03

Repository: `cpariona/Lamb-fundamental-solver`

Active implementation branch:
`restructure/phase-06-validation-surface-cleanup`

## Current state

- Rayleigh-Lamb, mRLFE, and AE IOP/HGO have small canonical scientific APIs.
- Main GUI, SweepTool, and FitTool converge on those model APIs.
- Model, analysis, and application ownership is physically separated.
- Official result contracts separate arrays, quality, diagnostics, and
  requested/effective configuration.
- Examples and diagnostics form a representative maintained surface rather
  than an archive of completed investigations.
- Validation has exactly six flat runner tiers and 114 uniquely owned tests.

AE production uses discrete atlas candidates followed by bounded continuous
refinement on the true SVD objective. The earlier three-point parabolic
candidate strategy is not part of production.

## Phase 6 boundary

Phase 6 changes validation and documentation surfaces only. It does not change
solver equations, tracking policy, optimizer defaults, numerical presets,
goldens, or tolerances. The known AE atlasA0 Cp snapshot difference remains an
explicit baseline result.

## Next phase

Phase 7 may perform final startup/path and documentation consistency review,
then prepare integration. It must not normalize the known AE baseline or expand
public APIs without separate authorization.
