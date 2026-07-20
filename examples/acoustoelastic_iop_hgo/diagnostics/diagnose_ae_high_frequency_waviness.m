% TEMPORARY_DIAGNOSTIC
clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_AE_HIGH_FREQUENCY_WAVINESS Explore residual waviness in AE Cp(f).
%
% This temporary diagnostic compares the maintained atlasA0 solution at two
% atlas velocity-grid resolutions and records whether local Cp curvature is
% associated with changes in nearest minimum rank, branch identity, or
% objective value.
%
% Outputs are written to:
%   Results/ae_iop_hgo/high_frequency_waviness
%
% The script does not modify solver output and does not apply smoothing.

outputFolder = aeOutputFolder(launchFolder, 'high_frequency_waviness');
plotFolder = fullfile(outputFolder, 'plots');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

frequency = linspace(1e3, 15e3, 141);
params = representativeParams(frequency);

caseSpecs = struct( ...
    'Name', {"baseline", "dense_velocity_grid"}, ...
    'AtlasNumYPoints', {300, 600}, ...
    'AtlasTopNMinima', {12, 12});

results = struct();
summaryRows = struct([]);

fprintf('\nAcoustoelastic IOP/HGO high-frequency waviness diagnostic\n');
fprintf('Launch folder:\n%s\n', launchFolder);
fprintf('Output folder:\n%s\n\n', outputFolder);

for i = 1:numel(caseSpecs)
    spec = caseSpecs(i);
    options = representativeOptions();
    options.atlasNumYPoints = spec.AtlasNumYPoints;
    options.atlasTopNMinima = spec.AtlasTopNMinima;

    fprintf('Running %s (%d velocity-grid points)\n', ...
        spec.Name, spec.AtlasNumYPoints);
    result = solveAcoustoelasticIOPHGOBranch(params, options);
    diagnostic = buildDiagnosticTable(result);

    fieldName = matlab.lang.makeValidName(spec.Name);
    results.(fieldName).spec = spec;
    results.(fieldName).result = result;
    results.(fieldName).diagnostic = diagnostic;

    writetable(diagnostic, fullfile(outputFolder, spec.Name + "_diagnostic.csv"));
    plotDiagnostics(diagnostic, spec, plotFolder);

    row = summarizeDiagnostic(diagnostic, spec);
    if isempty(summaryRows)
        summaryRows = row;
    else
        summaryRows(end + 1) = row; %#ok<SAGROW>
    end
end

summaryTable = struct2table(summaryRows);
writetable(summaryTable, fullfile(outputFolder, 'high_frequency_waviness_summary.csv'));

comparisonTable = compareCases(results.baseline.diagnostic, ...
    results.dense_velocity_grid.diagnostic);
writetable(comparisonTable, fullfile(outputFolder, ...
    'baseline_vs_dense_velocity_grid.csv'));
plotComparison(comparisonTable, plotFolder);

save(fullfile(outputFolder, 'high_frequency_waviness_workspace.mat'), ...
    'params', 'caseSpecs', 'results', 'summaryTable', 'comparisonTable', ...
    'launchFolder', '-v7.3');

disp(summaryTable);
fprintf('\nDiagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AEHighFrequencyWavinessSummary', summaryTable);
assignin('base', 'AEHighFrequencyWavinessComparison', comparisonTable);
assignin('base', 'AEHighFrequencyWavinessResults', results);
assignin('base', 'AEHighFrequencyWavinessOutputFolder', outputFolder);

function params = representativeParams(frequency)
params = struct( ...
    'R', 7.8e-3, ...
    'thickness', 550e-6, ...
    'mu', 50e3, ...
    'k1', 25e3, ...
    'k2', 100, ...
    'rho', 1060, ...
    'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9, ...
    'frequency', frequency, ...
    'IOP', 15 * 133.322);
end

function options = representativeOptions()
options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasBranchPolicy = "atlasA0";
options.useInternalAtlasTrackingGrid = true;
options.atlasInitializationMinFrequency_Hz = 200;
options.atlasInitializationNumFrequencyPoints = 30;
options.invalidateAtlasFallbackOutput = false;
end

function T = buildDiagnosticTable(result)
frequency = result.frequency(:);
Cp = result.Cp(:);
validCp = result.validCp(:) & isfinite(Cp);
objective = result.objective(:);
nearestRank = result.nearestRank(:);
nearestBranchID = result.nearestBranchID(:);
pointStatus = result.pointStatus(:);

firstDifference = nan(size(Cp));
secondDifference = nan(size(Cp));
relativeFirstDifference = nan(size(Cp));
relativeSecondDifference = nan(size(Cp));

adjacentValid = validCp(2:end) & validCp(1:end-1);
firstDifference(2:end) = Cp(2:end) - Cp(1:end-1);
firstDifference(2:end) = setInvalidToNaN(firstDifference(2:end), adjacentValid);

referenceCp = max(abs(Cp(1:end-1)), eps);
relativeFirstDifference(2:end) = firstDifference(2:end) ./ referenceCp;

tripleValid = validCp(3:end) & validCp(2:end-1) & validCp(1:end-2);
secondDifference(3:end) = Cp(3:end) - 2 .* Cp(2:end-1) + Cp(1:end-2);
secondDifference(3:end) = setInvalidToNaN(secondDifference(3:end), tripleValid);

localReferenceCp = max(abs(Cp(2:end-1)), eps);
relativeSecondDifference(3:end) = secondDifference(3:end) ./ localReferenceCp;

rankChanged = false(size(Cp));
branchChanged = false(size(Cp));
rankChanged(2:end) = adjacentValid & isfinite(nearestRank(2:end)) & ...
    isfinite(nearestRank(1:end-1)) & nearestRank(2:end) ~= nearestRank(1:end-1);
branchChanged(2:end) = adjacentValid & isfinite(nearestBranchID(2:end)) & ...
    isfinite(nearestBranchID(1:end-1)) & ...
    nearestBranchID(2:end) ~= nearestBranchID(1:end-1);

objectiveRatio = nan(size(objective));
objectiveValid = isfinite(objective(2:end)) & isfinite(objective(1:end-1));
objectiveRatio(2:end) = objective(2:end) ./ max(abs(objective(1:end-1)), eps);
objectiveRatio(2:end) = setInvalidToNaN(objectiveRatio(2:end), objectiveValid);

T = table(frequency, frequency ./ 1e3, Cp, validCp, pointStatus, objective, ...
    objectiveRatio, nearestRank, nearestBranchID, rankChanged, branchChanged, ...
    firstDifference, secondDifference, relativeFirstDifference, ...
    relativeSecondDifference, ...
    'VariableNames', {'Frequency_Hz', 'Frequency_kHz', 'Cp_mps', 'ValidCp', ...
    'PointStatus', 'Objective', 'ObjectiveRatioToPrevious', 'NearestRank', ...
    'NearestBranchID', 'RankChanged', 'BranchChanged', 'DeltaCp_mps', ...
    'Delta2Cp_mps', 'RelativeDeltaCp', 'RelativeDelta2Cp'});
end

function values = setInvalidToNaN(values, validMask)
values(~validMask) = NaN;
end

function row = summarizeDiagnostic(T, spec)
valid = T.ValidCp;
highFrequency = valid & T.Frequency_Hz >= 8e3;
curvature = abs(T.RelativeDelta2Cp);
finiteHighCurvature = highFrequency & isfinite(curvature);

if any(finiteHighCurvature)
    maxCurvature = max(curvature(finiteHighCurvature));
    medianCurvature = median(curvature(finiteHighCurvature));
else
    maxCurvature = NaN;
    medianCurvature = NaN;
end

row = struct( ...
    'CaseName', spec.Name, ...
    'AtlasNumYPoints', spec.AtlasNumYPoints, ...
    'AtlasTopNMinima', spec.AtlasTopNMinima, ...
    'TotalPoints', height(T), ...
    'ValidPoints', nnz(valid), ...
    'ValidFraction', nnz(valid) / max(height(T), 1), ...
    'HighFrequencyValidPoints', nnz(highFrequency), ...
    'HighFrequencyRankChanges', nnz(highFrequency & T.RankChanged), ...
    'HighFrequencyBranchChanges', nnz(highFrequency & T.BranchChanged), ...
    'HighFrequencyMaxAbsRelativeDelta2Cp', maxCurvature, ...
    'HighFrequencyMedianAbsRelativeDelta2Cp', medianCurvature);
end

function comparison = compareCases(baseline, dense)
assert(isequal(baseline.Frequency_Hz, dense.Frequency_Hz), ...
    'Diagnostic cases must use the same requested frequency grid.');

bothValid = baseline.ValidCp & dense.ValidCp;
deltaCp = dense.Cp_mps - baseline.Cp_mps;
relativeDeltaCp = deltaCp ./ max(abs(baseline.Cp_mps), eps);
deltaCp(~bothValid) = NaN;
relativeDeltaCp(~bothValid) = NaN;

comparison = table( ...
    baseline.Frequency_Hz, baseline.Frequency_kHz, ...
    baseline.Cp_mps, dense.Cp_mps, bothValid, deltaCp, relativeDeltaCp, ...
    baseline.RelativeDelta2Cp, dense.RelativeDelta2Cp, ...
    baseline.RankChanged, dense.RankChanged, ...
    baseline.BranchChanged, dense.BranchChanged, ...
    'VariableNames', {'Frequency_Hz', 'Frequency_kHz', 'BaselineCp_mps', ...
    'DenseCp_mps', 'BothValid', 'DenseMinusBaselineCp_mps', ...
    'RelativeDenseMinusBaselineCp', 'BaselineRelativeDelta2Cp', ...
    'DenseRelativeDelta2Cp', 'BaselineRankChanged', 'DenseRankChanged', ...
    'BaselineBranchChanged', 'DenseBranchChanged'});
end

function plotDiagnostics(T, spec, plotFolder)
fig = figure('Visible', 'off');
tiledlayout(4, 1, 'TileSpacing', 'compact');

nexttile;
plot(T.Frequency_kHz, T.Cp_mps, '.-'); grid on;
ylabel('Cp [m/s]');
title(strrep(spec.Name + " AE waviness diagnostic", '_', '\_'));

nexttile;
plot(T.Frequency_kHz, T.RelativeDelta2Cp, '.-'); grid on;
ylabel('\Delta^2Cp / Cp');

nexttile;
yyaxis left
plot(T.Frequency_kHz, T.NearestRank, '.-');
ylabel('nearest rank');
yyaxis right
plot(T.Frequency_kHz, T.NearestBranchID, '.-');
ylabel('branch ID');
grid on;

nexttile;
semilogy(T.Frequency_kHz, max(abs(T.Objective), realmin), '.-'); grid on;
xlabel('Frequency [kHz]'); ylabel('|objective|');

saveas(fig, fullfile(plotFolder, spec.Name + "_diagnostic.png"));
close(fig);
end

function plotComparison(T, plotFolder)
fig = figure('Visible', 'off');
tiledlayout(3, 1, 'TileSpacing', 'compact');

nexttile;
plot(T.Frequency_kHz, T.BaselineCp_mps, '.-', ...
    T.Frequency_kHz, T.DenseCp_mps, '.-');
grid on; ylabel('Cp [m/s]');
legend('baseline', 'dense velocity grid', 'Location', 'best');
title('AE velocity-grid sensitivity');

nexttile;
plot(T.Frequency_kHz, T.DenseMinusBaselineCp_mps, '.-');
grid on; ylabel('\DeltaCp [m/s]');

nexttile;
plot(T.Frequency_kHz, T.BaselineRelativeDelta2Cp, '.-', ...
    T.Frequency_kHz, T.DenseRelativeDelta2Cp, '.-');
grid on; xlabel('Frequency [kHz]'); ylabel('\Delta^2Cp / Cp');
legend('baseline', 'dense velocity grid', 'Location', 'best');

saveas(fig, fullfile(plotFolder, 'baseline_vs_dense_velocity_grid.png'));
close(fig);
end
