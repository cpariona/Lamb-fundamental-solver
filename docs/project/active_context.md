# Active project context

Last reviewed: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Default branch: main

## Current development focus

The mRLFE public-solver migration is complete and merged. The active development
phase is now a repository-wide hygiene and cleanup audit covering documentation,
examples, diagnostics, generated artifacts, compatibility wrappers, tests, and
potentially orphaned MATLAB files.

The cleanup objective is to reduce obsolete or misleading repository content
without changing maintained solver, GUI, fitting, sweep, or validation behavior.
The existing audit is the starting point:

```text
docs/repository/repository_cleanup_audit_2026-07-14.md
```

The audit is evidence and a candidate list, not authorization for bulk deletion.
Every deletion, move, consolidation, or rename requires dependency checks and
focused validation.

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
- Post-merge documentation refresh.
- Initial repository cleanup audit and phased cleanup proposal.

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
- The user performs merges manually unless explicitly requesting another workflow.

## Cleanup operating rules

1. Do not work directly on `main`; create a dedicated branch from updated `origin/main`.
2. Begin with an audit and dependency map before deleting or moving files.
3. Use exact symbol, filename, documentation-link, runner-registration, and fixture searches.
4. Treat MATLAB dynamic invocation, function handles, path-based discovery, and compatibility wrappers as possible hidden dependencies.
5. Keep cleanup batches small, coherent, and reversible.
6. Do not mix repository hygiene with solver behavior changes or feature work.
7. Do not rename maintained entrypoints, runners, or public files without checking naming/path contract tests.
8. Do not claim tests passed unless they were executed.
9. Do not rerun the two-day extended grid matrix unless solver or grid-policy behavior changes.
10. Preserve useful historical evidence only when it has a clear archive purpose; Git history alone may be sufficient for superseded phase logs.

## Validation status

The mRLFE migration passed its focused public-contract, production-core, GUI,
SweepTool, FitTool, execution-profile, fit-grid, and targeted grid-validation
checks before merge.

Cleanup work must select validation according to changed content. Relevant
commands are documented in:

```text
docs/repository/validation_status.md
docs/repository/repository_hygiene_plan.md
docs/repository/repository_cleanup_audit_2026-07-14.md
```

At minimum, use `git diff --check` plus exact route/link searches. Code, test,
runner, startup, or path changes require the corresponding MATLAB runners.

## Known limitations

- Existing synthetic and route-contract tests are not external physical validation.
- Grid-quality classifications near marginal branch tails can depend on the internal grid.
- Dense full-matrix validation is expensive and should not be repeated for documentation or repository hygiene alone.
- Historical documents may mention removed mRLFE routes as evidence; those names are not maintained production contracts.
- Some tests intentionally inspect names, paths, runner wrappers, generated inventories, or the absence of legacy routes.
- Repository search alone may miss dynamic MATLAB calls; removal decisions require conservative verification.

## Next development guidance

1. Update local `main` from `origin/main`.
2. Create a dedicated cleanup branch, recommended name `repo-hygiene-phase1-audit`.
3. Read the project and repository documents listed below.
4. Re-audit the full tree and verify each initial candidate independently.
5. Implement only the safest first cleanup batch unless evidence supports a broader change.
6. Commit in small logical units, push the branch, and report results. Do not merge.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- `docs/repository/maintained_entrypoints.md`
- `docs/repository/validation_status.md`
- `docs/repository/repository_hygiene_plan.md`
- `docs/repository/repository_cleanup_audit_2026-07-14.md`
- `docs/workflows/gui/adapter_architecture.md`
- `docs/workflows/fitting/architecture.md`
- `docs/models/mrlfe/README.md`
- `docs/models/acoustoelastic_iop_hgo/documentation_index.md`
