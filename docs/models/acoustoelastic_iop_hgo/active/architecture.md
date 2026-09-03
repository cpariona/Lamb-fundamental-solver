# AE IOP/HGO architecture

The public solver `solveAcoustoelasticIOPHGOBranch` owns request validation and
delegates production computation to the model layer. `aeResolveConfiguration`
and `aeGetNumericalPreset` own configuration; atlas construction, linking,
selection, fallback, quality assessment, and result construction remain
separate model responsibilities.

```text
app consumers -> public solver -> atlasA0 tracking -> quality -> canonical result
analysis fit/sweep -----------^
diagnostics -------------------- inspection only
```

The model layer does not depend on `analysis/`, `app/`, `examples/`, or
`tests/`. Analysis owns fitting, sweep orchestration, plotting, persistence,
and diagnostic interpretation. Application code owns surface translation and
presentation. Examples only compose maintained APIs.

No diagnostic branch can replace production selection or result construction.
The numerical regression golden and its tolerance are independent contracts.
