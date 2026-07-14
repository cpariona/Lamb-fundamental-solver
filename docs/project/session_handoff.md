# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current branch: main

## Current state

PR #109 is merged. The mRLFE public production architecture is stable and the
post-merge documentation refresh is complete.

The active task is now repository hygiene. An initial audit has already been
created:

```text
docs/repository/repository_cleanup_audit_2026-07-14.md
```

That document contains candidate files and recommended phases. It is not a bulk
deletion list. Each candidate must be verified against code references,
documentation links, runners, fixtures, dynamic MATLAB invocation, and focused
tests before removal or relocation.

## Required branch setup

Do not modify `main` directly for the cleanup implementation.

Start with:

```bash
git fetch origin
git switch main
git pull --ff-only origin main
git status -sb
git switch -c repo-hygiene-phase1-audit
```

If that branch name already exists, use a similarly scoped new branch created
from the updated `origin/main` state.

## Cleanup objective

Perform a complete repository audit and implement a conservative first cleanup
batch. The work may cover documentation, generated artifacts, examples,
diagnostics, tests, CSV snapshots, wrappers, and orphaned MATLAB helpers, but it
must preserve maintained behavior.

The first implementation batch should prioritize low-to-medium-risk candidates:

1. generated or unreferenced sweep figures;
2. the possibly orphaned `app/fitting/guiEvaluateFitFullCurve.m` helper;
3. unregistered legacy-named mRLFE tests;
4. generated or stale CSV snapshots;
5. clearly superseded documentation that can be consolidated or archived safely.

Do not assume any candidate is removable merely because its name appears legacy
or because a text search has no result.

## Mandatory reading

Read in this order before changing files:

1. `docs/project/README.md`
2. `docs/project/active_context.md`
3. `docs/project/session_handoff.md`
4. `docs/repository/repository_structure.md`
5. `docs/repository/naming_strategy.md`
6. `docs/repository/maintained_entrypoints.md`
7. `docs/repository/validation_status.md`
8. `docs/repository/repository_hygiene_plan.md`
9. `docs/repository/repository_cleanup_audit_2026-07-14.md`
10. task-specific model/workflow documents for every candidate being changed

## Critical safeguards

- No solver-physics, GUI behavior, fitting behavior, sweep behavior, or execution-profile behavior changes.
- Do not remove or rename maintained public APIs, model entrypoints, GUI adapters, runners, compatibility wrappers, or tests without complete caller/reference evidence.
- AE IOP/HGO still uses valid atlas terminology. Do not apply mRLFE legacy-atlas conclusions to AE files.
- Some tests inspect exact filenames, paths, strings, runner wrappers, inventories, or absence of legacy routes.
- MATLAB may invoke code dynamically through strings, function handles, callbacks, paths, or registries.
- Generated files may still serve as test fixtures or documentation assets.
- Preserve a small curated PNG set only when it is intentionally referenced; binary `.fig` files require stronger justification to remain tracked.
- Do not rerun the extended two-day mRLFE grid matrix for cleanup-only changes.
- Do not open a PR or merge unless explicitly requested. Push the branch and report it for user review.

## Required audit evidence for each candidate

Before deleting, moving, consolidating, or renaming a file, record:

1. exact path and classification: retain, archive, consolidate, or remove;
2. exact symbol and filename search results;
3. inbound code callers or lack thereof;
4. documentation and README links;
5. runner, registry, fixture, CSV, or path references;
6. potential dynamic invocation risk;
7. replacement coverage, if any;
8. validation needed after the change.

Keep this evidence in an updated cleanup audit or a new phase report under
`docs/repository/`.

## Validation guidance

Always run:

```bash
git diff --check
```

Also run exact repository searches for every removed or moved name.

Select MATLAB validation by scope:

- documentation/generated artifacts: focused smoke groups and link/path searches;
- mRLFE code/tests/diagnostics: public-contract, production-core, FitTool, legacy-cleanup, and mRLFE smoke runners as applicable;
- AE files: acoustoelastic smoke and fitting validation as applicable;
- runner/startup/path changes: startup utilities and `run_all_smoke_tests`;
- broad cleanup before review: `run_all_smoke_tests`.

Do not claim a MATLAB runner passed unless it was actually executed. If MATLAB is
unavailable, report that limitation and stop short of high-risk deletion.

## Commit and delivery rules

- Prefer small coherent commits by category.
- Avoid one large deletion commit.
- Record exact commit SHAs.
- Push the cleanup branch.
- Do not merge.
- Final report must include retained candidates as well as removed candidates.

## Expected final report

- branch name and base SHA;
- audit methodology;
- files retained, archived, consolidated, removed, or deferred;
- dependency evidence for each changed candidate;
- commits and final SHA;
- exact validation commands and results;
- known open risks;
- final `git status -sb`;
- recommended next cleanup phase.
