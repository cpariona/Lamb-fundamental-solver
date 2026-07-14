# Active project context

Last reviewed: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Default branch: main
Last known good merge: `ca0ccfc3ea636ae2e77f1a672d9d4e8d3304e7ba` (PR #110)

## Current development focus

The mRLFE public-solver migration and repository hygiene phase 1 are complete and
merged into `main`.

No next technical objective has been selected. The next session should first
recover the current repository state, review the remaining work recorded by the
cleanup audit, and choose one focused objective before creating a branch.

Repository hygiene remains an active multi-phase concern, but later phases are
not automatically the next priority. They must be compared against open test,
documentation, diagnostic, compatibility, and solver-layer issues.

## Recently completed capabilities

- Public mRLFE API and production-core organization.
- Removal of legacy mRLFE atlas/direct-visco production routes.
- End-to-end execution-profile integration across Main GUI, SweepTool, and FitTool.
- Fast, Balanced, Robust, and dense/reference numerical presets.
- Direct SweepTool use of `mrlfeSolve` per sweep point.
- FitTool objective evaluations on a bounded fit-optimized internal grid.
- Fit-result normalization without automatic solver reevaluation.
- Explicit user-requested fitted-curve solver evaluation.
- Fit-versus-requested-curve consistency diagnostics.
- Repository-wide hygiene audit and conservative phase 1 cleanup through PR #110.
- Removal of generated execution-profile CSV snapshots.
- Removal of the superseded `guiEvaluateFitFullCurve` helper.
- Removal of two obsolete unregistered direct-visco route tests.

Detailed phase 1 evidence:

```text
docs/repository/repository_cleanup_phase1_report.md
```

## Active architectural contracts

- GUI surfaces delegate to adapters and backends. See `docs/workflows/gui/adapter_architecture.md`.
- Model physics remains in model layers. See `docs/repository/repository_structure.md`.
- Fitting uses request -> dispatcher -> adapter -> maintained model API. See `docs/workflows/fitting/architecture.md`.
- `executionProfile` is distinct from route policy and optimizer options.
- Main GUI, SweepTool, and FitTool resolve Fast, Balanced, or Robust into the corresponding public mRLFE numerical preset.
- A0Like uses `physicalTail`; S0Like uses `none`; fallback remains disabled.
- FitTool optimization uses `gridPolicy = "fitOptimized"`.
- A complete fitted curve is evaluated only after the explicit **Evaluate fitted curve** action and uses `gridPolicy = "numericalPreset"`.
- AE IOP/HGO still uses valid atlas terminology; mRLFE legacy-atlas cleanup must not remove AE atlas code, tests, examples, or documentation.
- Public test-runner wrappers under `tests/` remain intentional compatibility entrypoints.
- The user performs merges manually unless explicitly requesting another workflow.

## Known limitations and open issues

- Existing synthetic and route-contract tests are not external physical validation.
- Grid-quality classifications near marginal branch tails can depend on the internal grid.
- Dense full-matrix validation is expensive and should not be repeated for documentation or repository hygiene alone.
- `run_mrlfe_public_contract_tests` contains a stale expectation that `balanced` is invalid, while the maintained implementation supports Balanced.
- `test_mrlfe_legacy_cleanup_characterization` has a pre-existing exact FitTool/direct Cp equality failure.
- Some long mRLFE suites exceeded the available execution timeout during hygiene phase 1; no pass was claimed for them.
- Historical documents may mention removed mRLFE routes as evidence; those names are not maintained production contracts.
- Some tests intentionally inspect names, paths, runner wrappers, generated inventories, or absence of legacy routes.
- Repository search alone may miss dynamic MATLAB calls; removal decisions require conservative verification.

## Provisional next-objective candidates

These are options for review, not an approved sequence:

1. **Documentation consolidation**
   - stale generic execution-profile audit and benchmark material;
   - historical mRLFE atlas/grid/route documents and exact-path tests;
   - fitting phase-log archive.
2. **Test-contract repair**
   - update stale Balanced preset expectations;
   - diagnose the exact FitTool/direct Cp equality characterization failure;
   - separate genuine regressions from obsolete assertions.
3. **Diagnostic and compatibility audit**
   - diagnostic runtime/value review;
   - `aeCopyLegacyResultFolder`;
   - shared Rayleigh-Lamb mRLFE compatibility fields;
   - old `solveMRLFEBranch` implementation.

High-risk compatibility or solver-layer work must use separate model-focused
branches and must not be combined with documentation cleanup.

## Next development guidance

1. Update local `main` from `origin/main` and confirm the merge SHA.
2. Read the persistent project documents before opening task-specific contracts.
3. Summarize the current state and compare a maximum of three next objectives.
4. Do not create a branch or modify files until the user selects the objective.
5. After selection, create one dedicated branch from updated `origin/main`.
6. Keep changes small, localized, validated, and ready for manual user merge.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- `docs/repository/maintained_entrypoints.md`
- `docs/repository/validation_status.md`
- `docs/repository/repository_hygiene_plan.md`
- `docs/repository/repository_cleanup_audit_2026-07-14.md`
- `docs/repository/repository_cleanup_phase1_report.md`
- `docs/workflows/gui/adapter_architecture.md`
- `docs/workflows/fitting/architecture.md`
- `docs/models/mrlfe/README.md`
- `docs/models/acoustoelastic_iop_hgo/documentation_index.md`
