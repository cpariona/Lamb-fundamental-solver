# AE IOP/HGO sensitivity studies

Two opt-in studies represent the maintained sensitivity surface:

```matlab
run('studies/sensitivity/acoustoelastic_iop_hgo/aeStudyIOPAtlasA0.m')
run('studies/sensitivity/acoustoelastic_iop_hgo/aeStudyMuIOPAtlasA0.m')
```

The first is the canonical one-dimensional pressure sweep. The second is the
canonical two-dimensional material-pressure grid. They call `aeRunSensitivity` and
`aeRunGridSensitivity`, which use the production `atlasA0` solver route and canonical
result arrays.

Other parameter combinations are covered by automated contracts instead of
duplicate scripts. The studies are not loaded by `startup`; each calls the
canonical solver and the generic `lamb.sweeps.runParametricSweep` engine where
applicable.
