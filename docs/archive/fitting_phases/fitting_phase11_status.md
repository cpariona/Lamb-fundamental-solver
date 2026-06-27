# Fitting Phase 11 status

## Scope

Phase 11 targets branch-coherent fitting evaluators for models whose forward fitting paths can otherwise switch between residual minima that do not belong to the same physical modal branch.

The implementation is intentionally staged:

```text
Phase 11A: Rayleigh-Lamb fitting evaluator only
Phase 11B: mRLFE fitting evaluator audit and update if needed
```

## Phase 11A — Rayleigh-Lamb

Status:

```text
implemented on branch rl-branch-fit
```

Changed helper:

```matlab
analysis/rayleigh_lamb/rlEvaluateFitModel.m
```

The previous fitting evaluator solved each requested experimental frequency independently. That avoided predictor-only fallback values but did not enforce modal continuity across frequencies. In dense parameter sweeps, this could make `RMSE(mu)` irregular because neighboring points could be sampled from different valid residual minima.

The new evaluator:

```text
1. builds an internal tracking frequency grid;
2. starts tracking from a low initialization frequency;
3. explicitly includes all requested fitting frequencies;
4. calls the maintained RL continuation branch solver;
5. disables prediction fallback for fitting output;
6. reports only the requested frequencies to the optimizer;
7. stores internal tracking arrays, diagnostics, and reliability metadata in `rawResult`.
```

Primary output contract remains unchanged:

```matlab
[Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
```

New diagnostic fields include:

```matlab
rawResult.trackingMode
rawResult.internalFrequency_Hz
rawResult.internalCp_mps
rawResult.internalResidual
rawResult.internalValidMask
rawResult.reliability
rawResult.diagnostics
rawResult.branchTable
```

## Tests

Added maintained test:

```matlab
tests/rayleigh_lamb/test_rl_fit_evaluator_branch_consistency.m
```

The test compares `rlEvaluateFitModel` with the maintained `rlComputeFundamentalLambModes` A0 branch and checks that the evaluator uses the branch-coherent internal-grid tracking mode without prediction fallback.

Recommended validation sequence:

```matlab
clear functions
rehash toolboxcache
startup

test_rl_fit_evaluator_branch_consistency
test_fit_validation_rayleigh_lamb
run_fit_validation_tests
run_core_smoke_tests
run_gui_smoke_tests
run_all_smoke_tests
```

## Phase 11B — mRLFE

Status:

```text
not implemented in Phase 11A
```

The mRLFE documentation already records that global residual minimization is unsafe for branch selection and that continuity must be interpreted with local-minimum evidence. Before changing mRLFE fitting, audit whether `mrlfeEvaluateFitModel` already routes through the maintained DP/modal-local branch selection path for `A0Like`.

Relevant existing file:

```matlab
models/mrlfe/solvers/solveMRLFEBranchDP.m
```

## Non-goals of Phase 11A

Phase 11A did not change:

```text
optimizer policy
GUI fitting controls
AE IOP/HGO branch policy
mRLFE fitting behavior
experimental data contracts
```

If the Rayleigh-Lamb `RMSE(mu)` profile remains irregular after this branch-coherent forward model change, the next step should be a shared optimizer strategy in `analysis/fitting`, such as coarse-global search followed by local refinement.
