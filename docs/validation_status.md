# Validation status

This document summarizes the current numerical/physical status of the main solver components.

| Component | Current status | Main validation script | Notes |
|---|---|---|---|
| Rayleigh-Lamb A0 | Stable baseline | `examples/validation/check_default_outputs.m` | Main reference branch for A0-like problems. |
| Rayleigh-Lamb S0 | Implemented, experimental | `examples/validation/check_default_outputs.m` | Needs benchmarking against a trusted reference before final use. |
| mRLFE elastic real-k A0-like | Stable to 16 kHz for tested range | `examples/validation/stress_test_mrlfe_elastic_range.m` | Uses multicandidate DP tracking. Tracker-vs-residual diagnostics support local-minimum consistency. |
| mRLFE elastic real-k S0-like | Numerically stable in tested range, physically experimental | `examples/validation/stress_test_mrlfe_elastic_range.m` | Needs trusted S0/fluid-loaded benchmark. Tracker-vs-residual diagnostics support local-minimum consistency. |
| mRLFE Han visco real-k A0-like | Conservative modal-local tracker | `examples/validation/stress_test_mrlfe_han_visco_range.m` | Uses modal Cp window and previous-point continuity cutoff. Valid branches are intentionally cut when no mode-relevant real-k local minimum remains. |
| mRLFE Han visco real-k S0-like | Conservative modal-local tracker, experimental | `examples/validation/stress_test_mrlfe_han_visco_range.m` | S0-like remains more sensitive and needs benchmarking, but tracker diagnostics support local-minimum consistency in the valid segment. |
| mRLFE complex-k | Experimental/internal | `examples/archive/run_mrlfe_complexk_prototype.m` | Not validated for quantitative attenuation fitting. |

## Current maintained validation workflow

Run from the repository root after `startup`:

```matlab
examples/validation/check_default_outputs
examples/validation/stress_test_mrlfe_elastic_range
examples/validation/stress_test_mrlfe_han_visco_range
```

For Han real-k breakdown analysis:

```matlab
examples/diagnostics/diagnose_mrlfe_han_visco_validity_breakdown
examples/diagnostics/diagnose_mrlfe_han_visco_residual_landscape
```

For tracker-vs-residual landscape evidence:

```matlab
examples/diagnostics/compare_mrlfe_tracker_vs_condition_peaks
```

The current diagnostic summary is documented in:

```text
docs/mrlfe_tracker_diagnostic_summary.md
```

## Current interpretation of Han real-k branch cuts

After modal-local stabilization, branch cuts should be interpreted conservatively. A cut usually means that the solver did not find a local residual minimum satisfying all of the following:

1. branch-specific modal Cp window around the elastic real-k reference;
2. previous-point continuity;
3. finite residual/Cp.

The branch should not be extrapolated across these cuts.

## Tracker-vs-residual diagnostic interpretation

The tracker comparison diagnostic supports the following conclusions for the tested reference case (`E = 100 kPa`, `thickness = 0.5 mm`, `nu = 0.4999`, fluid sound speed `1500 m/s`):

1. tracked elastic and viscoelastic branches lie close to local residual minima;
2. the global residual minimum often selects a low-Cp spurious valley;
3. viscoelastic real-k branches should be treated as conservative valid segments, not extrapolated curves;
4. brute-force residual scanning is useful diagnostically but does not replace modal branch selection and continuity tracking.

See `docs/mrlfe_tracker_diagnostic_summary.md` for the case-by-case metrics.

## Recommended next validation tasks

1. Add a focused validation case reproducing GUI-like settings where branch switching is observed between the current stress-test grid points.
2. Benchmark S0-like against an independent trusted Rayleigh-Lamb/fluid-loaded reference.
3. Build focused complex-k diagnostics for cases where the Han real-k modal minimum disappears.
