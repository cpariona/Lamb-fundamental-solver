# Integration handoff

Last reviewed: 2026-09-05

Integration branch: `planning/full-repository-restructure`
Working branch: `numerical-solver-alignment/ae-performance-optimization`
Planning base: `60dad1ff17a19eaeca7eb9efaf949cb37b2463c5`.
`main` has not been modified by this campaign.

## Completed numerical work

mRLFE optimization is already integrated into planning through PR #131.
Its maintained Fast route uses coarse scanning plus targeted dense rescue and
selected-candidate continuous refinement.

The current branch optimizes AE atlas construction without altering scientific
selection behavior. Production changes are limited to reuse of Cp-dependent
state/algebraic coefficients and avoidance of unused/repeated computation.
The following remain unchanged:

- Fast/Balanced/Robust AE atlas densities, including Fast = 300 points;
- discrete local-minimum discovery;
- branch linking/splitting;
- official `atlasA0` selection;
- bounded continuous refinement on the true SVD objective;
- fallback and requested-grid policies.

Temporary diagnostics verified zero objective-map, branch-rank, and discrete-Cp
difference for the exact optimization path. Numerical regression and extended
integration passed after the production changes.

A proposed AE coarse/rescue density scheme was rejected. In the 33-case
validation matrix, 19 coarse cases differed from the 300-point reference and a
`ValidFraction < 1` trigger missed 10 of them. No density adaptation entered
production.

## Repository cleanup

Temporary AE diagnostics and ad hoc numerical benchmarks have been removed.
The obsolete mRLFE benchmark-specific contract was also removed because the
maintained cross-surface validator already covers execution-profile behavior.
There are now 113 maintained tests across the same six canonical runners.

## Next gate

Run all six canonical runners on the current branch. If they pass, review the
branch diff and open a PR into `planning/full-repository-restructure`.
Do not merge into `main` without explicit authorization.
