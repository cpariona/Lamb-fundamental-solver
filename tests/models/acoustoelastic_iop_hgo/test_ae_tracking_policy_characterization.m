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
assert(fallbackResult.quality.selectionFallbackUsed == true);
assert(fallbackResult.quality.a0StartFilterPassed == false);
assert(any(isfinite(fallbackResult.fallbackCandidateCp)));
assert(all(isnan(fallbackResult.phaseVelocity_mps)));
assert(all(~fallbackResult.validMask));
assert(all(fallbackResult.pointStatus == "fallbackRejectedA0StartFilter"));

assertContinuousRefinement();
fprintf('AE tracking and policy characterization passed.\n');
end

function assertContinuousRefinement()
% Independent guards for the historical atlasA0 snapshot fixture. No golden
% values enter these objective, identity, or convergence assertions.
params = representativeParams(logspace(log10(300), log10(15e3), 35));
options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasNumYPoints = 300;
options.atlasTopNMinima = 12;
options.atlasBranchPolicy = "atlasA0";
refined = solveAcoustoelasticIOPHGOBranch(params, options);
options.refineLocalMinima = false;
discrete = solveAcoustoelasticIOPHGOBranch(params, options);
assert(all(refined.validMask) && ~refined.quality.selectionFallbackUsed);
assert(isequal(refined.validMask, discrete.validMask));
assert(isequaln(refined.minimaTable, discrete.minimaTable));
assert(isequaln(refined.nearestRank, discrete.nearestRank));
assert(isequaln(refined.nearestBranchID, discrete.nearestBranchID));
assert(all(ismember(refined.minimaTable.Cp_mps, refined.cGrid)), ...
    'Refinement must leave atlas candidates on the discrete grid.');
[a,b,g] = computeAcoustoelasticABGFromIOPHGO(params.IOP, params.R, ...
    params.thickness, params.mu, params.k1, params.k2);
for j = 1:numel(params.frequency)
    objective = objectiveAcoustoelasticResidual(a,b,g,params.thickness, ...
        params.rho,params.rhoF,params.fluidBulkModulus,params.frequency(j), ...
        refined.phaseVelocity_mps(j),options);
    assertNearlyEqual(objective, refined.objective(j));
    assert(objective < discrete.objective(j), ...
        'Continuous refinement must improve the true SVD objective.');
end
options.refineLocalMinima = true;
options.selectedBranchRefinementTolLogCp = 1e-10;
options.selectedBranchRefinementMaxFunEvals = 100;
options.selectedBranchRefinementMaxIter = 100;
tight = solveAcoustoelasticIOPHGOBranch(params, options);
assert(isequal(refined.validMask, tight.validMask));
delta = max(abs(refined.phaseVelocity_mps(:) - tight.phaseVelocity_mps(:)));
% Measured 1.441e-6 m/s; 3e-6 is a convergence bound, not a relaxed golden.
assert(delta < 3e-6, 'Selected-branch refinement failed convergence guard.');
fprintf('AE true-SVD/identity/convergence guards passed: max delta %.9g m/s.\n', delta);
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
assert(size(result.objectiveMap, 2) == numel(result.frequency_Hz));
assert(isequal(size(result.phaseVelocity_mps), size(result.frequency_Hz)));
assert(isequal(size(result.validMask), size(result.frequency_Hz)));
end

function assertDiscreteMinima(result)
if isempty(result.minimaTable)
    return;
end
[isGridPoint, gridIndex] = ismember(result.minimaTable.Cp_mps, result.cGrid);
assert(all(isGridPoint), 'Atlas candidate minima must remain on cGrid.');
for row = 1:height(result.minimaTable)
    column = find(result.frequency_Hz == result.minimaTable.Frequency_Hz(row), 1);
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
expectedValid = isfinite(result.phaseVelocity_mps(:)) & ...
    (result.branchExistsAtFrequency(:) | result.interpolatedCp(:));
assert(isequal(result.validMask(:), expectedValid));
end

function assertSelectedBranchConsistency(result)
if isempty(result.selectedBranchPoints)
    return;
end
for row = 1:height(result.selectedBranchPoints)
    outputIndex = find(result.frequency_Hz == result.selectedBranchPoints.Frequency_Hz(row), 1);
    if isempty(outputIndex)
        continue;
    end

    % selectedBranchPoints remains diagnostic even when fallback policy
    % invalidates the official output. Compare only explicit valid outputs.
    if ~result.validMask(outputIndex) || ~result.branchExistsAtFrequency(outputIndex)
        continue;
    end

    assertNearlyEqual(result.phaseVelocity_mps(outputIndex), result.selectedBranchPoints.Cp_mps(row));
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
