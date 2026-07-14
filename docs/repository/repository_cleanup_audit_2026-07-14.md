# Repository cleanup audit — 2026-07-14

## Scope

This audit reviews the current repository tree after the mRLFE public-solver migration and the documentation refresh. The objective is to identify files that may be obsolete, generated, duplicated, historical, unreferenced, or misleading.

No files are deleted by this audit. Every candidate must pass dependency and test checks before removal.

The supplied repository tree contains approximately:

- 422 MATLAB files;
- 116 Markdown files;
- 17 MATLAB figure files;
- 17 PNG figure files;
- 2 tracked CSV result/inventory files.

## Classification

Candidates are classified as:

- **Remove candidate**: likely obsolete or generated, with no known maintained dependency.
- **Archive candidate**: useful only as historical evidence and should not remain in an active documentation or example location.
- **Consolidate candidate**: overlapping documents or wrappers that may be reduced to one maintained source.
- **Retain pending verification**: suspicious name or legacy content, but removal risk is not yet understood.

## High-confidence candidates

### 1. Generated example figures

Tracked outputs under:

```text
examples/**/sweeps/figures/**/*.fig
examples/**/sweeps/figures/**/*.png
```

Current tree contains 17 `.fig` and 17 `.png` files.

Assessment:

- `.fig` files are binary generated artifacts and are poor review targets.
- PNG files may be useful as documentation examples, but they should be explicitly referenced by maintained documentation.
- Generated outputs should normally be written to `analysis_output` or another ignored output directory.

Recommendation:

1. Verify whether any Markdown or README file references each PNG.
2. Remove all unreferenced `.fig` files.
3. Remove unreferenced PNGs or retain a small curated subset.
4. Add matching ignore rules so regenerated outputs are not recommitted.

Risk: low for `.fig`; low-to-medium for PNG.

### 2. Orphaned FitTool helper

Candidate:

```text
app/fitting/guiEvaluateFitFullCurve.m
```

Repository search found the function itself and documentation references, but no maintained code or test invocation. The active workflow now uses:

```text
guiBuildFitDisplayCurve

guiEvaluateRequestedFitCurve
```

Recommendation:

- verify with a MATLAB dependency scan and exact symbol search;
- remove the function if no dynamic invocation exists;
- update remaining documentation references in the same change.

Risk: medium because MATLAB permits indirect calls by string/function handle.

### 3. Unregistered legacy-named mRLFE tests

Candidates:

```text
tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_opt_in_contract.m
tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_s0_guard_contract.m
```

The maintained legacy-cleanup runner executes only:

```text
test_mrlfe_no_legacy_routes
test_mrlfe_no_legacy_route_flags
test_mrlfe_legacy_cleanup_characterization
```

The two delayed-direct-visco tests are not found in maintained runners and refer to route terminology removed from production.

Recommendation:

- inspect whether they still execute successfully;
- determine whether they test deleted code, only static absence, or obsolete compatibility behavior;
- remove if they are not part of a maintained runner and no longer test a supported contract.

Risk: medium.

### 4. Generated or stale CSV snapshots

Candidates:

```text
analysis/execution_profiles/execution_profile_inventory.csv
analysis/performance/execution_profile_benchmark_results.csv
```

Assessment:

- both appear to be generated outputs rather than source inputs;
- the execution-profile inventory still contains references to removed legacy-named tests;
- benchmark results may become stale whenever hardware, presets, or solver code changes.

Recommendation:

- confirm whether tests read these files as fixtures;
- if not required, move them to ignored output folders or replace them with Markdown summaries containing provenance;
- regenerate inventory only through its script and avoid treating it as maintained source.

Risk: medium because a contract test may parse them.

## Strong archive candidates

### 5. mRLFE historical documents in active locations

Candidates:

```text
docs/models/mrlfe/atlas_policy_notes.md
docs/models/mrlfe/fittool_grid_path_sensitivity.md
docs/models/mrlfe/docs_cleanup_audit.md
docs/validation/mrlfe_legacy_route_inventory.md
docs/validation/mrlfe_solver_route_audit.md
docs/validation/mrlfe_solver_route_quick_results.md
```

These documents preserve migration evidence but are not active production contracts. Several describe deleted atlas routes or transitional fitting behavior.

Recommendation:

- retain only current contract documents in the active mRLFE root:
  - `README.md`
  - `public_api.md`
  - `production_core.md`
  - `fitting_workflow.md`
  - `current_sweeps.md`
- move historical evidence to `docs/models/mrlfe/archive/` or consolidate it into one migration-history document;
- update links before moving files.

Risk: low-to-medium due to documentation-link tests or grep-based contracts.

### 6. Phase-by-phase fitting logs

Candidates:

```text
docs/archive/fitting_phase_logs.md
docs/archive/fitting_phases/fitting_phase1_status.md
...
docs/archive/fitting_phases/fitting_phase11_status.md
```

Assessment:

- these are explicitly archived;
- eleven status documents plus a summary create substantial duplication;
- the information is available in Git history and may no longer justify repository maintenance.

Recommendation:

- consolidate into one `fitting_migration_history.md` if the history is still useful;
- otherwise remove the individual phase files after checking inbound links.

Risk: low.

### 7. AE IOP/HGO completed audits and closure reports

Potentially historical groups:

```text
docs/models/acoustoelastic_iop_hgo/audits/*.md
docs/models/acoustoelastic_iop_hgo/archive/*.md
```

The archive directory is correctly labelled. The audits directory, however, contains many completed reviews that may be mistaken for active requirements.

Recommendation:

- classify each audit as active checklist, unresolved work, or completed evidence;
- move completed audits into archive or consolidate them;
- retain only documents that define current unresolved actions.

Risk: medium because AE development may still rely on some audit conclusions.

## Code and example candidates requiring dependency verification

### 8. mRLFE diagnostic examples containing removed route language

Candidates include:

```text
examples/mrlfe/diagnostics/diagnose_mrlfe_atlas_primary_policy_matrix.m
examples/mrlfe/diagnostics/diagnose_etaS_forward_cache.m
examples/mrlfe/diagnostics/diagnose_fit_option_sensitivity.m
examples/mrlfe/diagnostics/diagnose_fit_timing.m
examples/mrlfe/diagnostics/diagnose_mrlfe_gui_performance_32kHz.m
examples/mrlfe/diagnostics/diagnose_mrlfe_visco_residual_landscape.m
examples/mrlfe/diagnostics/diagnose_mrlfe_visco_validity_breakdown.m
examples/mrlfe/diagnostics/stress_test_mrlfe_real_k_range.m
```

Assessment:

- some may still be valid public-solver diagnostics;
- `diagnose_mrlfe_atlas_primary_policy_matrix.m` is especially suspicious after atlas-route removal;
- diagnostic scripts are often not covered by smoke tests and may silently rot.

Recommendation:

For each script, record:

1. maintained purpose;
2. public entrypoint used;
3. expected runtime;
4. last known successful execution;
5. whether it produces unique evidence not covered by tests.

Remove or archive scripts that fail this checklist.

Risk: medium-to-high.

### 9. AE compatibility and legacy helper functions

Suspicious names include:

```text
aeCopyLegacyResultFolder.m
aeRunLegacyScript.m
aeDeleteExampleFigure.m
aeResolveResultFile.m
```

These may be intentional migration helpers, but their names indicate compatibility debt.

Recommendation:

- trace all callers;
- retain only when used by maintained examples or migration tooling;
- otherwise remove in an AE-specific cleanup phase.

Risk: high until callers are mapped.

### 10. Duplicate or compatibility runner entrypoints

The tree contains runners both at:

```text
tests/run_*.m
tests/runners/run_*.m
```

Some root files may be compatibility wrappers. Removing them may break user commands, documentation, or CI.

Recommendation:

- build a runner map identifying canonical implementation and wrappers;
- keep one public command per validation group;
- remove wrappers only after updating all references and tests.

Risk: high.

### 11. Potentially duplicated mRLFE solver entrypoints

Candidates requiring review:

```text
models/mrlfe/solvers/mrlfeSolveBranch.m
models/mrlfe/solvers/solveMRLFEBranch.m
```

The similar names may represent distinct layers or a retained legacy implementation.

Recommendation:

- compare responsibilities and callers;
- rename only if both are maintained and semantically distinct;
- remove one only after call-graph verification and public-contract tests.

Risk: high.

## Repository-structure candidates

### 12. `.agents`

The tree shows a top-level `.agents` directory with no listed contents.

Recommendation:

- determine whether it is actually tracked or only present locally;
- remove if empty and unused.

Risk: low.

### 13. `references/PYTHON_REPO_NOTES.md`

This single-file references directory may be project history, external implementation notes, or obsolete migration context.

Recommendation:

- inspect content and inbound links;
- move to model documentation, archive it, or remove it if it has no current purpose.

Risk: low.

## Documents likely retained

The following groups should remain unless a later audit finds direct duplication:

- public API documents;
- production-core documents;
- current fitting and sweep workflows;
- ADRs;
- repository structure and naming contracts;
- current validation commands;
- model README/index files;
- active AE branch-policy and public-API documentation.

## Tests and safeguards

Several tests are intentionally coupled to names, paths, or the absence of legacy routes. Cleanup must therefore use these safeguards.

### Static checks before each deletion batch

```text
exact symbol search
exact filename search
README and Markdown link search
runner registration search
inventory/CSV reference search
```

### MATLAB checks by cleanup category

Documentation and generated artifacts:

```matlab
run_core_smoke_tests
run_gui_smoke_tests
```

mRLFE code, diagnostics, or tests:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_legacy_cleanup_tests
run_mrlfe_smoke_tests
```

AE helpers, examples, or documentation contracts:

```matlab
run_acoustoelastic_smoke_tests
run_fit_validation_tests
```

Runner consolidation or startup/path changes:

```matlab
test_startup_path_policy
test_repository_root_utilities
run_all_smoke_tests
```

## Recommended cleanup phases

### Phase 1 — generated artifacts and obvious orphans

- remove unreferenced `.fig` files;
- classify PNG outputs;
- verify and remove `guiEvaluateFitFullCurve.m` if orphaned;
- inspect and remove unregistered delayed-direct-visco tests;
- classify generated CSV snapshots.

Expected risk: low-to-medium.

### Phase 2 — documentation consolidation

- consolidate fitting phase logs;
- archive mRLFE migration evidence;
- classify completed AE audits;
- repair all links and indexes.

Expected risk: low.

### Phase 3 — diagnostic examples

- execute or statically validate each diagnostic;
- retain only diagnostics with a documented maintained purpose;
- archive expensive one-off studies and remove broken scripts.

Expected risk: medium.

### Phase 4 — compatibility helpers and runners

- map root runners to canonical runners;
- audit AE legacy helpers;
- inspect similar mRLFE solver entrypoints;
- remove compatibility layers only with complete caller evidence.

Expected risk: high.

## Initial decision

The repository is not ready for a single broad deletion commit. The safest first implementation batch is:

1. generated figures;
2. the apparently orphaned FitTool full-curve helper;
3. the two unregistered delayed-direct-visco tests;
4. stale generated CSV snapshots.

Each item should be verified independently and committed in small, reversible changes.