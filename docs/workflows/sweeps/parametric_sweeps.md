# Parametric sweeps

The maintained executable examples deliberately cover one representative 1D
sweep per model plus one AE 2D grid:

```matlab
run('examples/rayleigh_lamb/sweeps/rl_sweep_thickness_A0.m')
run('examples/mrlfe/sweeps/mrlfe_sweep_etaS_A0Like.m')
run('examples/acoustoelastic_iop_hgo/sweeps/ae_sweep_iop_A0Like.m')
run('examples/acoustoelastic_iop_hgo/sweeps/ae_sweep_mu_iop_A0Like.m')
```

Reusable orchestration belongs to `runParametricSweep` and the model-owned
`rlRunSweep`, `mrlfeRunSweep`, `aeRunSweep`, and `aeRunGridSweep` helpers.
Plot-data construction is separate from rendering and persistence; generated
tables and figures are untracked run artifacts below the canonical `Results/`
roots.

SweepTool uses `guiBuildSweepRequest`, `guiRunSweep`, and
`guiNormalizeAcoustoelasticIOPHGOSweep` rather than invoking example scripts.
Additional parameters and branches are exercised through
`run_extended_integration_tests`.
