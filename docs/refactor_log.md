# Refactor log: Li 2024 and mRLFE cleanup

This document records the structural cleanup performed after the Li 2024 acoustoelastic and mRLFE solver development work.

## Objective

Separate active model code, maintained examples, diagnostics, documentation, and tests into a clearer structure without changing validated solver behavior.

The cleanup policy was:

1. move files first;
2. verify MATLAB path resolution with `which`;
3. run smoke tests;
4. remove legacy locations only after the new paths worked;
5. update documentation after code paths were stable.

## Final active structure

### Li 2024 acoustoelastic model

```text
models/li2024_acoustoelastic/core/
models/li2024_acoustoelastic/constitutive/
models/li2024_acoustoelastic/solvers/
models/li2024_acoustoelastic/options/
examples/li2024/basic/
examples/li2024/sweeps/
examples/li2024/diagnostics/