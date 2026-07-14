# Test-suite audit brief

## Purpose

Audit the complete MATLAB test surface under `tests/` before any cleanup or
reorganization. The audit must produce evidence for later, smaller implementation
PRs. This phase is not permission to move, rename, delete, merge, or rewrite
broad test families.

## Repository state

- Repository: `cpariona/Lamb-fundamental-solver`
- Baseline: updated `origin/main` after PR #111
- Last known good merge: `09f9a2d81dc974f930965a4da87983816984bd14`
- Audit work must use a dedicated branch created from updated `origin/main`.

## Why this audit is needed

The current suite has a generally sound top-level organization, but its runtime
and ownership boundaries are difficult to reason about:

- root-level runner wrappers coexist with implementations under `tests/runners/`;
- some wrappers may be intentional compatibility entrypoints but are not fully
  documented;
- some test implementations remain outside the target layout;
- several runners overlap and execute the same tests;
- some smoke runners include fitting, regression, integration, characterization,
  or performance work;
- extended matrices and benchmarks appear alongside ordinary contract tests;
- the large flat `tests/models/mrlfe/` folder contains several distinct families;
- static calls may not capture MATLAB dynamic dispatch.

## Current target layout

The maintained target is:

```text
tests/
├─ runners/
├─ shared/
├─ models/
└─ app/
```

Root-level or legacy-folder MATLAB files are allowed only when they are deliberate
compatibility wrappers. Read `tests/README.md` before classifying them.

Known candidates for special review include, but are not limited to:

```text
tests/analysis/test_sweep_plot_renderer_contract.m
tests/fitting/test_gui_prepare_experimental_fit_data.m
tests/fitting/test_gui_read_experimental_fit_file.m
tests/fitting/run_fit_validation_tests.m
tests/run_main_gui_export_tests.m
tests/run_mrlfe_production_core_tests.m
tests/run_mrlfe_public_contract_tests.m
```

Do not assume these files are misplaced or removable until wrapper and consumer
checks are complete.

## Required audit outputs

### 1. Complete test inventory

Inventory every tracked MATLAB file under `tests/` and record at least:

- repository-relative path;
- basename / MATLAB entrypoint;
- type: test, runner implementation, compatibility wrapper, helper, fixture, or
  unknown;
- owning area: app, model family, shared infrastructure, analysis, or legacy;
- inferred category: contract, smoke, regression, integration,
  characterization, diagnostic, benchmark/performance, or helper;
- static numerical-cost indicators;
- direct callers;
- runner membership;
- duplicate runner membership count;
- whether it is reachable from `run_all_smoke_tests`;
- whether it is documented as maintained;
- recommended action: retain, document, move later, split later, redesign later,
  investigate, or removal candidate;
- confidence and evidence.

### 2. Runner graph

Build a static graph covering:

```text
public/root wrapper -> maintained runner -> nested runner/test/helper
```

For each runner, report:

- directly invoked tests and runners;
- transitive test set;
- duplicated tests relative to other runners;
- whether it is reachable from `run_all_smoke_tests`;
- inferred category and expected cost;
- inconsistent counters/comments or stale labels;
- wrapper/implementation relationship.

### 3. Unregistered and duplicate coverage

Identify:

- tests not called by any maintained runner;
- tests called only through undocumented runners;
- tests called by multiple runners;
- runners with substantially overlapping transitive sets;
- exact or near-duplicate tests based on purpose and implementation;
- tests that only verify path availability versus tests that execute numerical
  behavior.

Do not classify a test as dead solely because static search finds no caller.
Search for dynamic MATLAB invocation patterns and record residual uncertainty.

### 4. Runtime and scope classification

Classify tests using evidence, not names alone:

| Category | Intended role |
| --- | --- |
| contract | schema, validation, metadata, names, routes, path/absence checks |
| smoke | one small representative execution |
| regression | deterministic numerical comparison or fixture |
| integration | multiple surfaces/models/routes |
| characterization | broad behavioral mapping without a simple pass threshold |
| diagnostic | troubleshooting or exploratory numerical evidence |
| benchmark/performance | timing, scaling, repeated runs, or hardware-sensitive work |
| helper | shared assertion, fixture, or runner utility |

Suggested runtime budgets are planning guidance, not facts unless measured:

```text
contract: target < 2 s
smoke: target < 10 s
regression: target < 30 s
integration: explicit and separate
characterization/diagnostic/benchmark: manual or extended validation
```

Known measured evidence:

- `test_execution_profile_validation_matrix` passed all 36 combinations in about
  178.7 seconds on the user's machine. It must be treated as extended integration
  validation, not routine smoke.
- broad suites have previously exceeded practical interactive timeouts.

Do not invent per-test timings. Provide a MATLAB timing plan for the user where
measurements are needed.

### 5. Staged cleanup plan

Recommend small future PRs in dependency-safe order. At minimum distinguish:

1. documentation and wrapper inventory fixes;
2. low-risk relocation of files outside the target layout;
3. separation of quick contracts/smoke from extended tests;
4. redesign of obsolete benchmarks and heavy characterization;
5. optional subdivision of large flat folders such as
   `tests/models/mrlfe/` only after runner ownership is stable;
6. deletion only for candidates with strong static and dynamic evidence.

For every proposed phase, include:

- exact scope;
- risks;
- files likely affected;
- required MATLAB validation;
- whether compatibility wrappers are needed;
- rollback strategy.

## Specific known concerns to verify

- `run_all_smoke_tests` delegates to core, GUI, AE, mRLFE, and legacy cleanup
  groups; determine its transitive cost and duplicated coverage.
- `run_core_smoke_tests` includes synthetic RL and mRLFE fitting tests.
- `run_gui_smoke_tests` has inconsistent progress counters and mixes GUI,
  fitting, and execution-profile contracts.
- execution-profile runners overlap.
- `test_execution_profile_validation_matrix` is extended integration.
- `test_mrlfe_execution_profile_benchmark_contract` and
  `analysis/execution_profiles/benchmarkMRLFEExecutionProfiles.m` still describe
  the former mapped-to-Fast policy and require a separate diagnostic redesign.
- `run_mrlfe_production_core_tests` mixes contracts, characterization, and
  performance.
- root-level wrappers must be compared against `tests/README.md` and
  `docs/repository/maintained_entrypoints.md`.

These are audit hypotheses, not predetermined conclusions.

## Dynamic invocation checks

Search for at least:

```text
eval
feval
run
runtests
which
str2func
function handles
script names stored in strings/cells/structs
generated inventories or path-based dispatch
```

Report where static analysis cannot establish reachability.

## Allowed changes in the audit task

The audit task may create or update only audit artifacts and directly related
project handoff documentation, for example:

```text
docs/repository/test_suite_audit.md
docs/project/active_context.md
docs/project/session_handoff.md
analysis/test_inventory/buildTestInventory.m
analysis/test_inventory/README.md
analysis/test_inventory/test_inventory.csv
analysis/test_inventory/runner_edges.csv
```

A generator script is preferred when it makes the inventory reproducible.
Generated CSV files may be committed only when stable, useful, and clearly marked
as generated evidence. Do not create large binary artifacts.

## Forbidden changes in the audit task

- no test moves, renames, deletions, or broad rewrites;
- no runner membership changes;
- no wrapper behavior changes;
- no production-code changes;
- no solver, GUI, fitting, sweep, numerical-grid, fallback, or branch-policy
  changes;
- no benchmark redesign in this audit branch;
- no claims that MATLAB tests passed unless actually executed;
- no PR or merge unless explicitly requested.

## Validation for the audit task

Static validation must include:

```bash
git status -sb
git diff --check
git diff --stat
git diff
```

Also validate the generated inventory for:

- one row per tracked MATLAB file under `tests/`;
- unique repository-relative paths;
- resolvable runner edges where static calls are explicit;
- explicit handling of wrappers and helpers;
- documented limitations for dynamic calls.

If a MATLAB inventory script is created, provide exact MATLAB commands for the
user to run. Codex must not claim those commands passed unless it actually has a
MATLAB runtime and executed them.

## Expected final report

- branch and base SHA;
- files created and changed;
- inventory counts by type/category/folder;
- wrapper list;
- runner graph summary;
- unregistered-test candidates;
- highest-overlap runners;
- likely heavy/extended tests;
- files outside target layout;
- staged cleanup recommendation;
- exact static checks performed;
- MATLAB commands still required from the user;
- known uncertainties;
- final working tree status.
