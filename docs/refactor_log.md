# Refactor log: Acoustoelastic IOP/HGO and mRLFE cleanup

This document records the structural cleanup performed after the Acoustoelastic IOP/HGO and mRLFE solver development work.

## Objective

Separate active model code, maintained examples, diagnostics, documentation, and tests into a clearer structure without changing validated solver behavior.

The cleanup policy was:

1. move files first;
2. verify MATLAB path resolution with `which`;
3. run smoke tests;
4. remove legacy locations only after the new paths worked;
5. update documentation after code paths were stable.

## Final active structure

### Acoustoelastic IOP/HGO model

```text
models/acoustoelastic_iop_hgo/core/
models/acoustoelastic_iop_hgo/constitutive/
models/acoustoelastic_iop_hgo/solvers/
models/acoustoelastic_iop_hgo/options/
examples/acoustoelastic_iop_hgo/basic/
examples/acoustoelastic_iop_hgo/sweeps/
examples/acoustoelastic_iop_hgo/diagnostics/