clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% The maintained quality summary consumes canonical public model results.
params = rlDefaultParams();
frequency_Hz = linspace(500, 4000, 10).';
elastic = solveCase(params, frequency_Hz, 0);
viscous = solveCase(params, frequency_Hz, 0.05);

summaryTable = summarizeMRLFETrackingQuality( ...
    {elastic, viscous}, ["etaS0", "etaS005"], ...
    'BranchName', "A0Like", 'Print', false);

assert(istable(summaryTable) && height(summaryTable) == 2, ...
    'mRLFE quality summary must return one row per public result.');
requiredVariables = {'Strategy','Branch','RequestedPoints','TrackingPoints', ...
    'ValidPoints','TotalPoints','ValidFraction','MaxRelJump','Roughness','QualityScore'};
for i = 1:numel(requiredVariables)
    assert(ismember(requiredVariables{i}, summaryTable.Properties.VariableNames), ...
        'mRLFE quality summary is missing required variable %s.', requiredVariables{i});
end
assert(all(summaryTable.ValidFraction >= 0 & summaryTable.ValidFraction <= 1), ...
    'ValidFraction values must be bounded in [0, 1].');
assert(all(isfinite(summaryTable.QualityScore)), 'QualityScore values must be finite.');

fprintf('test_mrlfe_tracking_quality_summary passed. Public results are summarized.\n');

function result = solveCase(params, frequency_Hz, etaS)
options = mrlfeDefaultSweepOptions("A0Like", 'EtaS', etaS);
request = mrlfeBuildSolveRequest(params, frequency_Hz, "A0Like", options);
result = mrlfeSolve(request);
end
