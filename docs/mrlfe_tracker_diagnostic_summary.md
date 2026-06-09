# mRLFE tracker diagnostic summary

This note summarizes the diagnostic evidence from `examples/diagnostics/compare_mrlfe_tracker_vs_condition_peaks.m`.

The diagnostic compares the current tracked mRLFE branch against a brute-force residual/condition scan over phase velocity `Cp`. It is intended to answer four questions:

1. Is the tracked branch continuous?
2. Does the tracked branch lie near a true local residual minimum?
3. Does the global residual minimum select the correct modal branch?
4. Is brute-force scanning a practical replacement for the tracker?

## Diagnostic configuration

Reference case used in the tests:

| Parameter | Value |
|---|---:|
| `E` | `100 kPa` |
| `nu` | `0.4999` |
| `CL` | `1500 m/s` |
| `rho` | `1050 kg/m^3` |
| `thickness` | `0.5 mm` |
| Frequency range | `500–16000 Hz` |
| Frequency points | `120` |
| Fluid density | `1000 kg/m^3` |
| Fluid sound speed | `1500 m/s` |
| Viscoelastic shear viscosity `etaS` | `0.1 Pa*s` |
| Cp scan range | `0.25–80 m/s` |
| Cp scan points | `5000` |
| Tight local window | `SolverCp ± 2%`, minimum half-width `0.05 m/s` |

## Summary of tested cases

| Model | Branch | Valid Cp points | Validity segments | Max relative Cp jump | Median relative Cp jump | Max relative tracker/local-min error | Median relative tracker/local-min error | Global mismatch fraction | Solver time | Estimated brute-force full-branch time | Interpretation |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `mRLFEElasticRealK` | `A0Like` | `120/120` | `1` | `0.12494` | `0.0011888` | `0.0022245` | `0.00083144` | `0.70` | `3.1119 s` | `3.6412 s` | Continuous, local-minimum consistent; largest relative jump occurs in the first low-frequency A0 interval. |
| `mRLFEElasticRealK` | `S0Like` | `120/120` | `1` | `0.015396` | `0.0047737` | `0.0014626` | `0.00036393` | `1.00` | `1.8042 s` | `3.6163 s` | Very clean continuity and local-minimum agreement. |
| `mRLFEHanViscoRealK` | `A0Like` | `55/120` | `1` | `0.12379` | `0.0076518` | `0.0021338` | `0.00086671` | `0.80` | `4.3435 s` | `3.0734 s` | Conservative real-k branch segment; local-minimum consistent until branch cut. |
| `mRLFEHanViscoRealK` | `S0Like` | `45/120` | `1` | `0.030398` | `0.0083871` | `0.00098574` | `0.00011753` | `1.00` | `3.2021 s` | `3.2755 s` | Conservative real-k branch segment; very strong local-minimum agreement until branch cut. |

## Main conclusions

### 1. The tracker follows local residual minima, not artificial continuity

Across all four diagnostic cases, the tracked `Cp` is very close to the nearest local residual minimum found by brute-force scanning.

The relative tracker/local-minimum differences remain small:

- Elastic A0-like: maximum `0.222%`, median `0.083%`.
- Elastic S0-like: maximum `0.146%`, median `0.036%`.
- Viscoelastic A0-like: maximum `0.213%`, median `0.087%`.
- Viscoelastic S0-like: maximum `0.099%`, median `0.012%`.

This supports the interpretation that the tracker is not merely drawing a smooth curve; it is following a mode-relevant residual valley.

### 2. The global residual minimum is not a safe branch-selection rule

The global minimum frequently falls away from the tracked branch, often at the lower Cp scan edge (`Cp = 0.25 m/s`).

Observed global-minimum mismatch fractions:

- Elastic A0-like: `70%`.
- Elastic S0-like: `100%`.
- Viscoelastic A0-like: `80%`.
- Viscoelastic S0-like: `100%`.

Therefore, selecting the global minimum, the largest condition-number peak, or the lowest phase velocity is not a reliable modal tracking strategy for soft fluid-loaded layers.

### 3. Continuity must be interpreted together with dispersion and local-minimum evidence

The largest relative jumps for A0-like branches occur at the first low-frequency interval, where the A0-like branch is strongly dispersive and Cp is still small. This can inflate relative jump metrics even when the curve is physically smooth.

For S0-like branches, the maximum relative jumps are smaller and occur within a monotonic descending branch or near the end of the valid real-k segment.

The diagnostic therefore reports both:

- continuity metrics; and
- local residual-minimum agreement.

A large relative jump should be inspected using the maximum-jump table, not interpreted automatically as branch switching.

### 4. Han viscoelastic real-k behaves conservatively

For viscoelastic real-k cases, the solver returns only one valid branch segment and cuts the branch when the modal-local real-k solution is no longer available.

This is the intended behavior:

- Do not force the branch using the seed.
- Do not jump to the global low-Cp valley.
- Do not extrapolate across invalid points.

### 5. Brute-force scanning is useful diagnostically but not sufficient as a solver

The brute-force scan is useful for visualizing the residual landscape and confirming that the tracker lies near a local minimum. However, a brute-force scan alone does not solve the modal-selection problem.

It still needs:

- modal reference information;
- local-minimum selection;
- continuity constraints;
- branch-specific windows;
- branch-cut logic.

For elastic cases, the current tracker is faster than the estimated full brute-force scan. For some viscoelastic cases, brute-force scanning may appear comparable in raw time, but it does not include the logic required to identify the physical branch reliably.

## Recommended use

Run the diagnostic from the repository root after `startup`:

```matlab
examples/diagnostics/compare_mrlfe_tracker_vs_condition_peaks
```

Edit the case at the top of the script:

```matlab
branchName = "A0Like";              % "A0Like" or "S0Like"
modelName  = "mRLFEElasticRealK";   % "mRLFEElasticRealK" or "mRLFEHanViscoRealK"
```

Recommended cases to keep checking:

```matlab
% Elastic A0-like
branchName = "A0Like";
modelName  = "mRLFEElasticRealK";

% Elastic S0-like
branchName = "S0Like";
modelName  = "mRLFEElasticRealK";

% Viscoelastic A0-like
branchName = "A0Like";
modelName  = "mRLFEHanViscoRealK";

% Viscoelastic S0-like
branchName = "S0Like";
modelName  = "mRLFEHanViscoRealK";
```

Keep the committed default as:

```matlab
branchName = "A0Like";
modelName  = "mRLFEElasticRealK";
```

This gives a stable baseline case when the diagnostic is opened or run without editing.

## Recommended wording for discussion

The solver does not simply minimize the global residual. In soft fluid-loaded layers, the global minimum can fall into a low-Cp spurious valley. The current solver instead follows mode-relevant local residual minima using modal references and continuity constraints. The diagnostic shows that the tracked branches are continuous and lie very close to local residual minima, while the global minimum often selects the wrong Cp.
