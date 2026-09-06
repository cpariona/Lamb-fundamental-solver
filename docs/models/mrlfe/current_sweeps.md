# Current mRLFE sweep

The maintained representative sweep is:

```matlab
run('examples/mrlfe/sweeps/mrlfe_sweep_etaS_A0Like.m')
```

It exercises the public `lamb.models.mrlfe.mrlfeSolve` route using shear viscosity as the swept
parameter and retains the normalized `mRLFEViscoRealK` result model name for
positive viscosity. Reusable orchestration is owned by `mrlfeRunSweep`; output
data are written below `Results/mrlfe/<task>` and figures are generated only as
untracked run artifacts.

Other parameter and branch combinations are covered by automated contracts and
characterization matrices rather than duplicate executable examples.
