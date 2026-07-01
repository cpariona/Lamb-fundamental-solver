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

Current diagnostic outcome:

```text
A0Like etaS=0:
    The direct atlas finds the first point with small Cp error, but the branch is truncated after that point.
    It is not suitable as the general elastic A0Like route yet.

S0Like etaS=0:
    The forced direct atlas agrees closely with the maintained elastic branch in the tested window.
    This is useful evidence, but S0Like direct atlas has not completed the same validation path as A0Like etaS fitting.
```

Current interpretation:

```text
Do not replace the maintained mRLFE workflow with the direct atlas route.
Keep direct atlas limited to the validated A0Like etaS fitting path.
Keep maintained RL -> mRLFE elastic -> mRLFE viscous workflow for general GUI and sweep use.
Treat S0Like direct-atlas agreement as preliminary diagnostic evidence only.
```

A future unification attempt should first solve the A0Like etaS=0 truncation and then run a dedicated S0Like direct-atlas validation.

## Policy

Diagnostic documents may preserve quantitative evidence and interpretation. They should not define the active API contract unless the conclusion is also summarized in `../fitting_workflow.md` or `../README.md`.
