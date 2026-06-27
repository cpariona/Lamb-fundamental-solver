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
diagnose_direct_atlas_etaS_zero_limit
diagnose_mrlfe_visco_validity_breakdown
diagnose_mrlfe_visco_residual_landscape
stress_test_mrlfe_real_k_range
```

## Direct atlas unification question

The direct viscous atlas route is currently validated for A0Like `etaS` fitting, not as the general mRLFE forward solver.

The diagnostic:

```matlab
diagnose_direct_atlas_etaS_zero_limit
```

checks whether the same direct residual-atlas route can reproduce the maintained elastic real-k mRLFE branch when `etaS = 0`.

Use this diagnostic before considering any interface policy that replaces the maintained elastic/cache workflow with a unified direct-atlas route.

Interpretation:

```text
A0Like etaS=0 agrees and S0Like etaS=0 agrees:
    direct atlas may be considered as a candidate unified mRLFE route.

A0Like etaS=0 agrees but S0Like etaS=0 fails:
    restrict direct atlas to A0Like workflows.

etaS=0 fails or truncates:
    keep the maintained elastic reference workflow.
```

## Policy

Diagnostic documents may preserve quantitative evidence and interpretation. They should not define the active API contract unless the conclusion is also summarized in `../fitting_workflow.md` or `../README.md`.
