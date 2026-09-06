# mRLFE restructuring baseline investigation

## Historical status

RESOLVED. This document records the numerical configuration regression that was
found during the earlier restructuring investigation. It is retained as
historical evidence, not as a current integration blocker.

The demonstrated cause was the adaptive tracker edge-guard mapping. The current
canonical configuration uses `trackerEdgeGuardPoints = 4`, which restores the
historical behavior identified by the counterfactual below. The subsequent
numerical-alignment campaign completed with maintained numerical regression and
benchmark gates passing. No scientific golden or tolerance was changed to hide
this regression.

## Reference and measured difference

Reference: Phase 1 commit `1b6b3a15a7ce46b1644918383e1bd6a1c630f5f4`.
Its models tree was extracted with git archive into a disposable directory.
The same 24 Fast / 6 Dense fixture was evaluated there and the resulting
fastResults/denseResults arrays saved outside the repository.
Reference MAT SHA-256:
`20CD747EA6BBA34FC6578ED5835B3621E5416A594D50BA40BA273F7E2B47B599`.

The then-current solver was checked again in a fresh session with
`restoredefaultpath` and current `startup`; `which` resolved the then-current
`lamb.models.mrlfe.mrlfeSolve` and RL seed API. Historical comparison failed the unchanged 1e-10
characterization tolerance before the configuration correction described below.

The Fast matrix uses A0Like/S0Like, mu=[50,75,158,250] kPa, etaS=[0,0.05,0.10]
Pa*s, rho=1000 kg/m3, nu=0.4999, thickness=0.5 mm, fluid density=1000 kg/m3,
fluid sound speed=1500 m/s, and 20 equally spaced requested frequencies from
1000 to 12000 Hz. A0Like termination is physicalTail; S0Like is none;
fallback is none.

| Fast case | Branch | mu (kPa) | etaS (Pa*s) | Maximum absolute Cp delta (m/s) |
| --- | --- | ---: | ---: | ---: |
| 4 | A0Like | 250 | 0 | 0.0109435516278 |
| 8 | A0Like | 250 | 0.05 | 0.0120684309767 |
| 12 | A0Like | 250 | 0.10 | 0.0101885782475 |

The other 21 Fast cases matched exactly. Overall maximum relative difference
was 0.00113100537214 (0.113100537214%); there were no mask differences.
Dense used mu=75 kPa and the same three viscosities/two branches. Its six
independent comparisons completed with maximum absolute and relative Cp delta
0, identical finite patterns, and no mask differences.

## Cause and counterfactual

The source mapping changed in
`a59ab9d25c386022bdf519be7aefc86e8ad98b3f`,
"refactor: reduce RL and mRLFE API configuration".

Before that commit, configuration stored mrlfeA0DPEdgeGuardPoints=8, while the
actual adaptive tracker consumed mrlfeAdaptiveEdgeGuardPoints, absent from the
public production configuration, and therefore used its default 4.
The renamed trackerEdgeGuardPoints was initialized to 8 and was then consumed
by the adaptive tracker. This changed the candidate exclusion near scan-window
edges, rather than merely renaming an effective setting.

Relevant owners are
`src/+lamb/+models/+mrlfe/+configuration/mrlfeResolveConfiguration.m`,
`src/+lamb/+models/+mrlfe/+solvers/mrlfeSolveViscoelasticBranch.m`, and
`src/+lamb/+models/+mrlfe/+tracking/mrlfeTrackBranchAdaptive.m`.

A read-only counterfactual resolved the configuration, changed only the
in-memory `internalOptions.trackerEdgeGuardPoints` from 8 to 4, and executed the
same model problem/solver/result pipeline. All 24 Fast cases then matched Phase
1 exactly: maximum absolute and relative Cp delta 0, mask differences 0. No
source files or caller presets were changed for that experiment.

## Why earlier PASS reports did not establish preservation

The inherited production-core matrix initialized difference statistics to zero
but never populated them from a historical comparison. Its printed zero was
not a measured regression result. The maintained test now explicitly reports
schema/coverage only without a reference, and computes real differences when
a reference file is supplied:

`tests/models/mrlfe/test_mrlfe_production_core_characterization.m`.

The 24-case GUI/FitTool/SweepTool comparisons compute differences, but compare
each consumer with the current public solver. Their exact equality proves
adapter consistency, not preservation against Phase 1. This distinction remains
important when interpreting characterization evidence.

## Resolution

The demonstrated correction was to restore the adaptive tracker edge guard to
4 in canonical model configuration. The current configuration retains that
value. The regression is therefore no longer an integration blocker; this file
remains as the audit trail explaining why historical comparison was required
and why consumer-equality tests alone were insufficient.
