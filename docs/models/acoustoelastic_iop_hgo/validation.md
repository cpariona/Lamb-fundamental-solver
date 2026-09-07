# AE atlasA0 validation

The numerical regression fixture uses radius 7.8 mm, thickness 550 micrometres,
`mu = 50 kPa`, `k1 = 25 kPa`, `k2 = 100`, tissue density 1060 kg/m3,
fluid density 1000 kg/m3, fluid bulk modulus 2.2 GPa, and IOP 15 mmHg over
35 logarithmically spaced frequencies from 300 to 15000 Hz. It uses the
canonical atlasA0 solver with corrected M54, row normalization disabled, no
physical Cp window, 300 atlas points, and 12 retained local minima.

The fixture is maintained by
`tests/models/test_lightweight_numerical_regression.m`. Its snapshot tolerance
is `1e-12` and is not relaxed for structural work.

Independent characterization protects the scientific meaning behind the
snapshot:

- requested points recompute the true SVD objective after bounded refinement;
- disabling refinement leaves atlas candidates, branch identity, ranks, and the
  valid mask unchanged;
- tighter bounded-refinement tolerances converge within 3e-6 m/s;
- 600- and 900-point atlas grids retain all fixture points and agree with the
  300-point curve within 3e-6 m/s;
- synthetic atlasA0 fitting recovers shear modulus without diagnostic or
  fallback branches.

The canonical algorithm discovers discrete atlas minima, links branches,
selects atlasA0, and then refines the selected branch continuously. Grid
convergence and synthetic recovery are numerical/constitutive checks; they do
not establish universal branch identity near ambiguous crossings or prove
experimental accuracy for every parameter regime.

Run `run_numerical_regression_tests` for the snapshot and tracking guards, then
the remaining runners in [repository validation](../../validation.md).
