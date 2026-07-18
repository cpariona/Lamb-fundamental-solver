# Repository simplification final state

Status: maintained final state.

This document records the maintained repository state after the bounded
simplification. Git history is the implementation record. Numerical, scientific,
GUI, fitting, sweep, output, and result behavior remain governed by their
existing contracts.

## Implemented structure

### AE analysis ownership

```text
analysis/acoustoelastic_iop_hgo/
|-- diagnostics/  repeatable diagnostic computation and defaults
|-- fitting/      fit problem construction, evaluation, and optimization
|-- io/           result/output resolution and figure-file helpers
`-- sweeps/       sweep orchestration, summaries, plot data, plots, and outputs
```

Every maintained AE analysis identifier has one tracked definition. Recursive
project path configuration preserves command names without forwarding files or
path aliases.

### AE model diagnostics

```text
models/acoustoelastic_iop_hgo/diagnostics/
|-- aeBuildIdentityA0DiagnosticBranch.m
`-- aeScoreBranchIdentityCandidates.m
```

These helpers remain diagnostic-only model internals used by the explicit
`identityA0Diagnostic` policy. `models/acoustoelastic_iop_hgo/results/` contains
only `aeBuildResult.m`.

### Model-family analysis decisions

`analysis/rayleigh_lamb/` remains flat: its ten maintained files form one small
fit/sweep/output workflow with eight internal call edges.

`analysis/mrlfe/` remains flat: its twenty maintained files form a cohesive
request-building, fitting, sweep, and diagnostic workflow with seventeen
internal call edges. The shared request builder couples surface-specific
requests intentionally. Subdirectories would add traversal without removing a
responsibility exception.

### Tests and runners

Canonical runner implementations live under `tests/runners/`. The explicit
public convenience wrappers are:

```matlab
run_acoustoelastic_smoke_tests
run_all_smoke_tests
run_core_smoke_tests
run_gui_smoke_tests
run_mrlfe_smoke_tests
```

The former `tests/fitting/` exception is absent. Specialized commands,
including fitting, Main GUI export, mRLFE production-core, public-contract, and
route-integrity validation, resolve directly from `tests/runners/`.

### Runtime evidence

`measureTestRuntime` writes local machine-dependent evidence to:

```text
Results/test_runtime/test_runtime_measurements.csv
```

The file is ignored and is never imported into deterministic ownership
inventory. The tracked deterministic inventories remain:

```text
analysis/test_inventory/test_inventory.csv
analysis/test_inventory/runner_edges.csv
analysis/test_inventory/test_runner_ownership.csv
```

## Enforced invariants

`run_repository_hygiene_tests` enforces:

- the four AE analysis responsibility directories and their explicit owners;
- diagnostic model ownership outside result construction;
- absence of `tests/fitting/` and unexpected root wrappers;
- delegation-only retained wrappers with canonical runner targets;
- no tracked runtime measurements;
- maintained layer direction and AE internal dependency boundaries;
- one tracked definition per maintained identifier;
- deterministic runner ownership with no unowned or multiply owned tests.

The current validation counts and commands are maintained in
`validation_status.md`; runner ownership is maintained in
`test_runner_ownership.md`.
