# mRLFE execution-profile benchmark

The maintained benchmark characterizes direct public profiles. It does not
encode the historical mapped-to-Fast policy.

## Structural contract

```matlab
[rows, summary] = benchmarkMRLFEExecutionProfiles( ...
    'Mode', "contract", 'RepeatCount', 1, 'WriteCsv', false);
```

Contract mode covers Main GUI, SweepTool, and FitTool; Fast, Balanced, and
Robust; A0Like; and elastic/viscous cases. Main/Fit use the maintained minimum
ten requested frequencies. SweepTool retains its own public grid policy.

The contract verifies requested/effective equality, `direct` support, matching
`fast`/`balanced`/`robust` public presets, no override, profile-independent
route policy, valid monotonic public grids, compatible Cp/mask lengths,
nonnegative timing, and stable output schema. VsFast Cp and common-valid fields
are descriptive and may differ.

## Full descriptive mode

```matlab
[rows, summary] = benchmarkMRLFEExecutionProfiles( ...
    'Mode', "full", 'RepeatCount', 1, 'WriteCsv', true);
```

Full mode adds S0Like and warmups. It is diagnostic/manual, writes no CSV unless
requested, and has no hardware timing threshold. Route, grid, fallback,
quality, profile, and validity metadata remain separate.
