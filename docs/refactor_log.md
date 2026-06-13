# Refactor log: Acoustoelastic IOP/HGO and mRLFE cleanup

This document records the structural cleanup performed after the Acoustoelastic IOP/HGO and mRLFE solver development work.

## Objective

Separate active model code, maintained examples, diagnostics, documentation, and tests into a clearer structure without changing validated solver behavior.

The cleanup policy was:

1. move files first;
2. verify MATLAB path resolution with `which`;
3. run smoke tests;
4. remove legacy locations only after the new paths worked;
5. update documentation after code paths were stable;
6. introduce author-neutral public entrypoints without deleting compatibility functions.

## Stable checkpoint

Before the naming transition, a stable checkpoint was tagged as:

```text
v0.2.0-refactor
```

This tag preserves the state after the first structural Li2024/mRLFE cleanup and before the Acoustoelastic IOP/HGO public naming transition.

## Final active structure

### Acoustoelastic IOP/HGO model

```text
models/acoustoelastic_iop_hgo/core/
models/acoustoelastic_iop_hgo/constitutive/
models/acoustoelastic_iop_hgo/solvers/
models/acoustoelastic_iop_hgo/options/
examples/acoustoelastic_iop_hgo/basic/
examples/acoustoelastic_iop_hgo/sweeps/
examples/acoustoelastic_iop_hgo/diagnostics/
tests/acoustoelastic_iop_hgo/
```

Recommended author-neutral entrypoints introduced during this phase:

```matlab
solveAcoustoelasticIOPHGOBranch
defaultAcoustoelasticIOPHGOOptions
run_acoustoelastic_iop_hgo_atlas_branch
diagnose_acoustoelastic_iop_hgo_branch_policy
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
```

The original Li2024-named functions and scripts remain available as compatibility/development entrypoints during the transition.

### mRLFE model

```text
models/mrlfe/core/
models/mrlfe/solvers/
models/mrlfe/options/
examples/mrlfe/basic/
examples/mrlfe/sweeps/
examples/mrlfe/diagnostics/
tests/mrlfe/
```

The mRLFE name is preserved because it identifies the model family used in this repository.

## Documentation updated

The following documentation files were updated to reflect the maintained structure and naming policy:

```text
README.md
docs/repository_structure.md
docs/maintained_entrypoints.md
docs/naming_transition.md
docs/acoustoelastic_iop_hgo_branch_policy.md
```

## Validation policy

After this refactor, the recommended validation sequence is:

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```

The smoke runner checks the author-neutral Acoustoelastic IOP/HGO wrappers, example/diagnostic entrypoints, test entrypoints, and the maintained mRLFE smoke test.

## Deferred cleanup

A full internal rename of MATLAB functions and files that still contain `Li2024` is intentionally deferred.

Reason: MATLAB requires the primary function name to match the file name. A full internal rename should be done in a dedicated pull request with all references updated consistently and with `run_all_smoke_tests` passing afterward.
