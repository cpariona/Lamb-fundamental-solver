# New chat bootstrap

Use this template to start the selected AE IOP/HGO architecture audit after the
current closeout pull request has been merged.

## Paste-ready Codex prompt

```text
I want to continue technical work in the repository:

cpariona/Lamb-fundamental-solver

The previous task migrated maintained internal consumers from
result.diagnostics.rawInternalResult to result.debug.rawInternalResult while
preserving the temporary compatibility alias. That task has been merged into
main.

The next selected objective is an AE IOP/HGO architecture audit and alignment
plan. This is an audit and documentation task, not an implementation phase.

Before doing any work:

1. Verify that local main matches origin/main and report the exact base commit.
2. Create a new branch from updated origin/main. Suggested branch:
   audit/ae-architecture-alignment
3. Read, in this order:

- docs/project/README.md
- docs/project/active_context.md
- docs/project/session_handoff.md
- docs/repository/repository_structure.md
- docs/repository/naming_strategy.md
- docs/repository/maintained_entrypoints.md
- docs/repository/validation_status.md
- docs/models/mrlfe/README.md
- docs/models/mrlfe/public_api.md
- docs/models/mrlfe/production_core.md
- docs/models/acoustoelastic_iop_hgo/README.md
- docs/models/acoustoelastic_iop_hgo/active/public_api.md
- docs/models/acoustoelastic_iop_hgo/active/branch_policy.md
- docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md
- docs/workflows/gui/adapter_architecture.md
- docs/workflows/fitting/architecture.md
- docs/workflows/sweeps/parametric_sweeps.md

Then inspect only the maintained AE and mRLFE code and tests needed to reconstruct
ownership and call paths. Do not perform an unbounded repository-wide rewrite or
recreate completed cleanup work.

Audit scope:

- models/acoustoelastic_iop_hgo/
- analysis/acoustoelastic_iop_hgo/
- AE app adapters and AE fitting/sweep integration points
- examples/acoustoelastic_iop_hgo/
- tests/models/acoustoelastic_iop_hgo/
- AE tests under tests/app/
- docs/models/acoustoelastic_iop_hgo/

Required outputs:

1. a complete maintained-file inventory by layer and responsibility;
2. current call graphs for Main GUI, SweepTool, FitTool, basic execution,
   maintained sweeps, and diagnostics;
3. classification into public API, advanced supported API, maintained internal,
   diagnostic-only, and compatibility surfaces;
4. a responsibility-by-responsibility comparison with mRLFE;
5. identification of mixed or misplaced responsibilities;
6. a target AE responsibility map that preserves AE-specific physics and
   scientific APIs;
7. phased migration options ordered by risk and dependency;
8. validation requirements for each proposed phase.

Pay particular attention to configuration and numerical preset ownership. The AE
Main GUI adapter currently applies internal atlas values directly. Determine
whether those values should be resolved in the model layer, but do not move them
or change their values during this audit.

Constraints:

- do not move, rename, delete, or create production MATLAB files;
- do not add aliases or wrappers;
- do not change physics, constitutive equations, matrix construction, residuals,
  tracking, branch selection, interpolation, fallback invalidation, reliability,
  defaults, presets, grids, scan counts, candidate counts, policies, tolerances,
  fitting, sweeps, GUI behavior, or result schemas;
- do not promote identityA0Diagnostic, raw_branch1, or branch_families to
  production;
- keep residual high-frequency AE Cp(f) waviness outside this task;
- do not force AE to copy the mRLFE folder tree when a responsibility boundary is
  not justified by maintained AE code.

The audit may update or add bounded architecture documentation that records the
inventory, call graphs, findings, and migration plan. Any executable
reorganization requires a later separately approved task and branch.

Validation for documentation-only audit changes:

clear functions
rehash toolboxcache
startup
run_repository_hygiene_tests
run_quick_contract_tests

Do not open a PR until the inventory and call graphs are internally consistent
and the required validation passes. I will perform the merge manually.
```

## Persistent context

The operational source of truth is:

1. `docs/project/README.md`
2. `docs/project/active_context.md`
3. `docs/project/session_handoff.md`

Maintained code and tests take precedence over project context when a discrepancy
is found. Use Git history for completed migrations and cleanup evidence rather
than adding historical reports to active documentation.