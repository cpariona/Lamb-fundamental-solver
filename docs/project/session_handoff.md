# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current documentation branch: `docs/test-suite-audit-context`
Baseline: `origin/main` after merge commit `09f9a2d81dc974f930965a4da87983816984bd14` (PR #111)

## Completed

PR #111, **Align mRLFE test contracts with direct execution profiles**, was
merged into `main`.

It restored the maintained mRLFE and execution-profile contract baseline without
changing solver mathematics, numerical grids, GUI behavior, fitting behavior,
sweep behavior, or public routes.

The user executed and reported passing the focused mRLFE, GUI, fitting, cleanup,
and execution-profile validations recorded in `docs/project/active_context.md`.
The 36-case execution-profile validation matrix passed in approximately 178.7
seconds and is classified as extended integration validation rather than a
lightweight smoke test.

## Selected next objective

Perform a repository-wide audit of the MATLAB test suite before any cleanup or
reorganization.

The authoritative task brief is:

```text
docs/repository/test_suite_audit_brief.md
```

The audit phase must:

- inventory all tracked MATLAB files under `tests/`;
- distinguish tests, runner implementations, public compatibility wrappers,
  helpers, and unknown files;
- build a static runner-to-test graph, including transitive reachability from
  `run_all_smoke_tests`;
- identify duplicate runner membership and unregistered-test candidates;
- classify test purpose and likely cost;
- identify files outside the target layout;
- propose a staged cleanup plan;
- provide MATLAB commands for runtime measurements that Codex cannot execute.

The audit phase must not move, rename, delete, consolidate, or broadly rewrite
tests and runners.

## Known audit hypotheses

These observations require verification and must not be treated as predetermined
cleanup decisions:

- root-level runners may be intentional compatibility wrappers;
- the documented wrapper list may be incomplete;
- `tests/analysis/` and non-wrapper files under `tests/fitting/` may be outside
  the target layout;
- `run_all_smoke_tests` may be too broad for interactive use;
- `run_core_smoke_tests` includes synthetic fitting;
- `run_gui_smoke_tests` mixes several concerns and has inconsistent progress
  counters;
- execution-profile runners overlap;
- `test_execution_profile_validation_matrix` is heavy integration validation;
- `run_mrlfe_production_core_tests` mixes contract, characterization, and
  performance;
- the mRLFE execution-profile benchmark still represents the former
  mapped-to-Fast policy and needs a separate redesign task.

## Required reading for Codex

Read in order:

1. `docs/project/README.md`
2. `docs/project/active_context.md`
3. `docs/project/session_handoff.md`
4. `docs/project/templates/codex_task.md`
5. `docs/repository/test_suite_audit_brief.md`
6. `docs/repository/repository_structure.md`
7. `docs/repository/naming_strategy.md`
8. `docs/repository/maintained_entrypoints.md`
9. `docs/repository/validation_status.md`
10. `docs/repository/repository_hygiene_plan.md`
11. `tests/README.md`

Then inspect the complete tracked `tests/` tree and every runner before creating
or modifying audit artifacts.

## Branch and scope rules

- Update local `main` from `origin/main` first.
- Create a dedicated audit branch, suggested name:
  `test/test-suite-audit`.
- Never work directly on `main`.
- Do not reuse `docs/test-suite-audit-context` for the Codex audit implementation.
- Keep audit outputs reproducible and text-based.
- Do not open a PR or merge unless explicitly requested.
- Do not claim MATLAB validation unless it was actually executed.

## Expected audit deliverables

Recommended outputs:

```text
docs/repository/test_suite_audit.md
analysis/test_inventory/buildTestInventory.m
analysis/test_inventory/README.md
analysis/test_inventory/test_inventory.csv
analysis/test_inventory/runner_edges.csv
```

Codex may adjust exact artifact names if a clearer structure is justified, but
must remain within the audit-only scope.

## Validation expectations

At minimum:

```bash
git status -sb
git diff --check
git diff --stat
git diff
```

If a MATLAB inventory or timing helper is added, Codex must provide exact MATLAB
commands for the user and report them as not executed unless Codex actually has a
working MATLAB runtime.

## Working rules

- Audit before editing.
- One branch per task.
- Preserve maintained entrypoints and wrapper compatibility.
- Treat static reachability as evidence, not proof, when dynamic MATLAB calls are
  possible.
- Separate audit findings from implementation recommendations.
- Prefer multiple small cleanup PRs over one broad reorganization.
- The user performs merges manually.
