### branch_families diagnostic

This diagnostic focuses on the difficult corner identified by the atlas/raw validation workflow:

```matlab
IOP_mmHg = 35;
mu_kPa = 25;
k1_kPa = 25;
k2 = 100;
thickness_um = 550;
```

The purpose is to inspect competing raw-atlas branch families instead of forcing a single `raw_branch1` selection. This is diagnostic only. It does not modify `result.Cp`, `result.validCp`, `atlasA0`, or `identityA0Diagnostic`.

### Runnable script

```matlab
cd('E:\')
startup
diagnose_branch_families
AcoustoelasticIOPHGOBranchFamiliesSummary
AcoustoelasticIOPHGOBranchFamiliesAggregate
```

### Output folder

```text
Results/ae_iop_hgo/branch_families
```

### Output files

- `branch_families_summary.csv`
- `branch_families_points.csv`
- `branch_families_aggregate.csv`
- `branch_families_configs.csv`
- `branch_families_workspace.mat`

### Configurations

The first run used five configurations:

| Config | NumY | TopNMinimaPerFrequency | MaxLogYJumpForRawBranch |
|---|---:|---:|---:|
| `base` | 900 | 16 | 0.075 |
| `top24` | 900 | 24 | 0.075 |
| `top32` | 900 | 32 | 0.075 |
| `fine_top24` | 1400 | 24 | 0.075 |
| `fine_loose` | 1400 | 24 | 0.110 |

### Aggregate result

| Configurations | Families reported | Best-family median coverage | Best-family min coverage | Best-family max coverage | Best-family median rank | Families with coverage >= 0.80 | Families with median rank <= 4 | Families with coverage >= 0.80 and median rank <= 4 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 5 | 25 | 0.85625 | 0.73125 | 0.92500 | 6 | 4 | 2 | 0 |

### Best family per configuration

| Config | Best-family coverage | Best-family median rank | Best-family roughness | Cp range [m/s] | Frequency range [kHz] |
|---|---:|---:|---:|---|---|
| `base` | 0.73125 | 4.0 | 0.0054348 | 2.2071 to 7.1753 | 0.1 to 35 |
| `top24` | 0.81875 | 6.0 | 0.0048409 | 2.2071 to 7.7135 | 0.1 to 35 |
| `top32` | 0.92500 | 8.5 | 0.0052991 | 2.2071 to 8.2323 | 0.1 to 35 |
| `fine_top24` | 0.85625 | 6.0 | 0.0031080 | 2.2065 to 7.6676 | 0.1 to 33.734 |
| `fine_loose` | 0.86250 | 6.0 | 0.0033481 | 2.2065 to 8.6124 | 0.1 to 35 |

### Interpretation

The diagnostic shows that the difficult corner is not resolved by simply retaining more minima or refining the `y` grid.

- Increasing `TopNMinimaPerFrequency` improves best-family coverage: from 0.73125 in `base` to 0.81875 in `top24` and 0.92500 in `top32`.
- The cost is a higher median rank for the selected best family: rank 4 in `base`, rank 6 in `top24`, and rank 8.5 in `top32`.
- No reported family simultaneously satisfies high coverage (`>= 0.80`) and low median rank (`<= 4`).
- Several secondary branch families occupy shorter but non-negligible frequency intervals, especially in the `fine_loose` configuration.

This supports the conclusion that the `IOP = 35 mmHg`, `mu = 25 kPa` corner has genuine modal-family ambiguity under the current residual-only raw-atlas tracking approach.

### Consequence for solver policy

The current evidence supports keeping `atlasA0` as the conservative official output.

Do not promote `raw_branch1` or `identityA0Diagnostic` to production output in this corner. The solver policy should treat this regime as an explicit ambiguity region until a stronger branch-identity criterion is available, such as modal-shape information, branch-family continuity across material parameters, or an independent physical plausibility constraint.

### Current optimization status

For the tested regimes outside the low-stiffness/high-IOP corner, the solver appears close to optimized for the current modeling assumptions:

- `atlasA0` is aligned with the persistent raw branch where both are valid.
- Most failures are conservative truncations, not systematic branch switches.
- `identityA0Diagnostic` increases coverage but remains too permissive for production promotion.

Remaining work should focus on documenting the ambiguity boundary and adding optional diagnostics, not on changing the official branch policy.
