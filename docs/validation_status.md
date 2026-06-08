# Validation status

This document summarizes the current numerical/physical status of the main solver components.

| Component | Current status | Main validation script | Notes |
|---|---|---|---|
| Rayleigh-Lamb A0 | Stable baseline | `examples/validation/check_default_outputs.m` | Main reference branch for A0-like problems. |
| Rayleigh-Lamb S0 | Implemented, experimental | `examples/validation/check_default_outputs.m` | Needs benchmarking against a trusted reference before final use. |
| mRLFE elastic real-k A0-like | Stable to 16 kHz for tested range | `examples/validation/stress_test_mrlfe_elastic_range.m` | Uses multicandidate DP tracking. |
| mRLFE elastic real-k S0-like | Numerically stable in tested range, physically experimental | `examples/validation/stress_test_mrlfe_elastic_range.m` | Needs trusted S0/fluid-loaded benchmark. |
| mRLFE Han visco real-k A0-like | Conservative modal-local tracker | `examples/validation/stress_test_mrlfe_han_visco_range.m` | Uses modal Cp window and previous-point continuity cutoff. |
| mRLFE Han visco real-k S0-like | Conservative modal-local tracker, experimental | `examples/validation/stress_test_mrlfe_han_visco_range.m` | S0-like remains more sensitive to branch switching and needs benchmarking. |
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

## Current interpretation of Han real-k branch cuts

After modal-local stabilization, branch cuts should be interpreted conservatively. A cut usually means that the solver did not find a local residual minimum satisfying all of the following:

1. branch-specific modal Cp window around the elastic real-k reference;
2. previous-point continuity;
3. finite residual/Cp.

The branch should not be extrapolated across these cuts.

## Recommended next validation tasks

1. Add a focused validation case reproducing GUI-like settings where branch switching is observed between the current stress-test grid points.
2. Benchmark S0-like against an independent trusted Rayleigh-Lamb/fluid-loaded reference.
3. Build focused complex-k diagnostics for cases where the Han real-k modal minimum disappears.
