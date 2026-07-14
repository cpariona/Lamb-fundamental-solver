# mRLFE robust-start validation

Last reviewed: 2026-07-12

## Scope

The maintained mRLFE production core now applies a neutral forward-only
robust-start policy to `A0Like` tracking.

```text
mrlfeSolve
  -> mrlfeSolveElasticBranch / mrlfeSolveViscoelasticBranch
       -> mrlfeBuildSeed
       -> mrlfeTrackBranchRobustStart
            -> mrlfeTrackBranchAdaptive
       -> mrlfeApplyTerminationPolicy
```

`mrlfeTrackBranchAdaptive` remains the elementary local continuation tracker.
`mrlfeTrackBranchRobustStart` is an orchestration policy around that tracker.

## Behavior

1. Attempt the existing forward adaptive tracking from the first solve frequency.
2. If the required valid run is established, return the original result.
3. If A0Like does not establish, probe configured candidate start frequencies.
4. A probe is accepted only when its first required run is fully valid.
5. Track forward from the first stable candidate to the end of the solve grid.
6. Frequencies before the selected start remain invalid.
7. No backward tracking is performed.

The default candidate frequencies are:

```text
75, 100, 150, 200, 300, 500, 750, 1000 Hz
```

The required stable run is eight points by default.

## Architectural constraints

- Public consumers still call `mrlfeSolve`.
- Main GUI, SweepTool, and FitTool adapters do not select low-level trackers.
- Robust-start is a tracking policy, not a solver fallback.
- `physicalTail` remains a separate termination policy applied after tracking.
- S0Like does not use robust-start.
- The public requested frequency grid remains unchanged.

## Diagnostics

The internal branch result includes:

```text
branch.robustStart.Enabled
branch.robustStart.Attempted
branch.robustStart.Applied
branch.robustStart.StartIndex
branch.robustStart.StartFrequency_Hz
branch.robustStart.ProbesAttempted
branch.robustStart.Reason
```

## Validation

Run:

```matlab
run_mrlfe_production_core_tests
```

The focused regression is:

```matlab
test_mrlfe_robust_start_contract
```

It reproduces the observed low-frequency failure pattern, verifies forward
recovery, confirms that lower frequencies remain invalid, preserves the public
requested grid, and confirms that solver fallback is not reported as applied.

After the contract passes, rerun:

```matlab
validate_grid_presets
```

The repeated grid study should be used to define the final Fast, Balanced, and
Robust frequency-step policies. Those preset values are not fixed by this change.
