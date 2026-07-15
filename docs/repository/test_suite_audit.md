# MATLAB test-suite audit

Cleanup phase 1 runtime measurements and their limitations are recorded in
`docs/repository/test_suite_runtime_evidence.md`. The original static audit
counts and graph conclusions remain the baseline; no runner membership changed.

Audit date: 2026-07-14
Branch: `test/test-suite-audit-2026-07-14`
Base: `d3fcfd0c6a279df72b3e11caf7684e77f21c3aae` (`origin/main`)

## Executive summary

This audit inventories every Git-tracked MATLAB file under `tests/`, models the
static runner graph, and proposes later cleanup work. It does not modify test
membership, wrappers, production code, or numerical behavior.

The tracked suite contains **137 MATLAB files**: **104 tests**, **21 runner
implementations** (20 under `tests/runners/` plus one standalone root runner),
**9 compatibility wrappers**, **3 helpers**, **0 fixtures**, and **0 unknown
files**. Thirteen files are outside the target top-level layout: nine root files,
one file under `tests/analysis/`, and three under `tests/fitting/`. Ten of those
thirteen have an intentional public-entrypoint role; three are misplaced test
implementations.

Static graph analysis found 149 edges, 51 tests reachable from
`run_all_smoke_tests`, six tests with no executable maintained-runner
registration, and 55 tests with more than one transitive maintained-runner
membership. Most of the 55 are legitimate aggregation through
`run_all_smoke_tests`; the material non-parent overlap is concentrated in the
execution-profile runners and a few focused/standalone runners.

Highest-priority cleanup opportunities are documentation-only wrapper alignment,
relocation of the three misplaced tests without changing membership, explicit
separation of quick and extended validation, and redesign of the obsolete
mapped-to-Fast benchmark. No file has sufficient evidence for
`removal_candidate` in this audit.

### Inventory counts

| File type | Count |
| --- | ---: |
| test | 104 |
| runner | 21 |
| compatibility_wrapper | 9 |
| helper | 3 |
| fixture | 0 |
| unknown | 0 |

| Category | Count |
| --- | ---: |
| contract | 76 |
| smoke | 16 |
| regression | 8 |
| integration | 23 |
| characterization | 6 |
| diagnostic | 2 |
| benchmark_performance | 3 |
| helper | 3 |

| Top-level location below `tests/` | Count |
| --- | ---: |
| root | 9 |
| app | 39 |
| models | 49 |
| runners | 20 |
| shared | 16 |
| analysis | 1 |
| fitting | 3 |

| Model or surface | Count |
| --- | ---: |
| mrlfe | 64 |
| fitting | 19 |
| execution_profiles | 16 |
| acoustoelastic_iop_hgo | 15 |
| shared | 10 |
| gui | 6 |
| rayleigh_lamb | 4 |
| sweeps | 3 |

The model/surface field identifies primary ownership, not every dependency. For
example, an mRLFE FitTool test is assigned to mRLFE when the model-specific
contract dominates.

## Method and reproducibility

The audit used `git ls-files 'tests/*.m' 'tests/**/*.m'` as the authoritative
file set. Every returned source file was read. Runner implementations, wrappers,
out-of-layout files, heavy candidates, and the three execution-profile analysis
helpers were inspected in full. Repository-wide `git grep` searches covered
explicit entrypoint calls, documentation references, `eval`, `feval`, `run`,
`runtests`, `which`, `str2func`, function handles, names in strings/cells/structs,
and path-based dispatch.

`analysis/test_inventory/buildTestInventory.m` reproduces the inventory and
graph without executing tests. It strips comments and quoted text before
high-confidence executable matching, recognizes the known wrapper convention,
and treats `runtests` path lists as medium-confidence dynamic edges. The
committed CSVs contain repository-relative paths, stable columns and ordering,
no timestamps, and no machine-specific paths.

Static parsing cannot prove the absence of workspace dispatch, constructed
names, callbacks, path shadowing, or manual command use. The CSV evidence must
therefore be read as a conservative call graph, not as a complete MATLAB
runtime trace.

## Current structure

The maintained target is:

```text
tests/
|-- app/
|-- models/
|-- runners/
`-- shared/
```

The 124 files under those four folders align structurally. The current useful
tree is:

```text
tests/
|-- app/
|   |-- execution_profiles/  10
|   |-- fitting/             15
|   |-- gui/                  8
|   `-- sweeps/               6
|-- models/
|   |-- acoustoelastic_iop_hgo/ 11
|   |-- mrlfe/                   36
|   `-- rayleigh_lamb/            2
|-- runners/                  20
|-- shared/
|   |-- fitting/              10
|   |-- regression/            1
|   `-- utilities/             5
|-- analysis/                  1
|-- fitting/                   3
`-- root MATLAB files          9
```

`tests/README.md` says the migration has reached steady state and that all
non-wrapper tests are inside the four owned folders. At the audit baseline the
tracked tree disproved that statement: the renderer contract and both FitTool
data-import tests were non-wrapper implementations outside the target layout.
Cleanup phase 1 moved only those three implementations into the maintained
layout without changing their entrypoint names or runner membership.

## Compatibility-wrapper audit

All nine wrappers are three-line scripts that call
`runRepositoryTestRunner(mfilename('fullpath'), '<same name>')`. The helper
resolves `tests/runners/<name>.m` and invokes it with `run`. This is deliberate
dynamic delegation and high-confidence wrapper evidence.

| Wrapper | Target | In `tests/README.md` wrapper list | Static consumers / exposure | Recommendation |
| --- | --- | --- | --- | --- |
| `tests/run_acoustoelastic_smoke_tests.m` | `tests/runners/run_acoustoelastic_smoke_tests.m` | yes | maintained docs and public MATLAB command | retain; document |
| `tests/run_all_smoke_tests.m` | `tests/runners/run_all_smoke_tests.m` | yes | principal documented validation command | retain; document |
| `tests/run_core_smoke_tests.m` | `tests/runners/run_core_smoke_tests.m` | yes | nested by all-smoke and documented directly | retain; document |
| `tests/run_gui_smoke_tests.m` | `tests/runners/run_gui_smoke_tests.m` | yes | nested by all-smoke and documented directly | retain; document |
| `tests/run_mrlfe_legacy_cleanup_tests.m` | `tests/runners/run_mrlfe_legacy_cleanup_tests.m` | yes | nested by all-smoke and documented directly | retain; document |
| `tests/run_mrlfe_production_core_tests.m` | `tests/runners/run_mrlfe_production_core_tests.m` | yes (phase 1) | maintained-entrypoint and validation docs | retain; documented |
| `tests/run_mrlfe_public_contract_tests.m` | `tests/runners/run_mrlfe_public_contract_tests.m` | yes (phase 1) | maintained-entrypoint and validation docs | retain; documented |
| `tests/run_mrlfe_smoke_tests.m` | `tests/runners/run_mrlfe_smoke_tests.m` | yes | nested by all-smoke and documented directly | retain; document |
| `tests/fitting/run_fit_validation_tests.m` | `tests/runners/run_fit_validation_tests.m` | yes | maintained fitting-validation command | retain during legacy-folder migration |

At the audit baseline the discovered wrapper list was two entries longer than
the README list; cleanup phase 1 aligned the documentation with all nine.
`tests/run_main_gui_export_tests.m` is not a compatibility wrapper: it is
a standalone root runner that starts the project, checks two export helpers,
and calls `test_main_gui_export_contract` directly. Its public status should be
documented before any relocation decision.

Dynamic-path caution remains important. `startup` recursively exposes `tests/`,
duplicate runner basenames exist by design, and `runRepositoryTestRunner` uses a
constructed runner path. Removing a wrapper on the basis of ordinary call grep
would break documented commands even if no production `.m` file calls it.

## Runner inventory

Runtime classes below are planning classifications from source structure. They
are not measured durations.

| Runner | Purpose | Direct tests | Nested runners | Transitive tests | From all-smoke | Category / runtime class | Findings |
| --- | --- | ---: | --- | ---: | --- | --- | --- |
| `run_main_gui_export_tests` | standalone export contract | 1 | none | 1 | no | contract / quick | root implementation; public status undocumented |
| `run_acoustoelastic_smoke_tests` | AE API, solver, sweep, renderer and fit coverage | 10 | none | 10 | yes | smoke / likely extended | includes atlas solve and synthetic fitting |
| `run_all_smoke_tests` | aggregate maintained groups | 0 | core, GUI, AE, mRLFE smoke, legacy cleanup | 51 | root | integration / extended | name understates numerical and fitting scope |
| `run_core_smoke_tests` | paths, RL baseline, shared regression and fitting | 7 | none | 7 | yes | smoke / likely extended | embeds repeated RL solve plus RL and mRLFE synthetic fits |
| `run_execution_profile_cleanup_tests` | cleanup and mapping contracts | 4 | none | 4 | no | contract / quick-to-medium | three tests overlap surface suite |
| `run_execution_profile_diagnostics_tests` | format plus benchmark contract | 2 | none | 2 | no | diagnostic / manual | benchmark executes 18 cases and is stale |
| `run_execution_profile_end_to_end_tests` | state, curve metadata and 36-case matrix | 4 | none | 4 | no | integration / extended | matrix is measured at about 178.7 s externally |
| `run_execution_profile_infrastructure_tests` | normalization, resolvers and metadata | 4 | none | 4 | no | contract/integration / quick | entire set is contained in surface suite except no integration test |
| `run_execution_profile_surface_tests` | cross-surface profile contracts | 5 | none | 5 | partly | integration / medium | overlaps infrastructure (4) and cleanup (3) |
| `run_fit_data_import_tests` | MATLAB unit tests for import/preparation | 3 | none | 3 | no | integration / quick | dynamic `runtests` paths; includes interaction helpers also in two runners |
| `run_fit_tool_interaction_tests` | FitTool helpers and requested curves | 2 | none | 2 | no | integration / medium | interaction helper also in data-import and GUI smoke |
| `run_fit_validation_tests` | eight synthetic recovery/QC cases | 8 | none | 8 | no | integration / extended | correctly separate from all-smoke, but wrapper lives in legacy folder |
| `run_gui_smoke_tests` | GUI, fitting, sweeps and profiles | 17 | none | 17 | yes | smoke / likely extended | mixes four surfaces; counters change from `14/19` to `15/17` |
| `run_mrlfe_fit_public_solver_tests` | FitTool public solver route | 5 | none | 5 | no | integration / medium-to-extended | includes characterization and parameter regression |
| `run_mrlfe_legacy_cleanup_tests` | absence and cleanup behavior | 3 | none | 3 | yes | contract / medium | characterization performs numerical consumer comparison |
| `run_mrlfe_main_gui_public_solver_tests` | Main GUI public route | 4 | none | 4 | no | integration / medium-to-extended | includes characterization and equivalence solves |
| `run_mrlfe_neutral_production_helper_tests` | neutral helpers and dependencies | 4 | none | 4 | no | integration / extended | shares production-core characterization |
| `run_mrlfe_production_core_tests` | production contracts, grids and timing | 8 | none | 8 | no | mixed integration / extended | deliberately mixes contract, characterization and performance today |
| `run_mrlfe_public_contract_tests` | public defaults, validation, schema and route | 4 | none | 4 | no | contract / medium | route characterization performs multiple solves |
| `run_mrlfe_smoke_tests` | base mRLFE contracts and tracking | 14 | none | 14 | yes | smoke / medium-to-extended | broad numerical set; several maintained tests remain unregistered |
| `run_mrlfe_sweeptool_public_solver_tests` | SweepTool public route | 3 | none | 3 | no | integration / medium-to-extended | point characterization performs several sweeps |

Direct test entrypoints are fully enumerated in `runner_edges.csv`. Important
sets are:

- `run_all_smoke_tests`: 51 transitive tests through five nested runners.
- `run_core_smoke_tests`: `test_startup_path_policy`,
  `test_repository_root_utilities`, `test_model_output_folder_helpers`,
  `test_lightweight_numerical_regression`, `test_fitting_helpers_smoke`,
  `test_rl_fit_synthetic_A0`, and `test_mrlfe_fit_synthetic_A0Like`.
- `run_gui_smoke_tests`: 17 direct tests spanning GUI adapters, FitTool state and
  interaction, SweepTool, mRLFE fitting, and execution profiles.
- `run_mrlfe_production_core_tests`: eight direct tests including
  `test_mrlfe_production_core_characterization` and
  `test_mrlfe_production_core_performance`.

## Runner graph and overlap

The graph contains:

| Edge type | Count |
| --- | ---: |
| wrapper_to_runner | 9 |
| runner_to_runner | 5 |
| runner_to_test | 112 |
| test_to_helper | 14 |
| dynamic_candidate | 9 |

There are 129 direct executable edges, 12 modeled dynamic edges, and eight
reference-only edges. The dynamic set consists principally of the nine wrappers,
the two `runtests` path edges for legacy FitTool import tests, and helper-based
path dispatch. `which` matches are exposure checks, not execution edges.

The largest overlaps are expected parent-child containment:

- all-smoke / GUI smoke: 17;
- all-smoke / mRLFE smoke: 14;
- all-smoke / AE smoke: 10;
- all-smoke / core smoke: 7;
- all-smoke / legacy cleanup: 3.

The largest non-parent overlaps are more actionable:

- infrastructure / surface execution-profile runners: 4 tests;
- cleanup / surface execution-profile runners: 3 tests;
- cleanup / infrastructure: 2 tests;
- surface / GUI smoke: 2 tests;
- neutral-production-helper / production-core: one shared numerical
  characterization.

Tests with four maintained-runner memberships are:

- `test_execution_profile_current_contract`;
- `test_gui_execution_profile_normalization`;
- `test_fit_tool_interaction_helpers`;
- `test_execution_profile_surface_integration`.

Tests with three are `test_model_execution_profile_resolvers` and
`test_main_gui_export_contract`. Fifty-five tests have multiple transitive
memberships in total; most two-membership cases are simply a focused runner plus
the all-smoke aggregate.

## Unregistered-test analysis

Six test files have no executable static path from a maintained runner. Five are
documented as maintained, which makes silent deletion especially unsafe.

| Test | Evidence and likely intent | Classification | Recommendation |
| --- | --- | --- | --- |
| `tests/app/fitting/test_mrlfe_fit_grid_policy_performance.m` | no runner call; cleanup report explicitly describes it as manual lightweight performance characterization | intentionally standalone benchmark | retain; document as manual/extended |
| `tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy.m` | path-asserted by AE smoke but never executed; active API and diagnostic-policy docs reference it | possibly forgotten contract | add to a focused contract runner only after measured cost review |
| `tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_short_entrypoints.m` | path-asserted by AE smoke but never executed; extensive `which`/wrapper checks; many active/archive references | likely intentionally standalone or accidentally omitted | decide explicit registration; do not call it dead |
| `tests/models/mrlfe/test_mrlfe_etaS_fit_forward_cache.m` | maintained-entrypoint docs list it; no executable runner call | possibly forgotten fitting contract/regression | measure, then register in focused extended fitting/mRLFE suite or document manual status |
| `tests/models/mrlfe/test_mrlfe_fit_fast_options_quality.m` | maintained-entrypoint docs list it; no executable runner call | possibly forgotten numerical regression | measure before selecting quick versus extended owner |
| `tests/models/rayleigh_lamb/test_rl_fit_evaluator_branch_consistency.m` | maintained-entrypoint docs and historical fitting evidence list it; no runner call | possibly forgotten regression | likely focused RL/fitting owner; measure first |

None is a strong dead-test or removal candidate. Recursive path exposure permits
manual invocation, and documentation references are substantial. The AE
short-entrypoint test also evaluates dynamically resolved wrapper paths, so
ordinary caller grep understates its public compatibility role.

## Duplicate and layered coverage

### Legitimate layered coverage

- `run_all_smoke_tests` aggregating focused groups is useful public composition,
  not duplicate execution within one run.
- Path checks in runners plus behavioral tests protect different failure modes:
  discoverability versus actual behavior.
- Main GUI, SweepTool and FitTool mRLFE characterizations exercise distinct
  consumer adapters even when they share `mrlfeSolve`.
- `test_main_gui_export_contract` has a focused standalone command and broad GUI
  membership; this is reasonable if the standalone command is documented.

### Possibly unnecessary duplication

- The execution-profile surface suite subsumes all four infrastructure tests and
  three of four cleanup tests. A future ownership matrix can give each contract
  one canonical runner and let higher-level runners nest that owner.
- `test_fit_tool_interaction_helpers` is executed by GUI smoke,
  fit-tool-interaction, and data-import runners. The data-import runner needs
  only its import-related subset or an explicit nested focused runner.
- `test_mrlfe_production_core_characterization` is called by both production-core
  and neutral-helper runners and repeats a model/profile matrix.
- `test_execution_profile_surface_integration` is run by cleanup, surface and GUI
  suites, despite performing real RL, AE and mRLFE surface work.

### Requires runtime evidence

- Whether path-only assertions can be removed when a behavioral test resolves
  the same entrypoint depends on startup/path failure history.
- Numerical mRLFE characterization across public, production, GUI, sweep and fit
  layers may share solver work but checks different normalized contracts.
- Synthetic fitting tests in core smoke and focused validation look related but
  have different tolerances and ownership. Timing and failure-value analysis are
  required before consolidation.

No exact duplicate file bodies were found. The main duplication is runner
membership and repeated numerical solves, not byte-identical tests.

## Runtime classification

Planning targets are: contract below 2 seconds, smoke below 10 seconds,
regression below 30 seconds, integration explicitly separate, and
characterization/diagnostic/benchmark manual or extended. These are targets,
not measured facts.

The one supplied measurement is
`test_execution_profile_validation_matrix`: 36 combinations, passed on the
user's MATLAB machine in approximately 178.7 seconds. It is extended
integration validation.

Likely heavy tests based on static evidence are:

- `test_execution_profile_validation_matrix` (36 Main/Sweep/Fit x scenario x
  profile combinations);
- `test_mrlfe_execution_profile_benchmark_contract` (18 benchmark rows plus
  warmups and repeated reference cases);
- `test_mrlfe_fit_grid_policy_performance` (two forward policies across three
  cases with `tic/toc`);
- `test_mrlfe_production_core_performance` (warmup plus 12 timed solves);
- `test_mrlfe_production_core_characterization` (branch/viscosity/material
  matrix);
- `test_execution_profile_fit_curve_metadata` (RL, AE and mRLFE fitting);
- `test_execution_profile_surface_integration` (cross-model surface solves);
- `test_mrlfe_main_gui_characterization` and
  `test_mrlfe_sweep_point_characterization`;
- RL, mRLFE and AE synthetic-fit tests;
- the five shared fitting-validation scripts.

Likely heavy or extended runners are all-smoke, core smoke, GUI smoke, AE smoke,
execution-profile end-to-end, fitting validation, mRLFE production core, and the
three mRLFE public-solver consumer runners. This classification is static except
for the measured 36-case matrix.

`test_mrlfe_execution_profile_benchmark_contract` and
`benchmarkMRLFEExecutionProfiles` are also logically obsolete: they assert that
all effective profiles are Fast and support mode is `mapped_to_fast`, while the
maintained contract is direct Fast/Balanced/Robust preset mapping.

## Files outside the target layout

| File(s) | Assessment | Future location / action |
| --- | --- | --- |
| eight root `run_*` delegators listed in wrapper audit | intentional compatibility wrappers | retain at root until an explicit deprecation plan |
| `tests/run_main_gui_export_tests.m` | standalone public runner, not wrapper | document; optionally add maintained implementation plus wrapper in a later PR |
| `tests/fitting/run_fit_validation_tests.m` | intentional legacy-folder wrapper | retain while public path is needed |
| `tests/shared/sweeps/test_sweep_plot_renderer_contract.m` | shared sweep renderer contract moved in cleanup phase 1 | retained in maintained shared layout |
| `tests/app/fitting/test_gui_prepare_experimental_fit_data.m` | FitTool data-import unit test moved in cleanup phase 1 | retained in maintained app layout |
| `tests/app/fitting/test_gui_read_experimental_fit_file.m` | FitTool data-import unit test moved in cleanup phase 1 | retained in maintained app layout |

The two data-import tests are referenced by paths assembled in
`run_fit_data_import_tests` and passed to `runtests`; cleanup phase 1 updated
that file list atomically with the moves. The renderer test remains called by
the AE smoke runner but tests shared rendering across RL, mRLFE and AE;
shared/sweeps is a material ownership improvement, not just aesthetic
flattening.

## mRLFE test-family analysis

The 36 files in `tests/models/mrlfe/` form real conceptual families:

- **public_api**: `test_mrlfe_public_contract_*`;
- **production_core**: `test_mrlfe_production_core_*`,
  `test_mrlfe_numerical_preset_grids`, `test_mrlfe_solve_frequency_override`,
  and `test_mrlfe_robust_start_contract`;
- **grids**: internal tracking-grid, buffered-grid, viscous-default-grid, and
  internal-grid-quality tests;
- **tracking**: tracking-quality, tracking-strategy, neutral-seed and
  neutral-tracker tests;
- **termination**: termination policy, elastic reference buffer, etaS-zero limit
  and diagnostic selection;
- **fitting**: synthetic fit, fit frequency-grid, fast-options quality, etaS
  forward cache;
- **cleanup**: no-legacy routes/flags, legacy characterization, maintained
  naming, and no-historical-dependencies;
- **diagnostics/performance**: diagnostic material-sweep contract and production
  performance.

Subdivision would improve ownership only after runner membership is stabilized.
Today several families cross runners, and moving them first would create path
churn without clarifying which suite owns execution. Risks include duplicate
basenames on the recursive path, exact path assertions, documentation links,
and dynamic/manual invocation. A later move should handle one family at a time,
preserve names, update its single canonical runner, and run the corresponding
focused suite plus path checks.

## Staged cleanup plan

### Phase A - documentation and wrapper inventory

- **Objective:** make current public commands and static classifications true in
  documentation; no behavior changes.
- **Likely files:** `tests/README.md`,
  `docs/repository/maintained_entrypoints.md`,
  `docs/repository/validation_status.md`, comments/counters in
  `tests/runners/run_gui_smoke_tests.m`, and audit links.
- **Risk:** low.
- **Dependencies:** this audit and wrapper graph.
- **MATLAB validation:** inventory generator; targeted `which` checks for all
  wrapper/target pairs. Do not run numerical suites solely for prose/counters.
- **Git checks:** diff check, exact wrapper-list grep, no membership diff.
- **Compatibility:** add the two omitted wrappers; do not rename commands.
- **Rollback:** revert the documentation/counter commit.

### Phase B - low-risk layout corrections

- **Objective:** move only clearly misplaced implementations with unchanged
  entrypoint names and membership.
- **Likely files:** renderer contract to `tests/shared/sweeps/`; two FitTool
  import tests to `tests/app/fitting/`; `run_fit_data_import_tests.m`; README and
  maintained-entrypoint references.
- **Risk:** low-to-medium because `runtests` uses exact paths.
- **Dependencies:** Phase A wrapper truth and unique-basename check.
- **MATLAB validation:** `run_fit_data_import_tests`,
  `test_sweep_plot_renderer_contract`, `run_acoustoelastic_smoke_tests`, startup
  path policy, and then the maintained broad gate only if review requires it.
- **Git checks:** old-path absence, new-path presence, unique `which`, exact
  runner path list, generated inventory equality except paths.
- **Compatibility:** preserve MATLAB entrypoint names; no wrapper needed for test
  functions unless external path consumers are discovered.
- **Rollback:** reverse one coherent family move per commit.

### Phase C - separate quick and extended validation

- **Objective:** keep contract/smoke commands within planning budgets and move
  matrices, synthetic recovery, characterization and performance into explicit
  extended runners.
- **Likely files:** `run_all_smoke_tests.m`, `run_core_smoke_tests.m`,
  `run_gui_smoke_tests.m`, `run_acoustoelastic_smoke_tests.m`, execution-profile
  runners, `run_mrlfe_production_core_tests.m`, focused mRLFE consumer runners,
  and new quick/extended runner implementations plus wrappers only where public
  compatibility requires them.
- **Risk:** medium-high because membership changes.
- **Dependencies:** measured per-test timing table and Phase A ownership map.
- **MATLAB validation:** old commands must still cover documented contracts;
  compare old/new test sets; run quick suites, every new extended suite once,
  and a one-time legacy-command parity check.
- **Git checks:** graph diff, no orphaned maintained tests, wrapper-target checks.
- **Compatibility:** preserve historical public commands as aggregators or thin
  wrappers; introduce explicit `*_extended_tests` names rather than silently
  weakening a public command.
- **Rollback:** keep membership changes isolated by runner family.

### Phase D - benchmark and diagnostic redesign

- **Objective:** replace mapped-to-Fast equality with direct public-preset
  characterization; keep timing descriptive and hardware-independent.
- **Likely files:**
  `analysis/execution_profiles/benchmarkMRLFEExecutionProfiles.m`,
  `tests/app/execution_profiles/test_mrlfe_execution_profile_benchmark_contract.m`,
  `tests/runners/run_execution_profile_diagnostics_tests.m`, and associated
  execution-profile validation docs.
- **Risk:** medium; benchmark semantics change but production behavior must not.
- **Dependencies:** Phase C explicit diagnostic/extended ownership.
- **MATLAB validation:** one-repeat structural contract, metadata assertions for
  fast/balanced/robust, descriptive timing output, no cross-hardware threshold.
- **Git checks:** remove `mapped_to_fast` expectations from active benchmark
  sources; retain historical evidence only in archive/context docs.
- **Compatibility:** preserve callable benchmark name and output schema where
  useful; document any deliberate column migration.
- **Rollback:** revert benchmark/test/doc commit without touching presets.

### Phase E - optional folder subdivision

- **Objective:** subdivide `tests/models/mrlfe/` only where canonical runner
  ownership is stable.
- **Likely files:** one coherent family at a time, starting with `public_api/` or
  `cleanup/`, plus the owning runner and docs.
- **Risk:** medium due to recursive path and exact-path consumers.
- **Dependencies:** Phase C runner ownership; repository-wide path/reference
  search.
- **MATLAB validation:** owning focused runner, startup/path tests, unique
  `which`, and broad smoke after each coherent family.
- **Git checks:** `git mv` review, old-path absence, unchanged entrypoint set,
  inventory diff limited to paths.
- **Compatibility:** preserve function/script names; wrappers only for documented
  path commands, not automatically for internal tests.
- **Rollback:** one family and one commit per PR.

### Phase F - removal candidates

- **Objective:** remove only files proven obsolete by static and dynamic evidence.
- **Likely files:** none are approved by this audit. Re-evaluate only after
  ownership and timing work identifies a candidate.
- **Risk:** high.
- **Dependencies:** exact caller/doc/registry/fixture searches, MATLAB dependency
  review, manual invocation assessment, and replacement coverage.
- **MATLAB validation:** focused owner, broad public runner parity, path absence
  assertions, and any affected extended suite.
- **Git checks:** isolated deletion PR, exact stale-reference scans, generated
  inventory update.
- **Compatibility:** deprecate public commands before removal; preserve wrapper
  during the announced migration window when required.
- **Rollback:** restore the deletion commit and documented command immediately.

## Dynamic invocation risks and unresolved questions

- `runRepositoryTestRunner` constructs paths and invokes them with `run`.
- `run_fit_data_import_tests` constructs three file paths and uses `runtests`;
  two are outside the target layout.
- `which` loops verify names stored in arrays in AE/mRLFE naming tests and
  runners. They prove path exposure, not execution.
- Recursive startup path order exposes standalone tests and creates intentional
  duplicate runner basenames.
- No tracked source use of `feval` or `str2func` was found for test dispatch, but
  callbacks/workspace code can still invoke a name manually.
- Documentation contains stale references to removed execution-profile runner
  names and historical test paths; these are documentation findings, not graph
  edges.
- Static evidence cannot decide whether the five documented-but-unregistered
  tests were deliberately manual or accidentally omitted.
- No runtime timings were collected in this audit beyond the user's supplied
  178.7-second matrix measurement.

## Validation commands

Static and lightweight MATLAB validation for this audit should include:

```matlab
clear functions
rehash toolboxcache
startup

[inventory, edges] = buildTestInventory('WriteCsv', false);
height(inventory)
height(edges)
summary(inventory.FileType)
summary(inventory.Category)

assert(numel(unique(inventory.Path)) == height(inventory))
assert(all(strlength(inventory.Path) > 0))
assert(all(strlength(inventory.Entrypoint) > 0))
assert(sum(inventory.IsCompatibilityWrapper) == 9)
assert(sum(inventory.ReachableFromRunAllSmoke & inventory.FileType == "test") == 51)
```

To reproduce committed CSV evidence:

```matlab
clear functions
rehash toolboxcache
startup

[inventory, edges] = buildTestInventory('WriteCsv', true);
```

The full smoke suite, 36-case matrix, benchmark contract, and execution-profile
diagnostics runner are intentionally excluded from this audit's validation.

## Evidence files

- `analysis/test_inventory/test_inventory.csv`: one stable row per tracked
  MATLAB file under `tests/`.
- `analysis/test_inventory/runner_edges.csv`: wrapper, runner, test and helper
  edges with direct/dynamic and confidence fields.
- `analysis/test_inventory/buildTestInventory.m`: reproducible generator.
- `analysis/test_inventory/README.md`: interface and parser limitations.
