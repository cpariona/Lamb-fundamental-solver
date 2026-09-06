function test_ae_analyze_truncation_recovery()
%TEST_AE_ANALYZE_TRUNCATION_RECOVERY Unit test for aeAnalyzeTruncationRecovery.

frequency = (1:6) * 1e3;
Cp = [1.0 1.1 nan 1.3 nan 1.5];
validCp = isfinite(Cp);

minimaTable = table();
minimaTable.Frequency_Hz = [3e3; 5e3];
minimaTable.Frequency_kHz = [3; 5];
minimaTable.MinRank = [2; 1];
minimaTable.Cp_mps = [1.2; 0.4];
minimaTable.y = [0.2; 0.07];
minimaTable.log10y = log10(minimaTable.y);
minimaTable.Objective = [10; 1];
minimaTable.DepthRelativeToMedian = [1; 1];
minimaTable.DepthRelativeToDeepest = [0; 0];
minimaTable.SpacingToNearestLogY = [inf; inf];
minimaTable.BranchID = [4; 5];

result = struct();
result.frequency_Hz = frequency;
result.phaseVelocity_mps = Cp;
result.validMask = validCp;
result.minimaTable = minimaTable;

recovery = aeAnalyzeTruncationRecovery(result, ...
    'MaxRelativeCpDistance', 0.12, ...
    'MaxRelativeBridgeMismatch', 0.20, ...
    'MaxGapPoints', 1, ...
    'MaxGapFrequencyRatio', 2.0);

assert(recovery.recoveredValid(3), 'Third point should recover through a local minimum near previous Cp.');
assert(abs(recovery.recoveredCp(3) - 1.2) < 1e-12, 'Unexpected local-minimum recovered Cp.');
assert(recovery.recoveryMode(3) == "localMinimumNearPreviousCp", 'Unexpected recovery mode for local minimum.');
assert(recovery.recoveredValid(5), 'Fifth point should recover through small-gap bridge.');
assert(abs(recovery.recoveredCp(5) - 1.4) < 1e-12, 'Unexpected bridge-interpolated Cp.');
assert(recovery.recoveryMode(5) == "smallGapBridge", 'Unexpected recovery mode for small-gap bridge.');
assert(recovery.summary.NumRecoveredPoints == 2, 'Unexpected number of recovered points.');
assert(recovery.summary.NumLocalMinimumRecoveries == 1, 'Unexpected number of local-minimum recoveries.');
assert(recovery.summary.NumSmallGapBridgeRecoveries == 1, 'Unexpected number of bridge recoveries.');
assert(recovery.summary.NumContiguousRecoveredPoints == 2, 'Unexpected number of contiguous recovered points.');
assert(recovery.summary.NumContiguousLocalMinimumRecoveries == 1, 'Unexpected number of contiguous local-minimum recoveries.');
assert(recovery.summary.NumContiguousSmallGapBridgeRecoveries == 1, 'Unexpected number of contiguous bridge recoveries.');
assert(recovery.summary.NumPointwiseRecoveriesAfterContiguousBreak == 0, 'Unexpected pointwise recoveries after contiguous break.');
assert(isnan(recovery.summary.FirstMissingAfterContiguousRecovery_kHz), ...
    'There should be no missing frequency after contiguous recovery in this fixture.');
assert(abs(recovery.summary.LastContiguousRecoveredFrequency_kHz - 6) < 1e-12, ...
    'Unexpected last contiguous recovered frequency.');

fprintf('test_ae_analyze_truncation_recovery passed.\n');
end
