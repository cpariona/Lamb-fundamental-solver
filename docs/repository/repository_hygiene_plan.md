# Repository hygiene cleanup plan

## Purpose

This document defines the repository-wide cleanup process after the mRLFE public
solver migration and post-merge documentation refresh.

The current cleanup phase covers documentation, examples, diagnostics,
generated artifacts, tests, wrappers, CSV snapshots, and potentially orphaned
MATLAB files across all maintained model families.

The first implementation pass remains conservative. No file should be deleted,
moved, consolidated, or renamed solely because it appears old, generated,
legacy-named, duplicated, or unreferenced by one search method.

The current candidate inventory is:

```text
docs/repository/repository_cleanup_audit_2026-07-14.md
```

That audit is a starting point, not an approved deletion manifest.

## Priorities

1. Generated artifacts and obvious orphans with low-to-medium removal risk.
2. Superseded or duplicated documentation and historical migration evidence.
3. Diagnostic examples whose maintained purpose is unclear or no longer valid.
4. Compatibility helpers, runner wrappers, and similarly named solver layers.
5. AE IOP/HGO audits and legacy-named helpers after model-specific dependency review.
6. Rayleigh-Lamb documentation, examples, and validation assets.

## Cleanup rules

### Keep

Keep files that are one of the following:

- Maintained API, architecture, workflow, branch-policy, or validation documentation.
- Smoke, regression, or contract tests that guard current behavior or repository structure.
- Public examples that demonstrate a supported workflow.
- Diagnostics that reproduce an unresolved numerical issue or provide unique maintained evidence.
- Compatibility wrappers that remain part of documented user commands or startup/test routing.
- Generated assets intentionally used as fixtures or referenced documentation examples.

### Archive

Archive files that remain historically useful but no longer represent active
workflow, current validation evidence, or maintained requirements.

Archived files must clearly state that they are historical and must not be
presented as maintained API, current behavior, or required validation.

### Consolidate

Consolidate documents, wrappers, or reports only when:

- their responsibilities overlap materially;
- inbound references can be repaired safely;
- unique evidence is retained;
- naming and path contracts are not broken.

### Delete

Delete files only when all applicable conditions are satisfied:

- no maintained code caller or dynamic invocation dependency is found;
- no active documentation, README, registry, runner, fixture, or CSV dependency remains;
- the behavior or evidence is superseded or no longer required;
- the file is not needed to reproduce an unresolved issue;
- a maintained replacement exists when replacement is necessary;
- focused validation passes after removal;
- exact searches confirm no stale references remain.

## Mandatory evidence before changing a candidate

For every candidate, record:

1. exact path;
2. classification: retain, archive, consolidate, remove, or defer;
3. exact symbol and filename searches;
4. code callers and possible dynamic invocation;
5. documentation and README links;
6. runner, registry, callback, fixture, inventory, and path references;
7. replacement coverage or reason no replacement is needed;
8. validation selected for the change;
9. final result and remaining risk.

Store this evidence in the cleanup audit or a dedicated phase report under
`docs/repository/`.

## Critical model distinctions

- Removed mRLFE atlas/direct-visco production routes are historical only.
- AE IOP/HGO still uses maintained atlas terminology, policies, tests, examples,
  and diagnostics. Do not remove AE atlas content based on mRLFE cleanup rules.
- Similar filenames do not prove duplication. For example, solver wrappers may
  represent distinct public, orchestration, and numerical layers.
- Root-level test runners may intentionally be compatibility wrappers around
  implementations under `tests/runners/`.

## Recommended cleanup phases

### Phase 1 — generated artifacts and obvious orphans

Audit and, only when verified, clean:

- unreferenced `.fig` outputs under `examples/**/sweeps/figures/`;
- unreferenced or redundant PNG outputs while retaining an intentional curated set;
- `app/fitting/guiEvaluateFitFullCurve.m` if exact and dynamic dependency checks confirm it is orphaned;
- unregistered legacy-named mRLFE tests if they no longer test a maintained or cleanup contract;
- generated or stale CSV snapshots if no test, fixture, or documentation contract consumes them;
- empty tracked directories or isolated obsolete notes.

Expected risk: low-to-medium.

### Phase 2 — documentation consolidation

- consolidate fitting phase logs when unique evidence can be retained;
- archive or consolidate mRLFE migration evidence outside active contract locations;
- classify completed AE audits as active, archive, consolidate, or remove;
- repair all indexes and inbound links;
- ensure active documentation describes only maintained routes.

Expected risk: low-to-medium.

### Phase 3 — diagnostic examples

For every diagnostic, document:

- maintained purpose;
- public entrypoint used;
- expected runtime;
- last known successful execution or static validity evidence;
- unique evidence not covered by tests;
- output location and whether generated outputs are ignored.

Retain maintained diagnostics, archive expensive one-off studies, and remove
broken or superseded scripts only after verification.

Expected risk: medium.

### Phase 4 — compatibility helpers, runners, and solver layers

- map root runner wrappers to canonical runner implementations;
- audit AE legacy-named helpers and their callers;
- inspect similarly named mRLFE solver functions by responsibility and call graph;
- remove compatibility layers only with complete dependency evidence and broad validation.

Expected risk: high.

## Validation policy

Always run:

```bash
git status -sb
git diff --stat
git diff --check
git diff
```

Also run exact symbol, filename, documentation-link, runner-registration,
fixture, inventory, and path searches for every changed candidate.

### Documentation and generated artifacts

Use relevant link/path searches and focused smoke groups. If no runtime code,
runner, fixture, or path contract changes, do not claim broad MATLAB validation
unless it was actually executed.

### mRLFE code, diagnostics, or tests

Select applicable runners from:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_neutral_production_helper_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_legacy_cleanup_tests
run_mrlfe_smoke_tests
```

### AE IOP/HGO changes

```matlab
run_acoustoelastic_smoke_tests
run_fit_validation_tests
```

Use only the fitting validation portions needed by the changed scope when the
full suite is unnecessarily expensive.

### Runner, startup, or path changes

```matlab
test_startup_path_policy
test_repository_root_utilities
run_all_smoke_tests
```

### Broad cleanup before review

```matlab
run_all_smoke_tests
```

Do not rerun the extended two-day mRLFE grid matrix unless solver or grid-policy
behavior changes.

## Branch and delivery policy

- Never perform cleanup implementation directly on `main`.
- Update local `main` from `origin/main` first.
- Use one dedicated feature branch for the first conservative cleanup batch.
- Recommended initial branch: `repo-hygiene-phase1-audit`.
- Keep commits small, logical, and reversible.
- Do not mix solver behavior changes or feature work with hygiene changes.
- Push only after validation and review of the complete diff.
- Do not merge; the user performs merges manually.
- Do not open a PR unless explicitly requested.

## Expected completion report

The final report must include:

- branch and base SHA;
- audit methodology;
- files retained, archived, consolidated, removed, and deferred;
- dependency evidence for changed candidates;
- exact commits and final SHA;
- exact validation commands and results;
- known risks and unverified assumptions;
- final working tree status;
- recommendation for the next cleanup phase.
