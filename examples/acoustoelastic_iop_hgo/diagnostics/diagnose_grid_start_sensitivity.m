clear; clc; close all;
launchFolder = pwd;
addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

%DIAGNOSE_GRID_START_SENSITIVITY Diagnose AE atlasA0 sensitivity to output grid start/density.
%
% This diagnostic is intentionally not part of the automated validation tiers. It is a
% solver-interface diagnostic for the AE IOP/HGO branch-selection issue.
%
% Outputs are written to:
%   Results/ae_iop_hgo/grid_start_sensitivity

outputFolder = resolveModelOutputFolder(launchFolder, 'ae_iop_hgo', 'grid_start_sensitivity');

fprintf('\nAE IOP/HGO grid/start-frequency sensitivity diagnostic\n');
fprintf('Output folder:\n%s\n', outputFolder);

baseParams = makeBaseParams();
caseSpecs = makeCaseSpecs();

summaryRows = [];
curveTableAll = table();
branchTableAll = table();
resultByCase = struct();

for i = 1:numel(caseSpecs)
    spec = caseSpecs(i);
    params = baseParams;
    params.frequency = makeFrequencyVector(spec.fmin_Hz, spec.fmax_Hz, spec.nFreq);
    options = makeOptions(spec);

    fprintf('Running %s: fmin %.3g Hz, fmax %.3g Hz, N=%d, yN=%d, topN=%d\n', ...
        spec.label, spec.fmin_Hz, spec.fmax_Hz, spec.nFreq, options.atlasNumYPoints, options.atlasTopNMinima);

    result = solveAcoustoelasticIOPHGOBranch(params, options);
    key = matlab.lang.makeValidName(spec.label);
    resultByCase.(key) = result;

    summaryRows = [summaryRows; makeSummaryRow(spec, result)]; %#ok<AGROW>
    curveTableAll = [curveTableAll; makeCurveTable(spec, result)]; %#ok<AGROW>
    branchTableAll = [branchTableAll; makeBranchTable(spec, result)]; %#ok<AGROW>
end

if isempty(summaryRows)
    summaryTable = table();
else
    summaryTable = struct2table(summaryRows);
end

writetable(summaryTable, fullfile(outputFolder, 'grid_start_sensitivity_summary.csv'));
writetable(curveTableAll, fullfile(outputFolder, 'grid_start_sensitivity_curves.csv'));
if ~isempty(branchTableAll)
    writetable(branchTableAll, fullfile(outputFolder, 'grid_start_sensitivity_branches.csv'));
end
save(fullfile(outputFolder, 'grid_start_sensitivity_workspace.mat'), ...
    'baseParams', 'caseSpecs', 'summaryTable', 'curveTableAll', 'branchTableAll', 'resultByCase', '-v7.3');

plotCurves(curveTableAll, outputFolder);

disp(summaryTable);
fprintf('\nDiagnostic files written to:\n%s\n', outputFolder);
assignin('base', 'AEGridStartSensitivitySummary', summaryTable);
assignin('base', 'AEGridStartSensitivityCurves', curveTableAll);
assignin('base', 'AEGridStartSensitivityResults', resultByCase);

function params = makeBaseParams()
params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.IOP = 15 * 133.322;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
end

function specs = makeCaseSpecs()
specs = struct([]);

specs(1).label = "low_start_fast_output";
specs(1).fmin_Hz = 50;
specs(1).fmax_Hz = 15e3;
specs(1).nFreq = 35;
specs(1).atlasNumYPoints = 300;
specs(1).atlasTopNMinima = 12;

specs(2).label = "gui_like_balanced_output";
specs(2).fmin_Hz = 300;
specs(2).fmax_Hz = 15e3;
specs(2).nFreq = 50;
specs(2).atlasNumYPoints = 600;
specs(2).atlasTopNMinima = 16;

specs(3).label = "gui_like_robust_output";
specs(3).fmin_Hz = 300;
specs(3).fmax_Hz = 15e3;
specs(3).nFreq = 70;
specs(3).atlasNumYPoints = 900;
specs(3).atlasTopNMinima = 20;

specs(4).label = "same_start_dense_output";
specs(4).fmin_Hz = 300;
specs(4).fmax_Hz = 15e3;
specs(4).nFreq = 160;
specs(4).atlasNumYPoints = 900;
specs(4).atlasTopNMinima = 20;

specs(5).label = "high_start_dense_output";
specs(5).fmin_Hz = 1000;
specs(5).fmax_Hz = 15e3;
specs(5).nFreq = 160;
specs(5).atlasNumYPoints = 900;
specs(5).atlasTopNMinima = 20;
end

function frequency = makeFrequencyVector(fmin_Hz, fmax_Hz, nFreq)
frequency = logspace(log10(fmin_Hz), log10(fmax_Hz), nFreq);
end

function options = makeOptions(spec)
options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = spec.atlasNumYPoints;
options.atlasTopNMinima = spec.atlasTopNMinima;
end

function row = makeSummaryRow(spec, result)
valid = result.validMask & isfinite(result.phaseVelocity_mps);
cpValid = result.phaseVelocity_mps(valid);
row = struct();
row.CaseLabel = string(spec.label);
row.Fmin_Hz = spec.fmin_Hz;
row.Fmax_Hz = spec.fmax_Hz;
row.NFrequency = spec.nFreq;
row.AtlasNumYPoints = spec.atlasNumYPoints;
row.AtlasTopNMinima = spec.atlasTopNMinima;
row.SelectedBranchID = result.selectedBranchID;
row.ValidPoints = nnz(valid);
row.TotalPoints = numel(result.phaseVelocity_mps);
row.ValidFraction = nnz(valid) / max(numel(result.phaseVelocity_mps), 1);
row.FirstValidFrequency_Hz = result.quality.FirstValidFrequency_Hz;
row.LastValidFrequency_Hz = result.quality.LastValidFrequency_Hz;
row.FirstMissingFrequency_Hz = result.quality.FirstMissingFrequency_Hz;
row.SelectionFallbackUsed = result.quality.SelectionFallbackUsed;
row.A0StartFilterPassed = result.quality.A0StartFilterPassed;
row.YStart = result.quality.YStart;
row.StartRank = result.quality.StartRank;
if numel(cpValid) >= 2
    row.CpRange_mps = max(cpValid) - min(cpValid);
    row.RelativeCpRange = row.CpRange_mps / max(median(abs(cpValid), 'omitnan'), eps);
    row.NetCpChange_mps = cpValid(end) - cpValid(1);
else
    row.CpRange_mps = nan;
    row.RelativeCpRange = nan;
    row.NetCpChange_mps = nan;
end
row.PossibleConstantBranch = isfinite(row.RelativeCpRange) && row.RelativeCpRange < 0.01;
end

function T = makeCurveTable(spec, result)
n = numel(result.frequency_Hz);
T = table();
T.CaseLabel = repmat(string(spec.label), n, 1);
T.Frequency_Hz = result.frequency_Hz(:);
T.Frequency_kHz = result.frequency_Hz(:) / 1e3;
T.Cp_mps = result.phaseVelocity_mps(:);
T.ValidCp = result.validMask(:);
T.PointStatus = string(result.pointStatus(:));
T.NearestRank = result.nearestRank(:);
T.NearestBranchID = result.nearestBranchID(:);
T.Objective = result.objective(:);
end

function T = makeBranchTable(spec, result)
if isempty(result.branchTable)
    T = table();
    return;
end
T = result.branchTable;
T.CaseLabel = repmat(string(spec.label), height(T), 1);
T = movevars(T, 'CaseLabel', 'Before', 1);
end

function plotCurves(curveTable, outputFolder)
if isempty(curveTable)
    return;
end
figure('Color', 'w', 'Name', 'AE grid/start sensitivity');
hold on;
caseLabels = unique(curveTable.CaseLabel, 'stable');
for i = 1:numel(caseLabels)
    mask = curveTable.CaseLabel == caseLabels(i) & curveTable.ValidCp;
    plot(curveTable.Frequency_kHz(mask), curveTable.Cp_mps(mask), 'LineWidth', 1.5, 'DisplayName', char(caseLabels(i)));
end
hold off;
grid on;
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title('AE atlasA0 sensitivity to frequency start and output density');
legend('Location', 'best');
saveas(gcf, fullfile(outputFolder, 'grid_start_sensitivity_curves.fig'));
saveas(gcf, fullfile(outputFolder, 'grid_start_sensitivity_curves.png'));
end
