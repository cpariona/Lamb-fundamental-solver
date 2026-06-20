### atlasA0 truncation validation closure

This note documents the validation outcome for the acoustoelastic IOP/HGO `atlasA0` branch policy and separates maintained solver behavior from diagnostic-only analysis layers.

### Scope

The validation focused on high-frequency truncation of the maintained `atlasA0` branch in IOP and shear-modulus sweeps. The goal was to determine whether missing high-frequency portions are caused by physical/model limitations, residual-landscape ambiguity, conservative branch tracking, or a failure mode of the branch-selection algorithm.

The validated workspaces were generated from maintained short entrypoints:

```matlab
sweep_iop
sweep_mu
diagnose_atlas_truncation
```

The older descriptive aliases used during early validation have been archived.

### Maintained solver decision

The official solver branch remains:

```text
atlasA0
```

The official output should remain conservative:

```matlab
result.frequency
result.Cp
result.validCp
```

Missing high-frequency values should remain `NaN` when `atlasA0` cannot maintain a defensible continuous A0-like branch. The official solver should not automatically replace those values with pointwise recoveries or relaxed-threshold reconnections.

### Components that remain maintained

The following helpers are useful as maintained validation and diagnostic infrastructure:

```text
analysis/acoustoelastic_iop_hgo/aeAnalyzeSweepReliability.m
analysis/acoustoelastic_iop_hgo/aeAnalyzeTruncationCase.m
analysis/acoustoelastic_iop_hgo/aeAnalyzeTruncationRecovery.m
analysis/acoustoelastic_iop_hgo/aeClassifyTruncationRecovery.m
analysis/acoustoelastic_iop_hgo/aeSummarizeTruncationRecoveryClassification.m
```

They answer the core validation questions:

```text
Where is atlasA0 valid?
Where does it truncate?
Is the first truncation locally recoverable?
Is recovery contiguous or only pointwise after a break?
```

The following helpers are maintained as diagnostic-only analysis layers:

```text
analysis/acoustoelastic_iop_hgo/aeAnalyzeFirstUnrecoveredBreak.m
analysis/acoustoelastic_iop_hgo/aeAnalyzeBreakThresholdSensitivity.m
analysis/acoustoelastic_iop_hgo/aeCompareThresholdRelaxedBranch.m
analysis/acoustoelastic_iop_hgo/aeAssessThresholdRelaxedBranchQuality.m
analysis/acoustoelastic_iop_hgo/aeClassifyThresholdRelaxedBranchDecision.m
```

These helpers do not define the official branch. They evaluate whether a threshold-relaxed continuation is plausible, weak, or not recommended.

### Components that remain archived or diagnostic-only

The following should not be promoted to official solver output:

```text
legacy_backward_global_scan
pointwise recoveries after an unresolved contiguous break
automatic threshold-relaxed branch replacement
```

`legacy_backward_global_scan` can fill more points but can jump to physically implausible low-speed minima. It remains useful only as a historical comparison.

Pointwise recoveries after a contiguous break should not be interpreted as a continuous physical branch because they may reconnect after an unresolved discontinuity.

Threshold-relaxed branches are useful diagnostic objects, but they must remain separate from `result.Cp`.

### Key diagnostic outcomes

#### IOP sweep

The maintained `atlasA0` branch is monotonic with IOP over the shared valid range. High-IOP cases truncate earlier at high frequency.

Representative truncation behavior:

```text
iop_20mmHg: official branch valid to approximately 18.456 kHz
iop_25mmHg: official branch valid to approximately 15.922 kHz
```

#### Mu sweep

Low shear modulus cases truncate earlier. The low-frequency region is weakly sensitive to shear modulus, while the mid/high-frequency region is more sensitive.

Representative truncation behavior:

```text
mu_25kPa: official branch valid to approximately 9.265 kHz
```

### Threshold-relaxed decision summary

The diagnostic threshold-relaxed branch was classified case by case:

```text
iop_20mmHg: caution_low_rank_branch
iop_25mmHg: weak_partial_extension
mu_25kPa: not_recommended
```

#### iop_20mmHg

The threshold-relaxed branch extends the official branch from approximately 18.456 kHz to 35 kHz using a relaxed relative Cp-distance threshold of 0.15. It adds 13 points, all matched to stored local minima. However, many added points are low-rank minima, so the branch is useful as a diagnostic continuation but should not replace the official `atlasA0` branch.

#### iop_25mmHg

The threshold-relaxed branch adds only a short extension, from approximately 15.922 kHz to 18.456 kHz, and then fails again. It is a weak partial extension and should remain diagnostic only.

#### mu_25kPa

The threshold-relaxed branch is not recommended. It only gives a small extension and includes at least one addition that cannot be matched to a stored local minimum, consistent with a stronger ambiguity or model/branch limitation.

### Solver-level conclusion

`atlasA0` is validated as the maintained conservative branch policy for the acoustoelastic IOP/HGO model.

The high-frequency truncation is not a single failure mode:

```text
iop_20mmHg: likely conservative continuity threshold / branch persistence limitation
iop_25mmHg: partial threshold sensitivity but still unstable at higher frequency
mu_25kPa: not solved by threshold relaxation; likely stronger modal ambiguity or real-valued branch limitation
```
