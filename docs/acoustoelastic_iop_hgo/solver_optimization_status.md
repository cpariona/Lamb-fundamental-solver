### Solver optimization status

This document records the current optimization and validation status of the acoustoelastic IOP/HGO solver.

### Scope

This status applies to the `acoustoelastic_iop_hgo` module and the maintained official branch policy:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

The official solver output remains:

```matlab
result.Cp
result.validCp
```

Diagnostic branches such as `identityA0Diagnostic`, `raw_branch1`, and branch-family outputs are not production outputs.

### Current official policy

The recommended official policy is:

```text
atlasA0 = conservative official output
identityA0Diagnostic = diagnostic extension only
raw_branch1 = modal-identity diagnostic only
branch_families = ambiguity diagnostic only
```

This policy should remain unchanged unless a stronger modal-identity criterion is added.

### Evidence supporting the policy

The validation sequence established the following:

1. `atlasA0` is aligned with the persistent raw branch where both are valid.
2. The dominant failure mode is conservative truncation, not systematic branch switching.
3. `identityA0Diagnostic` increases coverage in several cases, but it can exceed the mismatch threshold in low-stiffness regimes and should not be promoted to production.
4. `raw_branch1` is useful as a diagnostic reference in well-conditioned regimes, but it becomes weak and selection-sensitive in the low-stiffness/high-IOP corner.
5. Competing branch-family analysis shows that the difficult corner has real modal-family ambiguity under residual-only tracking.

### Validated regimes

The tested grid was:

```matlab
IOP_mmHg = [5, 15, 25, 35];
mu_kPa = [25, 50, 100];
k1_kPa = 25;
k2 = 100;
thickness_um = 550;
```

The grid produced:

| Classification | Cases |
|---|---:|
| `aligned_with_raw_branch` | 5 |
| `atlas_truncated_but_aligned` | 6 |
| `raw_branch_uncertain` | 1 |

The only clearly problematic case was:

```matlab
IOP_mmHg = 35;
mu_kPa = 25;
```

### Ambiguity boundary

The current ambiguity boundary is the low-stiffness/high-IOP corner, especially:

```matlab
IOP_mmHg = 35;
mu_kPa = 25;
k1_kPa = 25;
k2 = 100;
thickness_um = 550;
```

This case should be treated as an explicit ambiguity regime, not as evidence that the official tracker should be made more permissive.

The branch-family diagnostic showed:

| Quantity | Value |
|---|---:|
| Configurations | 5 |
| Families reported | 25 |
| Best-family median coverage | 0.85625 |
| Best-family min coverage | 0.73125 |
| Best-family max coverage | 0.92500 |
| Best-family median rank | 6 |
| Families with coverage >= 0.80 | 4 |
| Families with median rank <= 4 | 2 |
| Families with coverage >= 0.80 and median rank <= 4 | 0 |

The last row is the key result: no reported family combines high coverage and low median minima rank.

### Interpretation of the ambiguity corner

The difficult corner is not resolved by increasing atlas resolution or retaining more residual minima.

Increasing `TopNMinimaPerFrequency` increases branch-family coverage, but it also raises the median minima rank of the selected family. This indicates that the branch identity is not sufficiently determined by residual depth and local continuity alone.

The corner therefore requires an additional identity criterion, such as:

- modal-shape information;
- branch-family continuity across parameter sweeps;
- a physical plausibility constraint derived from the expected low-frequency A0-like behavior;
- independent validation against a high-fidelity FEM or an alternative formulation.

Until one of those criteria is implemented, the official conservative truncation should be preserved.

### Closing criteria for the current solver optimization

For the current model assumptions and residual-only tracking, the solver optimization can be considered close to closed if the following remain true:

1. `test_acoustoelastic_iop_hgo_short_entrypoints` passes.
2. `compare_atlasA0_vs_raw_branch1` shows no systematic branch switch in the baseline regime.
3. `validate_atlas_raw_grid` continues to classify most cases as `aligned_with_raw_branch` or `atlas_truncated_but_aligned`.
4. `diagnose_raw_branch_corner` and `diagnose_branch_families` document the low-stiffness/high-IOP corner as ambiguous rather than forcing a production branch.
5. No diagnostic branch replaces or mutates `result.Cp` or `result.validCp`.

### Recommended next actions

The next work should not be a broad rewrite of the solver. Recommended next actions are:

1. Add a compact warning or status flag for explicit ambiguity regimes.
2. Keep `atlasA0` as the official conservative policy.
3. Keep `identityA0Diagnostic`, `raw_branch1`, and `branch_families` as diagnostics.
4. Add a final smoke/validation command list to make the closure reproducible.
5. If more accuracy is needed inside the ambiguous corner, add a new project phase focused on modal identity, not residual minimization.

### Current conclusion

The solver is near closure for the current optimization phase.

Remaining work is mainly boundary documentation and optional ambiguity reporting. The current evidence does not support making the production tracker more permissive.
