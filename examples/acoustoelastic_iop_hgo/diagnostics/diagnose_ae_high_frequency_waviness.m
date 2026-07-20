% TEMPORARY_DIAGNOSTIC
clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_AE_HIGH_FREQUENCY_WAVINESS Explore residual waviness in AE Cp(f).
%
% This temporary diagnostic compares:
%   1. the maintained baseline;
%   2. the same atlas grid without three-point parabolic refinement;
%   3. a denser atlas velocity grid.
%
% It records Cp curvature, rank/branch changes, objective values, and total
% solver runtime. Outputs are written to:
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
    'Name', {"baseline", "discrete_minima", "dense_velocity_grid"}, ...
    'AtlasNumYPoints', {300, 300, 600}, ...
    'AtlasTopNMinima', {12, 12, 12}, ...
    'RefineLocalMinima', {true, false, true});

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
    options.refineLocalMinima = spec.RefineLocalMinima;

    fprintf('Running %s (%d velocity-grid points, refinement %s)\n', ...
        spec.Name, spec.AtlasNumYPoints, onOff(spec.RefineLocalMinima));
    solveTimer = tic;
    result = solveAcoustoelasticIOPHGOBranch(params, options);
    elapsedTime_s = toc(solveTimer);
    diagnostic = buildDiagnosticTable(result);

    fieldName = matlab.lang.makeValidName(spec.Name);
    results.(fieldName).spec = spec;
    results.(fieldName).elapsedTime_s = elapsedTime_s;
    results.(fieldName).result = result;
    results.(fieldName).diagnostic = diagnostic;

    writetable(diagnostic, fullfile(outputFolder, spec.Name + "_diagnostic.csv"));
    plotDiagnostics(diagnostic, spec, plotFolder);

    row = summarizeDiagnostic(diagnostic, spec, elapsedTime_s);
    if isempty(summaryRows)
        summaryRows = row;
    else
        summaryRows(end + 1) = row; %#ok<SAGROW>
    end
end

summaryTable = struct2table(summaryRows);
writetable(summaryTable, fullfile(outputFolder, 'high_frequency_waviness_summary.csv'));

comparisonTables = struct();
comparisonTables.baseline_vs_discrete_minima = compareCases( ...
    results.baseline.diagnostic, results.discrete_minima.diagnostic, ...
    "Baseline", "Discrete");
comparisonTables.baseline_vs_dense_velocity_grid = compareCases( ...
    results.baseline.diagnostic, results.dense_velocity_grid.diagnostic, ...
    "Baseline", "Dense");

writetable(comparisonTables.baseline_vs_discrete_minima, fullfile(outputFolder, ...
    'baseline_vs_discrete_minima.csv'));
writetable(comparisonTables.baseline_vs_dense_velocity_grid, fullfile(outputFolder, ...
    'baseline_vs_dense_velocity_grid.csv'));

plotComparison(comparisonTables.baseline_vs_discrete_minima, ...
    "baseline", "discrete minima", 'baseline_vs_discrete_minima.png', plotFolder);
plotComparison(comparisonTables.baseline_vs_dense_velocity_grid, ...
    "baseline", "dense velocity grid", 'baseline_vs_dense_velocity_grid.png', plotFolder);

save(fullfile(outputFolder, 'high_frequency_waviness_workspace.mat'), ...
    'params', 'caseSpecs', 'results', 'summaryTable', 'comparisonTables', ...
    'launchFolder', '-v7.3');

disp(summaryTable);
fprintf('\nDiagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AEHighFrequencyWavinessSummary', summaryTable);
assignin('base', 'AEHighFrequencyWavinessComparisons', comparisonTables);
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
relativeFirstDifference(2:end) = firstDifference(2:end) ./ max(abs(Cp(1:end-1)), eps);

tripleValid = validCp(3:end) & validCp(2:end-1) & validCp(1:end-2);
secondDifference(3:end) = Cp(3:end) - 2 .* Cp(2:end-1) + Cp(1:end-2);
secondDifference(3:end) = setInvalidToNaN(secondDifference(3:end), tripleValid);
relativeSecondDifference(3:end) = secondDifference(3:end) ./ max(abs(Cp(2:end-1)), eps);

rankChanged = false(size(Cp));
branchChanged = false(size(Cp));
rankChanged(2:end) = adjacentValid & isfinite(nearestRank(2:end)) & ...
    isfinite(nearestRank(1:end-1)) & nearestRank(2:end) ~= nearestRank(1:end-1);
branchChanged(2:end) = adjacentValid & isfinite(nearestBranchID(2:end)) & ...
    isfinite(nearestBranchID(1:end-1)) & nearestBranchID(2:end) ~= nearestBranchID(1:end-1);

T = table(frequency, frequency ./ 1e3, Cp, validCp, pointStatus, objective, ...
    nearestRank, nearestBranchID, rankChanged, branchChanged, ...
    firstDifference, secondDifference, relativeFirstDifference, ...
    relativeSecondDifference, ...
    'VariableNames', {'Frequency_Hz', 'Frequency_kHz', 'Cp_mps', 'ValidCp', ...
    'PointStatus', 'Objective', 'NearestRank', 'NearestBranchID', ...
    'RankChanged', 'BranchChanged', 'DeltaCp_mps', 'Delta2Cp_mps', ...
    'RelativeDeltaCp', 'RelativeDelta2Cp'});
end

function values = setInvalidToNaN(values, validMask)
values(~validMask) = NaN;
end

function row = summarizeDiagnostic(T, spec, elapsedTime_s)
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
    'RefineLocalMinima', spec.RefineLocalMinima, ...
    'ElapsedTime_s', elapsedTime_s, ...
    'TotalPoints', height(T), ...
    'ValidPoints', nnz(valid), ...
    'ValidFraction', nnz(valid) / max(height(T), 1), ...
    'HighFrequencyValidPoints', nnz(highFrequency), ...
    'HighFrequencyRankChanges', nnz(highFrequency & T.RankChanged), ...
    'HighFrequencyBranchChanges', nnz(highFrequency & T.BranchChanged), ...
    'HighFrequencyMaxAbsRelativeDelta2Cp', maxCurvature, ...
    'HighFrequencyMedianAbsRelativeDelta2Cp', medianCurvature);
end

function comparison = compareCases(first, second, firstLabel, secondLabel)
assert(isequal(first.Frequency_Hz, second.Frequency_Hz), ...
    'Diagnostic cases must use the same requested frequency grid.');

bothValid = first.ValidCp & second.ValidCp;
deltaCp = second.Cp_mps - first.Cp_mps;
relativeDeltaCp = deltaCp ./ max(abs(first.Cp_mps), eps);
deltaCp(~bothValid) = NaN;
relativeDeltaCp(~bothValid) = NaN;

comparison = table(first.Frequency_Hz, first.Frequency_kHz, ...
    first.Cp_mps, second.Cp_mps, bothValid, deltaCp, relativeDeltaCp, ...
    first.RelativeDelta2Cp, second.RelativeDelta2Cp, ...
    first.RankChanged, second.RankChanged, ...
    'VariableNames', {'Frequency_Hz', 'Frequency_kHz', ...
    char(firstLabel + "Cp_mps"), char(secondLabel + "Cp_mps"), ...
    'BothValid', 'SecondMinusFirstCp_mps', 'RelativeSecondMinusFirstCp', ...
    char(firstLabel + "RelativeDelta2Cp"), char(secondLabel + "RelativeDelta2Cp"), ...
    char(firstLabel + "RankChanged"), char(secondLabel + "RankChanged")});
end

function plotDiagnostics(T, spec, plotFolder)
fig = figure('Visible', 'off');
tiledlayout(4, 1, 'TileSpacing', 'compact');
nexttile; plot(T.Frequency_kHz, T.Cp_mps, '.-'); grid on;
ylabel('Cp [m/s]'); title(strrep(spec.Name + " AE waviness diagnostic", '_', '\_'));
nexttile; plot(T.Frequency_kHz, T.RelativeDelta2Cp, '.-'); grid on;
ylabel('\Delta^2Cp / Cp');
nexttile; yyaxis left; plot(T.Frequency_kHz, T.NearestRank, '.-'); ylabel('nearest rank');
yyaxis right; plot(T.Frequency_kHz, T.NearestBranchID, '.-'); ylabel('branch ID'); grid on;
nexttile; semilogy(T.Frequency_kHz, max(abs(T.Objective), realmin), '.-'); grid on;
xlabel('Frequency [kHz]'); ylabel('|objective|');
saveas(fig, fullfile(plotFolder, spec.Name + "_diagnostic.png")); close(fig);
end

function plotComparison(T, firstLabel, secondLabel, fileName, plotFolder)
firstCp = T{:, 3};
secondCp = T{:, 4};
firstCurvature = T{:, 8};
secondCurvature = T{:, 9};
fig = figure('Visible', 'off');
tiledlayout(3, 1, 'TileSpacing', 'compact');
nexttile; plot(T.Frequency_kHz, firstCp, '.-', T.Frequency_kHz, secondCp, '.-');
grid on; ylabel('Cp [m/s]'); legend(firstLabel, secondLabel, 'Location', 'best');
nexttile; plot(T.Frequency_kHz, T.SecondMinusFirstCp_mps, '.-'); grid on; ylabel('\DeltaCp [m/s]');
nexttile; plot(T.Frequency_kHz, firstCurvature, '.-', T.Frequency_kHz, secondCurvature, '.-');
grid on; xlabel('Frequency [kHz]'); ylabel('\Delta^2Cp / Cp');
legend(firstLabel, secondLabel, 'Location', 'best');
saveas(fig, fullfile(plotFolder, fileName)); close(fig);
end

function value = onOff(flag)
if flag
    value = 'on';
else
    value = 'off';
end
end
