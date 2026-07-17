function test_ae_tracking_policy_ownership()
%TEST_AE_TRACKING_POLICY_OWNERSHIP Verify Phase-4 model-layer ownership.

repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
modelRoot = fullfile(repoRoot, 'models', 'acoustoelastic_iop_hgo');
owners = {
    'solvers', 'aeBuildAtlas';
    'tracking', 'aeFindAtlasLocalMinima';
    'tracking', 'aeLinkAtlasBranches';
    'tracking', 'aeSplitAtlasBranches';
    'policies', 'aeSelectAtlasA0Branch';
    'policies', 'aeApplyAtlasA0FallbackPolicy'};
for i = 1:size(owners, 1)
    expected = fullfile(modelRoot, owners{i,1}, owners{i,2} + ".m");
    assert(isfile(expected), 'Missing Phase-4 owner: %s', expected);
    assert(samePath(which(owners{i,2}), expected), ...
        '%s must resolve to its canonical model owner.', owners{i,2});
end

solverText = fileread(fullfile(modelRoot, 'solvers', 'solveAcoustoelasticAtlasBranch.m'));
assertContains(solverText, 'aeBuildAtlas(params, options)');
assertContains(solverText, 'aeFindAtlasLocalMinima(');
assertContains(solverText, 'aeLinkAtlasBranches(');
assertContains(solverText, 'aeSelectAtlasA0Branch(');
for oldLocal = ["function minima = localMinima", "function [minimaTable, branchTable] = linkBranches", ...
        "function minimaTable = splitBranchesOnLargeCpJump", "function [branch, id, branchTable] = selectBranch"]
    assert(~contains(solverText, oldLocal), 'Old local production owner remains: %s', oldLocal);
end

wrapperText = fileread(fullfile(modelRoot, 'solvers', 'solveAcoustoelasticIOPHGOAtlasBranch.m'));
assertContains(wrapperText, 'aeApplyAtlasA0FallbackPolicy(result)');
assert(~contains(wrapperText, 'result.fallbackCandidateCp = result.Cp'), ...
    'Fallback decision logic must not remain in the wrapper.');

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
minima = aeFindAtlasLocalMinima(cGrid, objective, 10, 4, options);
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
[linked, branches] = aeLinkAtlasBranches(T, options);
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
split = aeSplitAtlasBranches(T, 0.10, 3);
assert(isequal(split.BranchID, [2; 2; 2; 3; 3; 3]));
discarded = aeSplitAtlasBranches(T, 0.10, 4);
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
options = aeResolveConfiguration(struct());
[selected, id, scored] = aeSelectAtlasA0Branch(T, options);
assert(id == 1 && selected.BranchID == 1);
assert(isequal(scored.A0StartFilterPassed, [true; false]));
assert(isfinite(scored.SelectionScore(1)) && isinf(scored.SelectionScore(2)));
assert(all(~scored.SelectionFallbackUsed));
end

function assertFallbackContract()
result = struct();
result.options = struct('invalidateAtlasFallbackOutput', true);
result.reliability = struct('SelectionFallbackUsed', true);
result.Cp = [100, nan];
result.validCp = [true, false];
result.branchExistsAtFrequency = [true, false];
result.interpolatedCp = [false, false];
result.objective = [0.1, nan];
result.nearestRank = [1, nan];
result.nearestBranchID = [2, nan];
result.pointStatus = ["explicitBranchPoint", "missingSelectedBranch"];
[decided, applied] = aeApplyAtlasA0FallbackPolicy(result);
assert(applied == true);
assert(isequaln(decided.fallbackCandidateCp, result.Cp));
assert(isequal(decided.fallbackCandidateValidCp, result.validCp));
assert(all(isnan(decided.Cp)) && all(~decided.validCp));
assert(all(decided.pointStatus == "fallbackRejectedA0StartFilter"));
assert(isequaln(decided.reliability, result.reliability), ...
    'Fallback policy must not rebuild quality.');
result.options.invalidateAtlasFallbackOutput = false;
[unchanged, applied] = aeApplyAtlasA0FallbackPolicy(result);
assert(applied == false && isequaln(unchanged, result));
end

function assertContains(text, fragment)
assert(contains(text, fragment), 'Missing expected production call: %s', fragment);
end

function tf = samePath(actual, expected)
tf = strcmpi(strrep(string(actual), '/', '\'), strrep(string(expected), '/', '\'));
end
