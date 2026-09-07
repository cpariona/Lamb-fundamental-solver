# Parametric sensitivity studies

Sweep is secondary infrastructure for repeated calls to a canonical solver.
The only production sweep API is:

```matlab
lamb.sweeps.runParametricSweep
```

It applies parameter values, invokes a supplied evaluator, and records results,
requests, timing, and point status. It owns no physics, model policy, plotting,
persistence, GUI state, or sensitivity interpretation.

Maintained campaigns are opt-in studies:

```matlab
run('studies/sensitivity/rayleigh_lamb/study_thickness_A0.m')
run('studies/sensitivity/mrlfe/study_etaS_A0Like.m')
run('studies/sensitivity/acoustoelastic_iop_hgo/study_iop_A0Like.m')
run('studies/sensitivity/acoustoelastic_iop_hgo/study_mu_iop_A0Like.m')
```

The family study folders own parameter ranges, solver configuration, summary,
plotting, and output persistence. Every evaluated point calls the corresponding
canonical model API. Study code is not placed on the production path by
`startup`.
