# mRLFE diagnostic documentation

This folder contains diagnostic evidence for the maintained mRLFE solver and
tracking workflow.

## Current Diagnostic Summaries

```text
tracker_diagnostic_summary.md
```

## Related Diagnostics

Executable diagnostics live under:

```text
examples/mrlfe/diagnostics/
```

Retained diagnostics include:

```matlab
compare_mrlfe_tracker_vs_condition_peaks
diagnose_etaS_forward_cache
diagnose_fit_timing
diagnose_fit_option_sensitivity
diagnose_mrlfe_atlas_primary_policy_matrix
diagnose_mrlfe_gui_performance_32kHz
diagnose_mrlfe_visco_validity_breakdown
diagnose_mrlfe_visco_residual_landscape
stress_test_mrlfe_real_k_range
```

Direct-atlas and legacy-route diagnostics were removed with the obsolete mRLFE
route files. Historical findings are retained in `docs/validation/` and in
`docs/validation/mrlfe_legacy_route_inventory.md`.

## Policy

Diagnostic documents may preserve quantitative evidence and interpretation. They
do not define the active API contract unless the conclusion is also summarized in
`../public_api.md`, `../production_core.md`, or `../fitting_workflow.md`.
