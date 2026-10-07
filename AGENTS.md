# Repository agent context

This repository provides MATLAB forward solvers and inverse dispersion fitting
for Rayleigh-Lamb, mRLFE, and acoustoelastic IOP/HGO models.

## Ownership and dependencies

- `src/+lamb/+models/` owns forward physics, configuration, tracking, policy,
  quality, and canonical scientific results.
- `src/+lamb/+fitting/` owns inverse fitting, residuals, optimization, metrics,
  and family adapters to canonical model routes.
- `src/+lamb/+elasticity/`, `+grids/`, and `+sweeps/` contain only narrowly
  model-neutral operations.
- `app/` translates requests, coordinates workflows, and presents or persists
  already-computed results. Models calculate science; GUIs do not.
- `studies/` and `examples/` are opt-in consumers of production APIs.
- `tests/` owns executable invariants, validation runners, and test tooling.

Dependency direction is toward scientific owners. Models do not depend on
fitting, app, studies, examples, or tests. Production does not depend on
studies, examples, or tests. Fitting calls canonical model APIs. The sole
intentional cross-family scientific dependency is the mRLFE seed through the
public Rayleigh-Lamb solver.

## Scientific and public contracts

Preserve governing equations, constitutive laws, material definitions, branch
identity and selection, tracking and fallback behavior, validity policy,
numerical presets and candidate densities, stopping rules, fitting objectives,
bounds and metrics, result schemas, quality thresholds, tolerances, numerical
snapshots, performance baselines, and established execution-profile semantics
unless a scientific change is explicitly authorized.

Fitting uses `experimental.validMask` as a fixed objective mask. Every candidate
parameter set must return finite model phase velocity at every selected
observation; model-dependent point dropping is forbidden. Metrics use that same
fixed mask. Local sensitivity may be reported unavailable if a perturbation
loses coverage, but it must never shrink the observation mask to manufacture a
derivative. Family-specific fitting may reject observations outside a declared
forward-model support range before optimization.

Keep physical parameters, numerical options, execution profiles, and UI state
separate. `executionProfile` is the canonical app field; the established
`robustness` compatibility alias is restricted to app normalization. Profiles
change numerical effort, never physical meaning.

Public APIs represent complete scientific operations and may remain short when
they provide a stable validation, routing, error, or result boundary. Do not add
compatibility or forwarding wrappers without an explicit external contract and
removal condition. Internal equations, trackers, policies, result builders, and
optimizer mechanics stay internal unless independently useful.

AE official production output remains `atlasA0`. Diagnostic, raw, identity, or
fallback candidates never replace official production arrays. Stable diagnostic
evidence may be returned separately but must not become an alternate solver.

## Engineering constraints

- Audit the affected owner, consumers, tests, and current contract before a
  structural change; summarize the behavior and authorized scope before editing.
- One responsibility has one obvious owner. Extend that owner before adding an
  API. Prefer fewer conceptual layers and helper jumps; retain a one-file
  package only when it protects a meaningful independent domain.
- Keep orchestration at one abstraction level. Prefer a local one-use helper
  over a forwarding wrapper; do not extract solely to shorten a function.
- Validate at trust boundaries and preserve important physical invariants;
  do not repeatedly validate an already resolved upstream contract.
- Use `rl*`, `mrlfe*`, and `ae*` family prefixes for maintained family code.
- Do not add generic `shared` or `common` dumping grounds, speculative
  registries, managers, frameworks, or symmetry-only packages.
- Do not preserve development chronology through `old`, `new`, `legacy`, `v2`,
  or parallel implementations; Git history owns chronology.
- Extract or consolidate by semantic responsibility, not by line count or
  visual symmetry. Different model physics may require different structures.
- Quality assesses an already selected curve; it does not reconnect,
  interpolate, replace, or select branches.
- Structural work must not change baselines, tolerances, or snapshots to obtain
  a pass. A scientific baseline change requires separate authorization and
  independent numerical evidence.
- Preserve unrelated work and inspect generated artifacts before delivery.

Model-internal constraints that are difficult to infer live in
`src/+lamb/+models/+mrlfe/AGENTS.md` and
`src/+lamb/+models/+acoustoelastic_iop_hgo/AGENTS.md`, and
`src/+lamb/+models/+rayleigh_lamb/AGENTS.md`.

## Documentation ownership

Maintained documentation describes the current system. Git, commits, PRs, and
issues own chronology, migrations, completed stages, prior architectures,
branch names, merge SHAs, campaign logs, handoffs, and historical test counts.
Do not create temporary context or history documents without a current
operational responsibility. Preserve comments explaining physical intent,
scientific provenance, and non-obvious invariants.

README owns user orientation and entrypoints; this file owns modification policy.
[Architecture](docs/repository/final_architecture.md) owns the responsibility map;
[validation](docs/repository/validation_status.md) owns the validation contract.
Local AGENTS files contain only non-obvious family invariants. Link to an owner
instead of duplicating its contract.

## Validation and delivery

Run the canonical gate from the repository root:

```matlab
clear functions;
startup;
addpath(fullfile(pwd, "tests", "runners"), "-end");
summary = run_regression_tests;
```

Every maintained test must have exactly one catalog owner. The runner owns path setup
and restore the caller path. Finish with `git diff --check`, inspect untracked or
generated outputs, and report the exact validation and Git state. Work on a
review branch; never modify or merge `main` without explicit authorization.
