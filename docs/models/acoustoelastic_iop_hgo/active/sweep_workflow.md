# AE IOP/HGO sweep workflow

Two examples represent the maintained sweep surface:

```matlab
ae_sweep_iop_A0Like
ae_sweep_mu_iop_A0Like
```

The first is the canonical one-dimensional pressure sweep. The second is the
canonical two-dimensional material-pressure grid. They call `aeRunSweep` and
`aeRunGridSweep`, which use the production `atlasA0` solver route and canonical
result arrays.

SweepTool reaches the same workflow through `guiBuildSweepRequest` and
`guiRunSweep`. Other parameter combinations are covered by automated contracts
instead of duplicate scripts. Run `run_extended_integration_tests` after sweep
or consumer changes.
