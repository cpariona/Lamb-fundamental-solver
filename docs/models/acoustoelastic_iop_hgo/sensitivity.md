# AE IOP/HGO sensitivity studies

Two opt-in studies represent the maintained sensitivity surface:

```matlab
run('studies/sensitivity/acoustoelastic_iop_hgo/study_iop_A0Like.m')
run('studies/sensitivity/acoustoelastic_iop_hgo/study_mu_iop_A0Like.m')
```

The first is the canonical one-dimensional pressure sweep. The second is the
canonical two-dimensional material-pressure grid. They call `runAcoustoelasticSensitivity` and
`runAcoustoelasticGridSensitivity`, which use the production `atlasA0` solver route and canonical
result arrays.

Other parameter combinations are covered by automated contracts instead of
duplicate scripts. The studies are not loaded by `startup`; each calls the
canonical solver and the generic `lamb.sweeps.runParametricSweep` engine where
applicable.
