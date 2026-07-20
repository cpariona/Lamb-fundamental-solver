% TEMPORARY_DIAGNOSTIC
clear; clc; close all;
launchFolder = pwd;
startup

%VALIDATE_AE_SELECTED_BRANCH_REFINEMENT Compare old and bounded refinement.
%
% Outputs are written to:
%   Results/ae_iop_hgo/selected_branch_refinement

outputFolder = aeOutputFolder(launchFolder, 'selected_branch_refinement');
plotFolder = fullfile(outputFolder, 'plots');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

frequency = linspace(1e3, 15e3, 141);
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

caseNames = ["parabolic_only", "selected_branch_bounded"];
enableBoundedRefinement = [false, true];
results = struct();
summaryRows = struct([]);

for i = 1:numel(caseNames)
    options = defaultAcoustoelasticIOPHGOOptions();
    options.M54_variant = "corrected";
    options.normalizeRows = false;
    options.usePhysicalCpWindow = false;
    options.atlasBranchPolicy = "atlasA0";
    options.useInternalAtlasTrackingGrid = true;
    options.atlasInitializationMinFrequency_Hz = 200;
    options.atlasInitializationNumFrequencyPoints = 30;
    options.invalidateAtlasFallbackOutput = false;
    options.atlasNumYPoints = 300;
    options.atlasTopNMinima = 12;
    options.refineLocalMinima = true;
    options.refineSelectedAtlasBranch = enableBoundedRefinement(i);

    fprintf('Running %s\n', caseNames(i));
    solveTimer = tic;
    result = solveAcoustoelasticIOPHGOBranch(params, options);
    elapsedTime_s = toc(solveTimer);

    diagnostic = buildDiagnosticTable(result);
    fieldName = matlab.lang.makeValidName(caseNames(i));
    results.(fieldName).result = result;
    results.(fieldName).diagnostic = diagnostic;
    results.(fieldName).elapsedTime_s = elapsedTime_s;
    writetable(diagnostic, fullfile(outputFolder, caseNames(i) + "_diagnostic.csv"));

    summaryRows(i) = summarizeCase(caseNames(i), diagnostic, elapsedTime_s); %#ok<SAGROW>
end

summaryTable = struct2table(summaryRows);
comparisonTable = compareCases(results.parabolic_only.diagnostic, ...
    results.selected_branch_bounded.diagnostic);
writetable(summaryTable, fullfile(outputFolder, 'selected_branch_refinement_summary.csv'));
writetable(comparisonTable, fullfile(outputFolder, 'selected_branch_refinement_comparison.csv'));

fig = figure('Visible', 'off');
tiledlayout(3, 1, 'TileSpacing', 'compact');
nexttile;
plot(comparisonTable.Frequency_kHz, comparisonTable.ParabolicCp_mps, '.-', ...
    comparisonTable.Frequency_kHz, comparisonTable.BoundedCp_mps, '.-');
grid on; ylabel('Cp [m/s]'); legend('parabolic only', 'bounded selected branch', 'Location', 'best');
nexttile;
plot(comparisonTable.Frequency_kHz, comparisonTable.BoundedMinusParabolicCp_mps, '.-');
grid on; ylabel('\DeltaCp [m/s]');
nexttile;
plot(comparisonTable.Frequency_kHz, comparisonTable.ParabolicRelativeDelta2Cp, '.-', ...
    comparisonTable.Frequency_kHz, comparisonTable.BoundedRelativeDelta2Cp, '.-');
grid on; xlabel('Frequency [kHz]'); ylabel('\Delta^2Cp/Cp');
legend('parabolic only', 'bounded selected branch', 'Location', 'best');
saveas(fig, fullfile(plotFolder, 'selected_branch_refinement_comparison.png'));
close(fig);

save(fullfile(outputFolder, 'selected_branch_refinement_workspace.mat'), ...
    'params', 'results', 'summaryTable', 'comparisonTable', 'launchFolder', '-v7.3');

disp(summaryTable);
fprintf('\nValidation files written to:\n%s\n', outputFolder);

assignin('base', 'AESelectedBranchRefinementSummary', summaryTable);
assignin('base', 'AESelectedBranchRefinementComparison', comparisonTable);
assignin('base', 'AESelectedBranchRefinementResults', results);

function T = buildDiagnosticTable(result)
frequency = result.frequency(:);
Cp = result.Cp(:);
valid = result.validCp(:) & isfinite(Cp);
relativeDelta2Cp = nan(size(Cp));
tripleValid = valid(3:end) & valid(2:end-1) & valid(1:end-2);
delta2 = Cp(3:end) - 2 .* Cp(2:end-1) + Cp(1:end-2);
delta2(~tripleValid) = NaN;
relativeDelta2Cp(3:end) = delta2 ./ max(abs(Cp(2:end-1)), eps);
T = table(frequency, frequency ./ 1e3, Cp, valid, result.objective(:), ...
    result.nearestRank(:), result.nearestBranchID(:), relativeDelta2Cp, ...
    'VariableNames', {'Frequency_Hz', 'Frequency_kHz', 'Cp_mps', 'ValidCp', ...
    'Objective', 'NearestRank', 'NearestBranchID', 'RelativeDelta2Cp'});
end

function row = summarizeCase(caseName, T, elapsedTime_s)
highMask = T.ValidCp & T.Frequency_Hz >= 8e3 & isfinite(T.RelativeDelta2Cp);
curvature = abs(T.RelativeDelta2Cp(highMask));
row = struct( ...
    'CaseName', caseName, ...
    'ElapsedTime_s', elapsedTime_s, ...
    'ValidPoints', nnz(T.ValidCp), ...
    'HighFrequencyMaxAbsRelativeDelta2Cp', max(curvature, [], 'omitnan'), ...
    'HighFrequencyMedianAbsRelativeDelta2Cp', median(curvature, 'omitnan'), ...
    'HighFrequencyMedianObjective', median(T.Objective(highMask), 'omitnan'));
end

function T = compareCases(parabolic, bounded)
bothValid = parabolic.ValidCp & bounded.ValidCp;
deltaCp = bounded.Cp_mps - parabolic.Cp_mps;
deltaCp(~bothValid) = NaN;
T = table(parabolic.Frequency_Hz, parabolic.Frequency_kHz, ...
    parabolic.Cp_mps, bounded.Cp_mps, deltaCp, ...
    parabolic.RelativeDelta2Cp, bounded.RelativeDelta2Cp, ...
    parabolic.NearestRank, bounded.NearestRank, ...
    parabolic.NearestBranchID, bounded.NearestBranchID, ...
    'VariableNames', {'Frequency_Hz', 'Frequency_kHz', 'ParabolicCp_mps', ...
    'BoundedCp_mps', 'BoundedMinusParabolicCp_mps', ...
    'ParabolicRelativeDelta2Cp', 'BoundedRelativeDelta2Cp', ...
    'ParabolicNearestRank', 'BoundedNearestRank', ...
    'ParabolicNearestBranchID', 'BoundedNearestBranchID'});
end
