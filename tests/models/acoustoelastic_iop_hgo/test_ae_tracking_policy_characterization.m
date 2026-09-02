function test_ae_tracking_policy_characterization()
%TEST_AE_TRACKING_POLICY_CHARACTERIZATION Freeze the production decision path.
%
% Atlas candidates must remain discrete grid points. Continuous minimization is
% owned only by the selected-branch stage.

params = representativeParams(logspace(log10(300), log10(12e3), 16));
profiles = ["Fast", "Balanced", "Robust"];
expectedYPoints = [300, 600, 900];
expectedTopN = [12, 16, 20];

for i = 1:numel(profiles)
    options = representativeOptions(profiles(i));
    options.useInternalAtlasTrackingGrid = false;
    options.refineLocalMinima = false;
    result = solveAcoustoelasticIOPHGOBranch(params, options);

    assert(size(result.objectiveMap, 1) == expectedYPoints(i));
    assert(size(result.objectiveMap, 2) == numel(params.frequency));
    assert(numel(result.yGrid) == expectedYPoints(i));
    assert(numel(result.cGrid) == expectedYPoints(i));
    assert(result.options.atlasTopNMinima == expectedTopN(i));
    assertIntermediateSchema(result);
    assertDiscreteMinima(result);
    assertTrackingConsistency(result);
    assertSelectedBranchConsistency(result);
end

overrideOptions = representativeOptions("Fast");
overrideOptions.atlasNumYPoints = 137;
overrideOptions.atlasTopNMinima = 7;
overrideOptions.atlasMaxLogYJump = 0.031;
overrideOptions.atlasMaxRelativeCpJump = 0.021;
overrideOptions.useInternalAtlasTrackingGrid = false;
overrideResult = solveAcoustoelasticIOPHGOBranch(params, overrideOptions);
assert(size(overrideResult.objectiveMap, 1) == 137);
assert(overrideResult.options.atlasTopNMinima == 7);
assert(overrideResult.options.atlasMaxLogYJump == 0.031);
assert(overrideResult.options.atlasMaxRelativeCpJump == 0.021);
assertIntermediateSchema(overrideResult);
assertDiscreteMinima(overrideResult);
assertTrackingConsistency(overrideResult);
assertSelectedBranchConsistency(overrideResult);

fallbackParams = representativeParams(logspace(log10(1000), log10(15e3), 35));
fallbackOptions = representativeOptions("Fast");
fallbackOptions.atlasNumYPoints = 300;
fallbackOptions.atlasTopNMinima = 12;
fallbackOptions.useInternalAtlasTrackingGrid = false;
fallbackOptions.invalidateAtlasFallbackOutput = true;
fallbackResult = solveAcoustoelasticIOPHGOBranch(fallbackParams, fallbackOptions);
assertDiscreteMinima(fallbackResult);
assert(fallbackResult.reliability.SelectionFallbackUsed == true);
assert(fallbackResult.reliability.A0StartFilterPassed == false);
assert(any(isfinite(fallbackResult.fallbackCandidateCp)));
assert(all(isnan(fallbackResult.Cp)));
assert(all(~fallbackResult.validCp));
assert(all(fallbackResult.pointStatus == "fallbackRejectedA0StartFilter"));

fprintf('AE tracking and policy characterization passed.\n');
end

function assertIntermediateSchema(result)
minimaNames = {'Frequency_Hz', 'Frequency_kHz', 'MinRank', 'Cp_mps', ...
    'y', 'log10y', 'Objective', 'DepthRelativeToMedian', ...
    'DepthRelativeToDeepest', 'SpacingToNearestLogY', 'BranchID'};
branchNames = {'BranchID', 'NumPoints', 'FrequencyStart_Hz', ...
    'FrequencyEnd_Hz', 'FrequencyStart_kHz', 'FrequencyEnd_kHz', ...
    'FrequencyCoverage_kHz', 'CpStart_mps', 'CpEnd_mps', 'YStart', ...
    'YEnd', 'StartRank', 'EndRank', 'MinCp_mps', 'MaxCp_mps', ...
    'MedianCp_mps', 'MedianY', 'MedianRank', 'MedianObjective', ...
    'MedianSpacingToNearestLogY', 'NetCpIncrease_mps', 'NumCpDrops', ...
    'MaxCpDrop_mps', 'MaxRelativeCpDrop', 'Roughness', ...
    'A0StartFilterPassed', 'SelectionScore', 'SelectionFallbackUsed'};

assert(isequal(result.minimaTable.Properties.VariableNames, minimaNames));
if ~isempty(result.branchTable)
    assert(isequal(result.branchTable.Properties.VariableNames, branchNames));
end
assert(size(result.objectiveMap, 2) == numel(result.frequency));
assert(isequal(size(result.Cp), size(result.frequency)));
assert(isequal(size(result.validCp), size(result.frequency)));
end

function assertDiscreteMinima(result)
if isempty(result.minimaTable)
    return;
end
[isGridPoint, gridIndex] = ismember(result.minimaTable.Cp_mps, result.cGrid);
assert(all(isGridPoint), 'Atlas candidate minima must remain on cGrid.');
for row = 1:height(result.minimaTable)
    column = find(result.frequency == result.minimaTable.Frequency_Hz(row), 1);
    assert(~isempty(column));
    assert(result.objectiveMap(gridIndex(row), column) == result.minimaTable.Objective(row));
end
frequencies = unique(result.minimaTable.Frequency_Hz, 'stable');
for i = 1:numel(frequencies)
    rows = result.minimaTable.Frequency_Hz == frequencies(i);
    assert(isequal(result.minimaTable.MinRank(rows), (1:nnz(rows)).'));
end
end

function assertTrackingConsistency(result)
if isempty(result.branchTable)
    assert(isnan(result.selectedBranchID));
    assert(isempty(result.selectedBranch));
    assert(isempty(result.selectedBranchPoints));
    return;
end

assert(height(result.selectedBranch) == 1);
assert(result.selectedBranch.BranchID == result.selectedBranchID);
assert(all(result.selectedBranchPoints.BranchID == result.selectedBranchID));
assert(isequal(result.selectedBranchPoints.Frequency_Hz, ...
    sort(result.selectedBranchPoints.Frequency_Hz)));
selectedRow = result.branchTable.BranchID == result.selectedBranchID;
assert(nnz(selectedRow) == 1);
assert(result.branchTable.SelectionScore(selectedRow) == ...
    min(result.branchTable.SelectionScore));
assert(all(isfinite(result.minimaTable.BranchID) | isnan(result.minimaTable.BranchID)));
assert(all(result.validCp == (isfinite(result.Cp) & ...
    (result.branchExistsAtFrequency | result.interpolatedCp))));
end

function assertSelectedBranchConsistency(result)
if isempty(result.selectedBranchPoints)
    return;
end
for row = 1:height(result.selectedBranchPoints)
    outputIndex = find(result.frequency == result.selectedBranchPoints.Frequency_Hz(row), 1);
    if isempty(outputIndex)
        continue;
    end

    % selectedBranchPoints remains diagnostic even when fallback policy
    % invalidates the official output. Compare only explicit valid outputs.
    if ~result.validCp(outputIndex) || ~result.branchExistsAtFrequency(outputIndex)
        continue;
    end

    assertNearlyEqual(result.Cp(outputIndex), result.selectedBranchPoints.Cp_mps(row));
    assertNearlyEqual(result.objective(outputIndex), result.selectedBranchPoints.Objective(row));
    assert(result.nearestRank(outputIndex) == result.selectedBranchPoints.MinRank(row));
    assert(result.nearestBranchID(outputIndex) == result.selectedBranchPoints.BranchID(row));
end
end

function assertNearlyEqual(actual, expected)
scale = max([1, abs(actual), abs(expected)]);
assert(abs(actual - expected) <= 32 * eps(scale));
end

function params = representativeParams(frequency)
params = struct('R', 7.8e-3, 'thickness', 550e-6, 'mu', 50e3, ...
    'k1', 25e3, 'k2', 100, 'rho', 1060, 'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9, 'frequency', frequency, 'IOP', 15 * 133.322);
end

function options = representativeOptions(profile)
options = aeResolveConfiguration(struct(), 'NumericalPreset', profile);
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasBranchPolicy = "atlasA0";
options.invalidateAtlasFallbackOutput = false;
end
