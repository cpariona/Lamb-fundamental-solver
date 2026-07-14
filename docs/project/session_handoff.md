# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current audit branch: `test/test-suite-audit-2026-07-14`
Baseline: `origin/main` at `d3fcfd0c6a279df72b3e11caf7684e77f21c3aae` (PR #112, including PR #111)

## Completed in this audit

The complete tracked MATLAB test surface was audited without changing tests,
runners, wrappers, solvers, GUI code, fitting code, sweep code, or numerical
behavior.

Artifacts:

```text
docs/repository/test_suite_audit.md
analysis/test_inventory/README.md
analysis/test_inventory/buildTestInventory.m
analysis/test_inventory/test_inventory.csv
analysis/test_inventory/runner_edges.csv
```

The inventory contains 137 MATLAB files: 104 tests, 21 runner implementations,
9 compatibility wrappers, and 3 helpers. It identifies 13 files outside the
target layout, six tests without executable maintained-runner registration, 51
tests reachable from `run_all_smoke_tests`, and concentrated overlap among the
execution-profile runners.

MATLAB executed only the static inventory generator and `checkcode`; no test,
heavy matrix, diagnostic runner, benchmark, or full smoke suite was executed.

## Prior completed baseline

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

Review and, if accepted, manually merge the audit. The first implementation
phase should be documentation-only: align the wrapper list, maintained runner
documentation, and stale GUI smoke counters without changing runner membership.

The authoritative task brief is:

```text
docs/repository/test_suite_audit_brief.md
```

Later implementation must follow the staged plan in the audit report. In
particular, layout changes, quick/extended membership changes, benchmark
redesign, optional mRLFE subdivision, and any deletion must remain separate.

## Verified audit findings

- Nine files are deliberate compatibility wrappers; the README list omits the
  production-core and public-contract mRLFE wrappers.
- The renderer contract and two FitTool import tests are outside the target
  layout and are not wrappers.
- `run_all_smoke_tests` reaches 51 tests, including synthetic fitting and broad
  numerical coverage.
- `run_gui_smoke_tests` mixes GUI, fitting, sweeps and execution profiles, and
  its displayed counters change from `/19` to `/17`.
- Execution-profile runners materially overlap.
- Six tests have no executable static maintained-runner registration; five are
  nevertheless documented as maintained.
- The mRLFE production-core runner mixes contract, characterization and timing.
- The mRLFE execution-profile benchmark still asserts the removed
  mapped-to-Fast policy.

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

## Branch and scope rules for follow-up

- Update local `main` from `origin/main` first.
- Create a new dedicated branch for each implementation phase.
- Never work directly on `main`.
- Do not reuse this audit branch for cleanup implementation.
- Keep audit outputs reproducible and text-based.
- Do not open a PR or merge unless explicitly requested.
- Do not claim MATLAB validation unless it was actually executed.

## Delivered audit artifacts

Outputs:

```text
docs/repository/test_suite_audit.md
analysis/test_inventory/buildTestInventory.m
analysis/test_inventory/README.md
analysis/test_inventory/test_inventory.csv
analysis/test_inventory/runner_edges.csv
```

## Validation expectations for follow-up

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
