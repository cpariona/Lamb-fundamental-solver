% TEMPORARY_DIAGNOSTIC
clear; clc; close all;
launchFolder = pwd;
startup

%VALIDATE_AE_SELECTED_BRANCH_REFINEMENT Compare quality and repeated runtime.
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

caseNames = ["parabolic_only"; "selected_branch_bounded"];
enableBoundedRefinement = [false; true];
numCases = numel(caseNames);
numMeasuredRepeats = 6;
results = struct();

fprintf('\nWarming up both refinement paths...\n');
for i = 1:numCases
    solveAcoustoelasticIOPHGOBranch(params, makeOptions(enableBoundedRefinement(i)));
end

sampleCount = numCases * numMeasuredRepeats;
runIndex = nan(sampleCount, 1);
repeatIndex = nan(sampleCount, 1);
orderWithinRepeat = nan(sampleCount, 1);
benchmarkCaseName = strings(sampleCount, 1);
elapsedTime_s = nan(sampleCount, 1);
row = 0;

fprintf('\nRunning %d alternating measured repeats per case...\n', numMeasuredRepeats);
for repeat = 1:numMeasuredRepeats
    if mod(repeat, 2) == 1
        executionOrder = [1, 2];
    else
        executionOrder = [2, 1];
    end

    for position = 1:numCases
        caseIndex = executionOrder(position);
        options = makeOptions(enableBoundedRefinement(caseIndex));
        fprintf('Repeat %d/%d, position %d: %s\n', ...
            repeat, numMeasuredRepeats, position, caseNames(caseIndex));

        timerValue = tic;
        result = solveAcoustoelasticIOPHGOBranch(params, options);
        measuredTime = toc(timerValue);

        row = row + 1;
        runIndex(row) = row;
        repeatIndex(row) = repeat;
        orderWithinRepeat(row) = position;
        benchmarkCaseName(row) = caseNames(caseIndex);
        elapsedTime_s(row) = measuredTime;

        fieldName = matlab.lang.makeValidName(caseNames(caseIndex));
        results.(fieldName).result = result;
        results.(fieldName).diagnostic = buildDiagnosticTable(result);
    end
end

benchmarkSamples = table(runIndex, repeatIndex, orderWithinRepeat, ...
    benchmarkCaseName, elapsedTime_s, ...
    'VariableNames', {'RunIndex', 'RepeatIndex', 'OrderWithinRepeat', ...
    'CaseName', 'ElapsedTime_s'});
writetable(benchmarkSamples, fullfile(outputFolder, ...
    'selected_branch_refinement_runtime_samples.csv'));

summaryCaseName = caseNames;
summaryMedianElapsedTime_s = nan(numCases, 1);
summaryMeanElapsedTime_s = nan(numCases, 1);
summaryStdElapsedTime_s = nan(numCases, 1);
summaryMinElapsedTime_s = nan(numCases, 1);
summaryMaxElapsedTime_s = nan(numCases, 1);
summaryValidPoints = nan(numCases, 1);
summaryHighFrequencyMaxAbsRelativeDelta2Cp = nan(numCases, 1);
summaryHighFrequencyMedianAbsRelativeDelta2Cp = nan(numCases, 1);
summaryHighFrequencyMedianObjective = nan(numCases, 1);

for i = 1:numCases
    mask = benchmarkSamples.CaseName == caseNames(i);
    times = benchmarkSamples.ElapsedTime_s(mask);
    summaryMedianElapsedTime_s(i) = median(times);
    summaryMeanElapsedTime_s(i) = mean(times);
    summaryStdElapsedTime_s(i) = std(times);
    summaryMinElapsedTime_s(i) = min(times);
    summaryMaxElapsedTime_s(i) = max(times);

    fieldName = matlab.lang.makeValidName(caseNames(i));
    diagnostic = results.(fieldName).diagnostic;
    metrics = summarizeQuality(diagnostic);
    summaryValidPoints(i) = metrics.ValidPoints;
    summaryHighFrequencyMaxAbsRelativeDelta2Cp(i) = metrics.HighFrequencyMaxAbsRelativeDelta2Cp;
    summaryHighFrequencyMedianAbsRelativeDelta2Cp(i) = metrics.HighFrequencyMedianAbsRelativeDelta2Cp;
    summaryHighFrequencyMedianObjective(i) = metrics.HighFrequencyMedianObjective;
    writetable(diagnostic, fullfile(outputFolder, caseNames(i) + "_diagnostic.csv"));
end

summaryTable = table(summaryCaseName, summaryMedianElapsedTime_s, ...
    summaryMeanElapsedTime_s, summaryStdElapsedTime_s, ...
    summaryMinElapsedTime_s, summaryMaxElapsedTime_s, summaryValidPoints, ...
    summaryHighFrequencyMaxAbsRelativeDelta2Cp, ...
    summaryHighFrequencyMedianAbsRelativeDelta2Cp, ...
    summaryHighFrequencyMedianObjective, ...
    'VariableNames', {'CaseName', 'MedianElapsedTime_s', 'MeanElapsedTime_s', ...
    'StdElapsedTime_s', 'MinElapsedTime_s', 'MaxElapsedTime_s', ...
    'ValidPoints', 'HighFrequencyMaxAbsRelativeDelta2Cp', ...
    'HighFrequencyMedianAbsRelativeDelta2Cp', ...
    'HighFrequencyMedianObjective'});

parabolicMedian = summaryMedianElapsedTime_s(1);
boundedMedian = summaryMedianElapsedTime_s(2);
runtimeRatio = boundedMedian / parabolicMedian;
runtimeDifferencePercent = 100 * (runtimeRatio - 1);
runtimeComparison = table(parabolicMedian, boundedMedian, runtimeRatio, ...
    runtimeDifferencePercent, ...
    'VariableNames', {'ParabolicMedianTime_s', 'BoundedMedianTime_s', ...
    'BoundedToParabolicRatio', 'BoundedRuntimeDifference_percent'});

comparisonTable = compareCases(results.parabolic_only.diagnostic, ...
    results.selected_branch_bounded.diagnostic);
writetable(summaryTable, fullfile(outputFolder, ...
    'selected_branch_refinement_summary.csv'));
writetable(runtimeComparison, fullfile(outputFolder, ...
    'selected_branch_refinement_runtime_comparison.csv'));
writetable(comparisonTable, fullfile(outputFolder, ...
    'selected_branch_refinement_comparison.csv'));

fig = figure('Visible', 'off');
tiledlayout(3, 1, 'TileSpacing', 'compact');
nexttile;
plot(comparisonTable.Frequency_kHz, comparisonTable.ParabolicCp_mps, '.-', ...
    comparisonTable.Frequency_kHz, comparisonTable.BoundedCp_mps, '.-');
grid on; ylabel('Cp [m/s]');
legend('parabolic only', 'bounded selected branch', 'Location', 'best');
nexttile;
plot(comparisonTable.Frequency_kHz, ...
    comparisonTable.BoundedMinusParabolicCp_mps, '.-');
grid on; ylabel('\DeltaCp [m/s]');
nexttile;
plot(comparisonTable.Frequency_kHz, ...
    comparisonTable.ParabolicRelativeDelta2Cp, '.-', ...
    comparisonTable.Frequency_kHz, ...
    comparisonTable.BoundedRelativeDelta2Cp, '.-');
grid on; xlabel('Frequency [kHz]'); ylabel('\Delta^2Cp/Cp');
legend('parabolic only', 'bounded selected branch', 'Location', 'best');
saveas(fig, fullfile(plotFolder, ...
    'selected_branch_refinement_comparison.png'));
close(fig);

save(fullfile(outputFolder, 'selected_branch_refinement_workspace.mat'), ...
    'params', 'results', 'summaryTable', 'runtimeComparison', ...
    'benchmarkSamples', 'comparisonTable', 'launchFolder', '-v7.3');

disp(summaryTable);
disp(runtimeComparison);
fprintf('\nValidation files written to:\n%s\n', outputFolder);

assignin('base', 'AESelectedBranchRefinementSummary', summaryTable);
assignin('base', 'AESelectedBranchRefinementRuntimeComparison', runtimeComparison);
assignin('base', 'AESelectedBranchRefinementRuntimeSamples', benchmarkSamples);
assignin('base', 'AESelectedBranchRefinementComparison', comparisonTable);
assignin('base', 'AESelectedBranchRefinementResults', results);

function options = makeOptions(enableBoundedRefinement)
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
options.refineSelectedAtlasBranch = enableBoundedRefinement;
end

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

function metrics = summarizeQuality(T)
highMask = T.ValidCp & T.Frequency_Hz >= 8e3 & ...
    isfinite(T.RelativeDelta2Cp);
curvature = abs(T.RelativeDelta2Cp(highMask));
metrics = struct();
metrics.ValidPoints = nnz(T.ValidCp);
metrics.HighFrequencyMaxAbsRelativeDelta2Cp = max(curvature, [], 'omitnan');
metrics.HighFrequencyMedianAbsRelativeDelta2Cp = median(curvature, 'omitnan');
metrics.HighFrequencyMedianObjective = median(T.Objective(highMask), 'omitnan');
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
