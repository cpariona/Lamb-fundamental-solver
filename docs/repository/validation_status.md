# Validation status

## Integration gate

BLOCKED for historical mRLFE preservation; all six ordinary tiers passed on
`restructure/phase-07-final-integration`, based on Phase 6 HEAD `5183565`.
MATLAB R2024b, Windows, 2026-09-03.
The final run starts with clear functions, rehash toolboxcache, and startup,
and checks caller-path restoration after every tier.

| Tier | Direct tests | Final status |
| --- | ---: | --- |
| run_repository_hygiene_tests | 7 | PASS |
| run_quick_contract_tests | 16 | PASS |
| run_quick_smoke_tests | 29 | PASS |
| run_numerical_regression_tests | 17 | PASS |
| run_extended_integration_tests | 40 | PASS |
| run_performance_and_benchmark_tests | 5 | PASS |

There are exactly 114 tests and six flat runners; ownership is checked directly,
without wrapper graphs or generated inventories. See `tests/README.md`.

The quick-contract tier was rerun after strengthening the RL example/result
guard. The quick-smoke tier and mRLFE Main GUI result/axis contract were rerun
after restoring the dimensionless plotting coordinate; all passed.

Main GUI, FitTool, and SweepTool each completed 24 direct-public-solver
comparisons with absolute/relative Cp delta 0 and identical masks. Main GUI
versus FitTool/SweepTool also gave 0. Synthetic mu relative errors were
1.73383e-10 (RL), 5.00318e-09 (mRLFE), and 5.06201e-08 (AE).
The four mRLFE fitting regression cases retained 11, 8, 7, and 7 evaluations.
These current-consumer equivalences are distinct from the historical gate below.

## Performance

The full performance tier passed after extended integration. The four warm
production-core medians were 0.8700 s (A0Like, etaS=0), 0.9194 s (A0Like,
etaS=0.05), 0.9350 s (S0Like, etaS=0), and 0.9538 s (S0Like, etaS=0.05).
The same fixture in Phase 6 reported a 0.8465-0.8885 s range. The modest timing
increase is a machine-local measurement; its cause has not been isolated.
It does not establish added solver calls; production computation is unchanged
in this phase.
No architectural solve/evaluation duplication was observed: fitting counts
remain 11/8/7/7 and display/export contracts prohibit reevaluation.

The optimized fitting grid measured 3.768x, 3.824x, and 4.830x speedups versus
the preset grid in its three fixtures. Worst relative cross-grid Cp difference
was 0.00120634, with zero mask differences. This is a grid-policy comparison,
not the historical preservation comparison. No timing or numerical tolerance
was weakened to pass these checks.

## Scientific evidence

AE causal replay identifies `026994f`, not this restructuring, as the source
of the obsolete snapshot delta. Historical origin/parent and causal/current
pairs each match all 35 points exactly. Independent true-SVD, branch identity,
tight convergence, grid-density, and synthetic mu recovery evidence justified
the explicit golden update `6911727`, with 1e-12 unchanged.
See `docs/validation/ae_atlasA0_baseline.md`.

mRLFE historical replay against Phase 1 `1b6b3a1` exposes a real Fast delta:
maximum 0.0120684309767 m/s, relative 0.00113100537214, no mask differences.
Three A0Like cases at mu=250 kPa differ. An in-memory correction of the
migrated edge guard from 8 to its prior effective value 4 restores exact
equality in all 24 Fast cases. Production remains unchanged pending explicit
authorization; this is an integration blocker even if ordinary tiers pass.
All six Dense reference cases match exactly, including masks.
See `docs/validation/mrlfe_restructure_baseline.md`.

The inherited matrix printed initialized zeros without a reference comparison;
it now distinguishes coverage-only checks from measured historical deltas.
Human-surface tests use the current public solver as their adapter reference,
so their exact equality does not establish historical numerical preservation.

## Architecture and hygiene audit

- Models, fitting, and sweep calculation are unchanged by Phase 7. Changes
  cover paths, validation, tooling placement, examples' bootstrap,
  documentation, and the isolated AE snapshot update. The RL
  basic example also now reads the canonical diagnostics.residual field;
  executing it exposed the stale direct residual access.
- The mRLFE Main GUI view now derives its missing k*thickness plotting
  coordinate from canonical wavenumber and stored full thickness. No solver
  is called and official Cp, wavenumber, masks, and geometry are unchanged.
- Model -> app/analysis/examples/tests and analysis -> app/examples/tests
  dependencies are forbidden and checked. mRLFE -> RL seed is intentional;
  RL -> mRLFE is absent.
- Each maintained MATLAB filename is globally unique; critical public APIs
  resolve once through which -all.
- Result quality/configuration/diagnostic owners are explicit; plotting and
  export consume completed results without scientific recomputation.
- Low-reference functions were reviewed semantically. Complex-C AE inspection,
  diagnostic persistence continuation, and the all-condition grid renderer
  retain distinct responsibilities; they were not removed merely for low
  caller counts.
- The obsolete analysis performance smoke script was removed. App-facing
  benchmark/matrix functions moved to tests/tooling. Historical architecture
  plans and duplicate test-ownership docs were consolidated into current
  repository contracts and tests/README.
- Four obsolete empty directories were removed. No temporary diagnostic or
  generated output was added to tracked source.
- Main GUI, FitTool, and SweepTool launch successfully in an isolated MATLAB
  process. This is a launch/API check, not an assertion of manual visual QA.
- All three basic examples ran by explicit path in a disposable source copy:
  RL A0/S0 577/577 valid each, mRLFE A0Like/S0Like 120/120 each, AE 35/35.
  The RL analytical-approximation invocation in the API documentation also
  executed successfully. Generated example files stayed outside this worktree.

The initial final-validation attempts exposed a missing README profile
description and stale paths in sessions opened before empty-directory cleanup.
Both were corrected; the final run uses a fresh session and stable filesystem.
No scientific assertion or tolerance was relaxed to address those issues.

## Established input/file compatibility

These are bounded input/persistence contracts, not alternate model APIs or
scientific-result aliases.

| Contract | Owner | Reason and removal condition |
| --- | --- | --- |
| robustness input alias | app profile normalization | Existing callers are supported; remove only after producers/external requests migrate to executionProfile. |
| AE prior result-file locations | aeResolveResultFile | Read-only discovery of previously generated workspaces; remove after required external inputs migrate. |

No new aliases are introduced. Current model-result arrays have canonical
names and no compatibility copies.
