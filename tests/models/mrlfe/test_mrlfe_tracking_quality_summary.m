clear; clc;
startup

%TEST_MRLFE_TRACKING_QUALITY_SUMMARY Contract test for mRLFE quality summary helper.
%
% The helper is a maintained analysis utility used to compare tracking
% strategies without creating temporary diagnostics.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";

elasticOptions = rlDefaultOptions("Fast");
elasticOptions.computeA0 = true;
elasticOptions.computeS0 = false;
elasticOptions.computeMRLFE = false;
elasticOptions.computeMRLFERealK = true;
elasticOptions.computeMRLFEComplexK = false;
elasticOptions.mrlfeComputeA0Like = true;
elasticOptions.mrlfeComputeS0Like = false;
elasticOptions.mrlfeParams = defaultMRLFEParams();
elasticOptions.mrlfeParams.etaS = 0;
elasticOptions.mrlfeParams.etaL = 0;
elasticOptions.mrlfeParams.useComplexLambda = false;
elasticOptions.mrlfeParams.solveComplexK = false;

viscousOptions = elasticOptions;
viscousOptions.mrlfeParams.etaS = 0.05;

elasticResults = rlComputeFundamentalLambModes(params, elasticOptions);
viscousResults = rlComputeFundamentalLambModes(params, viscousOptions);

summaryTable = summarizeMRLFETrackingQuality( ...
    {elasticResults.models.mRLFERealK, viscousResults.models.mRLFERealK}, ...
    ["etaS0", "etaS005"], ...
    'BranchName', "A0Like", ...
    'Print', false);

assert(istable(summaryTable), 'mRLFE quality summary must return a table.');
assert(height(summaryTable) == 2, 'mRLFE quality summary must return one row per input result.');
requiredVariables = {'Strategy','Branch','UsedInternalGrid','RequestedPoints','TrackingPoints', ...
    'ValidPoints','TotalPoints','ValidFraction','MaxRelJump','Roughness','MedianResidual','QualityScore'};
for i = 1:numel(requiredVariables)
    assert(ismember(requiredVariables{i}, summaryTable.Properties.VariableNames), ...
        'mRLFE quality summary is missing required variable %s.', requiredVariables{i});
end

rowEtaS0 = find(summaryTable.Strategy == "etaS0", 1);
rowEtaS005 = find(summaryTable.Strategy == "etaS005", 1);
assert(~isempty(rowEtaS0) && ~isempty(rowEtaS005), 'Expected etaS0 and etaS005 rows.');
assert(~summaryTable.UsedInternalGrid(rowEtaS0), 'etaS = 0 public result should not report legacy internal-grid metadata.');
assert(~summaryTable.UsedInternalGrid(rowEtaS005), 'etaS > 0 public result should not report legacy internal-grid metadata.');
assert(summaryTable.TrackingPoints(rowEtaS005) == summaryTable.RequestedPoints(rowEtaS005), ...
    'etaS > 0 public result should report requested-grid branch metrics.');
assert(all(summaryTable.ValidFraction >= 0 & summaryTable.ValidFraction <= 1), ...
    'ValidFraction values must be bounded in [0, 1].');
assert(all(isfinite(summaryTable.QualityScore)), 'QualityScore values must be finite.');

fprintf('test_mrlfe_tracking_quality_summary passed. Quality helper summarizes public tracking metrics.\n');
