# Active project context

Last reviewed: 2026-09-03

Repository: `cpariona/Lamb-fundamental-solver`
Integration branch: `restructure/phase-07-final-integration`
Base: Phase 6 HEAD `5183565`.

## Final architecture

Models own physics, tracking, numerical configuration, quality, and scientific
results. Analysis owns fitting, sweeps, plotting, IO, and diagnostic
interpretation. App is surface-first: main, fitting, sweep, shared.
The dependency mRLFE -> RL is restricted to seed construction; RL never calls
mRLFE. Human interfaces consume the same maintained scientific owners.

Production startup loads root/models/analysis/app plus only the six test
launchers. Test bodies and tooling load explicitly and runners restore the
caller path. Examples/diagnostics are opt-in files.

There are 114 tests, exactly six runners, and 16 representative executable
examples (including six diagnostics). Authoritative ownership is in
`tests/README.md`; architecture is in
`docs/repository/repository_structure.md`.

## Scientific baseline

AE retains discrete atlas selection followed by bounded fminbnd refinement on
the true SVD objective. Causal replay proves that its earlier snapshot predates
that approved algorithm. Commit `6911727` updates only three golden values;
the 1e-12 tolerance and all production science are unchanged.
Evidence: `docs/validation/ae_atlasA0_baseline.md`.

## Integration

Integration is BLOCKED by a historical mRLFE configuration delta, independently
of the six ordinary tiers, all of which passed. The edge guard migrated from an
effective 4 to 8 in Phase 2; restoring 4 in memory reproduces all 24 Fast
reference cases exactly. A production correction requires explicit approval.
See `docs/validation/mrlfe_restructure_baseline.md` and
`docs/repository/validation_status.md`.
No push or merge is authorized. Review and integration are separate actions;
there is no subsequent restructuring phase.
