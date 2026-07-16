# Session handoff

Updated: 2026-07-16

## Repository state

- Repository: `cpariona/Lamb-fundamental-solver`
- Default branch: `main`
- Current closeout branch: `refactor/mrlfe-raw-internal-result-consumers`
- Current closeout task: migrate maintained consumers from
  `result.diagnostics.rawInternalResult` to
  `result.debug.rawInternalResult` while preserving the compatibility alias
- Validation status: confirmed by the repository owner
- Merge status: pending pull request and manual merge
- Selected next objective: AE IOP/HGO architecture audit and alignment plan
- Active AE implementation phase: none

Do not start the next task from the closeout branch. After the pull request is
merged, update local `main` from `origin/main` and create a new branch for the AE
audit.

## Required reading order for the next task

Read:

```text
docs/project/README.md
docs/project/active_context.md
docs/project/session_handoff.md
docs/repository/repository_structure.md
docs/repository/naming_strategy.md
docs/repository/maintained_entrypoints.md
docs/repository/validation_status.md
docs/models/mrlfe/README.md
docs/models/mrlfe/public_api.md
docs/models/mrlfe/production_core.md
docs/models/acoustoelastic_iop_hgo/README.md
docs/models/acoustoelastic_iop_hgo/active/public_api.md
docs/models/acoustoelastic_iop_hgo/active/branch_policy.md
docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md
docs/workflows/gui/adapter_architecture.md
docs/workflows/fitting/architecture.md
docs/workflows/sweeps/parametric_sweeps.md
```

Then inspect only the maintained AE and mRLFE files needed to reconstruct the
relevant call paths and ownership. Maintained code and tests take precedence
over operational context.

## Selected next objective

Audit the complete maintained AE IOP/HGO executable structure and determine how
it can be aligned with the responsibility-based mRLFE architecture without
forcing artificial API symmetry.

The audit must cover:

```text
models/acoustoelastic_iop_hgo/
analysis/acoustoelastic_iop_hgo/
app/adapters/ AE routes
app/fitting/ and app/sweep/ AE integration points
examples/acoustoelastic_iop_hgo/
tests/models/acoustoelastic_iop_hgo/
tests/app/ AE integration tests
docs/models/acoustoelastic_iop_hgo/
```

Required outputs:

1. complete maintained-file inventory by layer and responsibility;
2. current call graphs for Main GUI, SweepTool, FitTool, basic execution,
   maintained sweeps, and diagnostics;
3. public API, advanced supported API, maintained internal, diagnostic-only, and
   compatibility-surface classification;
4. comparison with mRLFE ownership for API, configuration, problem construction,
   solvers, tracking, policies, quality, results, analysis workflows, app
   adapters, examples, and tests;
5. identification of misplaced or mixed responsibilities, especially numerical
   preset resolution currently owned by app adapters;
6. target responsibility map for AE that preserves constitutive and scientific
   differences;
7. phased migration options ordered by risk and dependency;
8. focused validation required for each proposed phase.

## Audit constraints

During this task:

- do not move, rename, delete, or create production MATLAB files;
- do not introduce aliases or wrappers;
- do not change solver physics, constitutive behavior, residuals, branch
  selection, tracking, interpolation, fallback invalidation, or reliability;
- do not change defaults, presets, grids, scan counts, candidate counts,
  policies, tolerances, fitting, sweep, GUI, or output behavior;
- do not promote diagnostic branches to production;
- keep the residual high-frequency AE `Cp(f)` waviness as a separate numerical
  issue;
- use Git history for completed cleanup evidence rather than recreating broad
  repository audits.

The task may update or add bounded architecture documentation needed to record
the audit and migration plan, but any implementation requires a separately
approved branch and scope.

## Current architecture baseline

mRLFE provides the reference responsibility pattern:

```text
api/
configuration/
core/
options/
policies/
quality/
results/
solvers/
tracking/
```

AE currently has:

```text
constitutive/
core/
options/
solvers/
```

The goal is not to copy the folder tree mechanically. The audit must determine
which missing responsibility boundaries are justified by actual maintained AE
code. Existing explicit scientific APIs may remain long and model-specific.

## Standard validation

For documentation-only audit changes:

```matlab
clear functions
rehash toolboxcache
startup

run_repository_hygiene_tests
run_quick_contract_tests
```

If the audit branch changes executable inventories or test contracts, add the
focused commands owned by `docs/repository/validation_status.md`. No numerical
behavior change is authorized.

## Working rules

- Start from updated `origin/main` after the current PR is merged.
- Use one new branch for the audit.
- Suggested branch: `audit/ae-architecture-alignment`.
- Keep findings evidence-backed by maintained code, tests, and contracts.
- Do not open the audit PR until the documented inventory and call graphs are
  internally consistent and repository hygiene passes.
- The repository owner performs the merge manually.