# Execution Profiles Benchmark

## Reproducible script

Run from MATLAB:

```matlab
startup
results = run_execution_profile_benchmark('Repeats', 3);
```

Output:

```text
analysis/performance/execution_profile_benchmark_results.csv
```

The benchmark is intentionally headless. It records MATLAB version and platform, runs each case at least three times by default, and does not enforce absolute wall-clock limits.

## Cases

| Model | Cases | Profiles | Measurements |
| --- | --- | --- | --- |
| Rayleigh-Lamb | A0, S0, 1-12 kHz | Fast, Balanced, Robust | elapsed time, valid fraction, max jump, Cp difference vs Robust |
| mRLFE | A0Like/S0Like, etaS=0 and etaS>0 | maintained effective current route | elapsed time, route, atlas preset, valid fraction, max jump, scan points |
| AE IOP/HGO | atlasA0, PR #98 physical defaults | Fast, Balanced, Robust | elapsed time, valid fraction, max jump, Cp difference vs Robust, atlas density |
| Fitting | one short RL, mRLFE, AE fit | Fast defaults | elapsed fit time and RMSE summary |

## Interpretation rules

- The first run should be treated as possible warm-up. Compare repeated runs rather than a single timing.
- The script does not force artificial mRLFE comparisons by disabling maintained route policies.
- mRLFE results should be interpreted by effective route and atlas preset, not only by requested `robustness`.
- AE Robust is expected to cost more than Fast because atlas Y resolution and retained minima increase.

## Expected qualitative outcomes

These are expected from code structure and should be checked against local benchmark output:

1. RL `Robust` should be slower than `Fast` because `gridPointsInitial` and `gridPointsTracking` are much larger.
2. mRLFE Fit should report `fast_fit_atlas` even when a caller conceptually asks for the fit workflow, because the maintained atlas fit route applies that preset.
3. mRLFE `etaS=0` and `etaS>0` should report different paths: zero-viscosity adaptive atlas versus viscous unified atlas.
4. AE `Fast/Balanced/Robust` should report 300/12, 600/16, and 900/20 when called through `aeDefaultSweepOptions`.
5. Short fitting cases should show why solver profile cost multiplies optimizer cost: each objective evaluation invokes the relevant solver/evaluator.

## Benchmark limitations

- The mRLFE benchmark uses reduced frequency grids so it can run as a CI-adjacent diagnostic. It is not a publication-grade convergence study.
- The AE benchmark uses the current FitTool/default physical constants:
  `rho=1060`, `rhoF=1000`, `fluidBulkModulus=2.2e9`, `R=7.8e-3`,
  `thickness=550e-6`, `IOP=15*133.322`, `mu=64e3`,
  `k1=50e3`, `k2=200`.
- CSV output is small and reproducible, but should not be treated as a cross-machine performance contract.

## Cost implications for default policy

| Proposed surface default | RL | mRLFE | AE |
| --- | --- | --- | --- |
| Main GUI -> Balanced | Viable | Viable with warning: GUI fast atlas route still dominates atlas density. | Viable with warning: Balanced means 600/16 atlas cost. |
| SweepTool -> Fast | Viable for speed, lower quality than Balanced. | Viable and already current default; preserves deliberate fast GUI route. | Viable and already current default. |
| FitTool -> Fast | Viable and current. | Required for practical fitting unless a model-specific profile is introduced. | Viable and current via explicit 300/12/50 override. |
