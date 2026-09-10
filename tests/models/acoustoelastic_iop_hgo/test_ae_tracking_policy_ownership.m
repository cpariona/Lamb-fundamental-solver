function test_ae_tracking_policy_ownership()
%TEST_AE_TRACKING_POLICY_OWNERSHIP Verify canonical model-layer ownership.

assertLocalMinimaContract();
assertLinkContract();
assertSplitContract();
assertSelectionContract();
assertFallbackContract();

fprintf('AE tracking and policy ownership passed.\n');
end

function assertLocalMinimaContract()
cGrid = [10; 20; 30; 40; 50];
objective = [5; 1; 5; 2; 6];
options = struct('refineLocalMinima', false);
minima = lamb.models.acoustoelastic_iop_hgo.tracking.aeFindAtlasLocalMinima(cGrid, objective, 10, 4, options);
assert(isequal(minima.Cp_mps, [20; 40]));
assert(isequal(minima.y, [2; 4]));
assert(isequal(minima.Objective, [1; 2]));
end

function assertLinkContract()
frequency = [100; 100; 200; 200; 300; 300];
rank = [1; 2; 1; 2; 1; 2];
logY = [0; 1; 0.02; 1.02; 0.04; 1.04];
y = 10 .^ logY;
cp = 100 .* y;
T = table(frequency, frequency ./ 1e3, rank, cp, y, logY, ...
    [1; 2; 1.1; 2.1; 1.2; 2.2], ones(6,1), zeros(6,1), ...
    ones(6,1), nan(6,1), 'VariableNames', {'Frequency_Hz', ...
    'Frequency_kHz', 'MinRank', 'Cp_mps', 'y', 'log10y', 'Objective', ...
    'DepthRelativeToMedian', 'DepthRelativeToDeepest', ...
    'SpacingToNearestLogY', 'BranchID'});
options = struct('atlasMaxLogYJump', 0.10, 'atlasSplitOnLargeCpJump', false, ...
    'atlasMaxRelativeCpJump', 0.05, 'atlasMinBranchPoints', 2);
[linked, branches] = lamb.models.acoustoelastic_iop_hgo.tracking.aeLinkAtlasBranches(T, options);
assert(isequal(linked.BranchID, [1; 2; 1; 2; 1; 2]));
assert(isequal(branches.BranchID, [1; 2]));
assert(isequal(branches.NumPoints, [3; 3]));
assert(isequal(branches.FrequencyStart_Hz, [100; 100]));
assert(isequal(branches.FrequencyEnd_Hz, [300; 300]));
end

function assertSplitContract()
T = table([1; 2; 3; 4; 5; 6], [100; 200; 300; 400; 500; 600], ...
    [100; 101; 102; 150; 151; 152], ones(6,1), ...
    'VariableNames', {'Index', 'Frequency_Hz', 'Cp_mps', 'BranchID'});
split = lamb.models.acoustoelastic_iop_hgo.tracking.aeSplitAtlasBranches(T, 0.10, 3);
assert(isequal(split.BranchID, [2; 2; 2; 3; 3; 3]));
discarded = lamb.models.acoustoelastic_iop_hgo.tracking.aeSplitAtlasBranches(T, 0.10, 4);
assert(all(isnan(discarded.BranchID)));
end

function assertSelectionContract()
T = table([1; 2], [16; 16], [300; 300], [12000; 12000], [0.3; 0.3], ...
    [12; 12], [11.7; 11.7], [120; 450], [180; 500], [0.2; 0.8], ...
    [0.4; 0.9], [1; 5], [1; 5], [120; 450], [180; 500], [150; 475], ...
    [0.3; 0.85], [2; 5], [1; 1], [0.1; 0.2], [60; 50], ...
    [0; 0], [0; 0], [0; 0], [0.01; 0.01], ...
    'VariableNames', {'BranchID','NumPoints','FrequencyStart_Hz','FrequencyEnd_Hz', ...
    'FrequencyStart_kHz','FrequencyEnd_kHz','FrequencyCoverage_kHz','CpStart_mps', ...
    'CpEnd_mps','YStart','YEnd','StartRank','EndRank','MinCp_mps','MaxCp_mps', ...
    'MedianCp_mps','MedianY','MedianRank','MedianObjective', ...
    'MedianSpacingToNearestLogY','NetCpIncrease_mps','NumCpDrops','MaxCpDrop_mps', ...
    'MaxRelativeCpDrop','Roughness'});
options = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(struct());
[selected, id, scored] = lamb.models.acoustoelastic_iop_hgo.policies.aeSelectAtlasA0Branch(T, options);
assert(id == 1 && selected.BranchID == 1);
assert(isequal(scored.A0StartFilterPassed, [true; false]));
assert(isfinite(scored.SelectionScore(1)) && isinf(scored.SelectionScore(2)));
assert(all(~scored.SelectionFallbackUsed));
% A late-born branch must not inherit A0 identity from low y/rank alone.
T.YStart(2) = T.YStart(1);
T.StartRank(2) = T.StartRank(1);
T.FrequencyStart_Hz(2) = 10000;
[~, id, scored] = lamb.models.acoustoelastic_iop_hgo.policies.aeSelectAtlasA0Branch(T, options, 300);
assert(id == 1 && ~scored.A0StartFilterPassed(2));
T.FrequencyStart_Hz(1) = 500;
[selected, ~, scored] = lamb.models.acoustoelastic_iop_hgo.policies.aeSelectAtlasA0Branch(T, options, 300);
assert(~any(scored.A0StartFilterPassed) && selected.SelectionFallbackUsed);
end

function assertFallbackContract()
result = struct();
result.options = struct('invalidateAtlasFallbackOutput', true);
result.quality = struct('selectionFallbackUsed', true);
result.phaseVelocity_mps = [100; nan];
result.validMask = [true; false];
result.wavenumber_radpm = [1; nan];
result.branchExistsAtFrequency = [true; false];
result.interpolatedCp = [false; false];
result.objective = [0.1; nan];
result.nearestRank = [1; nan];
result.nearestBranchID = [2; nan];
result.pointStatus = ["explicitBranchPoint"; "missingSelectedBranch"];
[decided, applied] = lamb.models.acoustoelastic_iop_hgo.policies.aeApplyAtlasA0FallbackPolicy(result);
assert(applied == true);
assert(isequaln(decided.fallbackCandidateCp, result.phaseVelocity_mps));
assert(isequal(decided.fallbackCandidateValidCp, result.validMask));
assert(all(isnan(decided.phaseVelocity_mps)) && all(~decided.validMask));
assert(all(decided.pointStatus == "fallbackRejectedA0StartFilter"));
assert(isequaln(decided.quality, result.quality), ...
    'Fallback policy must not rebuild quality.');
result.options.invalidateAtlasFallbackOutput = false;
[unchanged, applied] = lamb.models.acoustoelastic_iop_hgo.policies.aeApplyAtlasA0FallbackPolicy(result);
assert(applied == false && isequaln(unchanged, result));
end
