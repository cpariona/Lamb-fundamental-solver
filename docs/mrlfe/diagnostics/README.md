# mRLFE diagnostic documentation

This folder contains diagnostic evidence for the maintained mRLFE solver and tracking workflow.

## Current diagnostic summaries

```text
tracker_diagnostic_summary.md
```

## Related maintained diagnostics

The corresponding executable diagnostics live under:

```text
examples/mrlfe/diagnostics/
```

Representative diagnostics:

```matlab
compare_mrlfe_tracker_vs_condition_peaks
diagnose_etaS_direct_atlas_fit
diagnose_etaS_forward_cache
diagnose_fit_timing
diagnose_fit_option_sensitivity
diagnose_mrlfe_visco_direct_atlas
diagnose_mrlfe_visco_validity_breakdown
diagnose_mrlfe_visco_residual_landscape
stress_test_mrlfe_real_k_range
```

## Policy

Diagnostic documents may preserve quantitative evidence and interpretation. They should not define the active API contract unless the conclusion is also summarized in `../fitting_workflow.md` or `../README.md`.
