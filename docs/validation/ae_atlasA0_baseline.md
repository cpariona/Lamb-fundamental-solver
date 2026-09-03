# AE atlasA0 scientific baseline decision

## Decision

GOLDEN UPDATE RECOMMENDED — conclusive evidence permits the explicitly
authorized Phase 7 update in a separate scientific-baseline commit.
This record is prepared before that update. The update changes only three
snapshot values, never the 1e-12 tolerance or production solver.

## Causal reproduction

MATLAB R2024b, Windows, 2026-09-03. Models were extracted with git archive
to disposable temporary directories and evaluated in isolated MATLAB paths.
The current working tree was not checked out backwards.

- Golden origin: 5762b7475d598d1673fe27defbe633a2f8345477.
- Last pre-refinement result: parent of 026994f86a2d1dfe5a740034d7a5fd81d4f08235.
- Causal commit: 026994f86a2d1dfe5a740034d7a5fd81d4f08235,
  "Replace AE parabolic refinement with bounded continuous refinement".
- Golden origin and causal parent match exactly at all 35 points.
- Causal commit and current solver match exactly at all 35 points.
- All four revisions have the same all-valid 35-point mask.

The old implementation refined three-point parabolic candidates before
selection. The approved canonical algorithm discovers discrete atlas minima,
links and selects atlasA0, then uses bounded fminbnd on the true SVD objective.
The Phase 7 request expressly protects that algorithm; reverting it merely to
match the earlier snapshot would contradict the scientific contract.

## Fixture and delta

R=7.8e-3 m, thickness=550e-6 m, mu=50e3 Pa, k1=25e3 Pa, k2=100,
rho=1060 and rhoF=1000 kg/m3, fluidBulkModulus=2.2e9 Pa, IOP=15*133.322 Pa.
Frequency is logspace(log10(300),log10(15000),35) Hz.
Use defaultAcoustoelasticIOPHGOOptions with corrected M54, normalizeRows=false,
usePhysicalCpWindow=false, atlasNumYPoints=300, atlasTopNMinima=12, atlasA0.
The fixture is maintained in
`tests/shared/regression/test_lightweight_numerical_regression.m`.

Signed delta is current minus old; relative delta is divided by old Cp.

| Index | Old Cp (m/s) | Current Cp (m/s) | Signed delta (m/s) | Relative delta |
| --- | --- | --- | --- | --- |
| 1 | 2.4468847811699295 | 2.4556775089884897 | 0.0087927278185602198 | 0.0035934376175882506 |
| 18 | 4.9263188405152958 | 4.9399570500019010 | 0.013638209486605213 | 0.0027684382452960858 |
| 35 | 6.7463630764435090 | 6.7283432297787886 | -0.018019846664720340 | -0.0026710460822425663 |

All-point maximum absolute delta is 0.027833771811266672 m/s at index 34,
13369.696635851533 Hz. Maximum absolute relative delta is
0.0041853517011645937 (0.41853517011645937%).
There are 21 positive and 14 negative deltas: not a constant offset or scale.
The signs in index order are:
`+++++++++++++--+-+-+------++-+-+-+-`.
The changing signs are consistent with removal of grid-local parabolic bias;
the exact causal replay, not that interpretation alone, establishes provenance.

## Independent scientific guards (before update)

- True SVD recomputation at every refined requested point agrees with the
  reported objective and improves on the discrete selected seed.
- Turning refinement off leaves minimaTable, nearestRank, nearestBranchID,
  and validMask exactly unchanged; atlas candidate velocities stay on cGrid.
- Tightening log-Cp tolerance from 1e-6 to 1e-10 with 100 iterations/evaluations
  changes Cp by at most 1.4405056507627023e-6 m/s. The independent convergence
  guard is 3e-6 m/s; it does not replace or loosen the snapshot tolerance.
- 600-point and 900-point atlas grids retain all 35 valid points and differ
  from the 300-point result by at most 2.6588420301010274e-6 and
  2.3133361377603023e-6 m/s respectively.
- Old true-SVD log10 values at indices 1/18/35:
  -2.8353722289085983, -2.2039820664918768, -1.7673107188040962.
  Current: -7.2272075482683604, -6.393753908681143, -7.0813098366274003.
  All-point median improves from -2.2911344587728748 to -6.9434163715941484.
- Fresh synthetic atlasA0 fitting recovers mu with relative error 5.06201e-08.

The permanent independent test is
`tests/models/acoustoelastic_iop_hgo/test_ae_tracking_policy_characterization.m`.
It passed before the golden change. These are numerical/constitutive checks,
not experimental proof for every parameter regime. Grid convergence does not
establish universal branch identity near ambiguous crossings.

All six validation tiers must run again after the separate baseline commit.
The completed results belong in `docs/repository/validation_status.md`.
