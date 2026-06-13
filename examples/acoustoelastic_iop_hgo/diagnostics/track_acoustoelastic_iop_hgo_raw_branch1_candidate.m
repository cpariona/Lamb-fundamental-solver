clear; clc; close all;
startup

% Li 2024 corrected-raw-matrix branch-candidate postprocessor.
%
% Run this after:
%   examples/diagnostics/diagnose_li2024_low_frequency_modal_atlas.m
%
% It reads the low-frequency atlas CSV tables, selects the smooth persistent
% branch from corrected_raw_matrix for each IOP, and compares that atlas-defined
% branch against the current global-scan trackers.

inputFolder = fullfile(pwd, 'Results', 'Li2024_low_frequency_modal_atlas');
outputFolder = fullfile(pwd, 'Results', 'Li2024_raw_branch_candidate');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

minimaFile = fullfile(inputFolder, 'Li2024_low_frequency_modal_atlas_minima_table.csv');
branchFile = fullfile(inputFolder, 'Li2024_low_frequency_modal_atlas_branch_table.csv');

if ~exist(minimaFile, 'file') || ~exist(branchFile, 'file')
    error(['Low-frequency atlas CSV files were not found. Run ', ...
        'examples/diagnostics/diagnose_li2024_low_frequency_modal_atlas.m first.']);
end

minimaTable = readtable(minimaFile);
branchTable = readtable(branchFile);

rawBranchTable = branchTable(branchTable.Condition == "corrected_raw_matrix", :);
rawMinimaTable = minimaTable(minimaTable.Condition == "corrected_raw_matrix", :);

IOP_mmHg = unique(rawBranchTable.IOP_mmHg, 'stable');
trackerGridPoints = [900, 1800, 3600];

baseParams = defaultExampleParams();
rawOptions = defaultLi2024AcoustoelasticOptions();
rawOptions.M54_variant = "corrected";
rawOptions.normalizeRows = false;
rawOptions.branch = "A0";
rawOptions.trackingDirection = "backward";
rawOptions.trackingMethod = "globalScan";
rawOptions.minDimensionlessFrequency = 0.0;
rawOptions.usePhysicalCpWindow = false;

normalizedOptions = rawOptions;
normalizedOptions.normalizeRows = true;

candidateSummary = table();
candidateCurve = table();
trackerComparison = table();

for i = 1:numel(IOP_mmHg)
    iop = IOP_mmHg(i);
    candidate = selectCandidateBranch(rawBranchTable(rawBranchTable.IOP_mmHg == iop, :));
    branchID = candidate.BranchID;
    points = rawMinimaTable(rawMinimaTable.IOP_mmHg == iop & rawMinimaTable.BranchID == branchID, :);
    points = sortrows(points, 'Frequency_Hz');

    candidateSummary = [candidateSummary; candidate]; %#ok<AGROW>
    candidateCurve = [candidateCurve; points]; %#ok<AGROW>

    fprintf('IOP %.1f mmHg: selected corrected_raw_matrix BranchID %g, %d points, Cp %.3f -> %.3f m/s\n', ...
        iop, branchID, height(points), points.Cp_mps(1), points.Cp_mps(end));

    params = baseParams;
    params.IOP = iop * 133.322;
    params.frequency = points.Frequency_Hz(:).';

    trackerComparison = [trackerComparison; compareTrackers(params, points, rawOptions, normalizedOptions, trackerGridPoints, iop)]; %#ok<AGROW>
    plotCandidateVsTrackers(params, points, rawOptions, normalizedOptions, trackerGridPoints, iop);
end

comparisonSummary = summarizeTrackerComparison(trackerComparison);
plotCandidateAcrossIOP(candidateCurve);
plotTrackerComparisonSummary(comparisonSummary);

writetable(candidateSummary, fullfile(outputFolder, 'Li2024_raw_branch_candidate_summary_table.csv'));
writetable(candidateCurve, fullfile(outputFolder, 'Li2024_raw_branch_candidate_curve_table.csv'));
writetable(trackerComparison, fullfile(outputFolder, 'Li2024_raw_branch_tracker_comparison_table.csv'));
writetable(comparisonSummary, fullfile(outputFolder, 'Li2024_raw_branch_tracker_comparison_summary_table.csv'));

save(fullfile(outputFolder, 'Li2024_raw_branch_candidate_workspace.mat'), ...
    'candidateSummary', 'candidateCurve', 'trackerComparison', 'comparisonSummary', ...
    'rawOptions', 'normalizedOptions', 'trackerGridPoints', '-v7.3');

fprintf('\nCandidate summary\n');
disp(candidateSummary);

fprintf('\nTracker comparison summary\n');
disp(comparisonSummary);

fprintf('\nData files written to:\n%s\n', outputFolder);

assignin('base', 'Li2024RawBranchCandidateSummary', candidateSummary);
assignin('base', 'Li2024RawBranchCandidateCurve', candidateCurve);
assignin('base', 'Li2024RawBranchTrackerComparison', trackerComparison);
assignin('base', 'Li2024RawBranchTrackerComparisonSummary', comparisonSummary);

function params = defaultExampleParams()
params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = [];
end

function candidate = selectCandidateBranch(T)
if isempty(T)
    error('No corrected_raw_matrix branches found for this IOP.');
end
coverage = normalizeMetric(T.FrequencyCoverage_kHz);
roughness = normalizeMetric(T.Roughness);
rank = normalizeMetric(T.MedianRank);
y = normalizeMetric(T.MedianY);
increase = normalizeMetric(T.NetCpIncrease_mps);
score = -1.4*coverage + 1.2*roughness + 0.7*rank + 0.35*y - 0.5*increase;
[~, idx] = min(score);
candidate = T(idx, :);
candidate.SelectionScore = score(idx);
end

function x = normalizeMetric(x)
x = x(:);
mask = isfinite(x);
if ~any(mask)
    x(:) = 0;
    return;
end
xmin = min(x(mask));
xmax = max(x(mask));
if abs(xmax - xmin) < eps
    x(mask) = 0;
else
    x(mask) = (x(mask) - xmin) ./ (xmax - xmin);
end
x(~mask) = 1;
end

function comparison = compareTrackers(params, branchPoints, rawOptions, normalizedOptions, gridList, iop)
rows = [];
methodLabels = ["corrected_raw_globalScan", "corrected_row_normalized_globalScan"];
for m = 1:numel(methodLabels)
    for g = 1:numel(gridList)
        if methodLabels(m) == "corrected_raw_globalScan"
            opt = rawOptions;
        else
            opt = normalizedOptions;
        end
        opt.numCpScanPoints = gridList(g);
        result = solveDispersionIOPHGO_Li2024(params, opt);
        candidateCp = interp1(branchPoints.Frequency_Hz, branchPoints.Cp_mps, result.frequency, 'linear', nan);
        for k = 1:numel(result.frequency)
            row = struct();
            row.IOP_mmHg = iop;
            row.TrackerMethod = methodLabels(m);
            row.GridPoints = gridList(g);
            row.Frequency_Hz = result.frequency(k);
            row.Frequency_kHz = result.frequency(k)/1e3;
            row.TrackerCp_mps = result.Cp(k);
            row.CandidateCp_mps = candidateCp(k);
            row.AbsError_mps = abs(result.Cp(k) - candidateCp(k));
            row.RelativeError = row.AbsError_mps / max(abs(candidateCp(k)), eps);
            row.ValidTracker = result.validCp(k);
            rows = [rows; row]; %#ok<AGROW>
        end
    end
end
comparison = struct2table(rows);
end

function S = summarizeTrackerComparison(T)
[G, method, grid, iop] = findgroups(T.TrackerMethod, T.GridPoints, T.IOP_mmHg);
S = table();
S.TrackerMethod = method;
S.GridPoints = grid;
S.IOP_mmHg = iop;
S.MedianAbsError_mps = splitapply(@(x) median(x, 'omitnan'), T.AbsError_mps, G);
S.MedianRelativeError = splitapply(@(x) median(x, 'omitnan'), T.RelativeError, G);
S.MaxRelativeError = splitapply(@(x) max(x, [], 'omitnan'), T.RelativeError, G);
S.ValidFraction = splitapply(@(x) mean(double(x), 'omitnan'), T.ValidTracker, G);
end

function plotCandidateVsTrackers(params, branchPoints, rawOptions, normalizedOptions, gridList, iop)
figure('Color', 'w', 'Name', sprintf('Li2024 raw branch candidate IOP %.0f', iop));
hold on; grid on;
plot(branchPoints.Frequency_kHz, branchPoints.Cp_mps, 'k-', 'LineWidth', 3, 'DisplayName', 'atlas candidate');
for g = 1:numel(gridList)
    opt = rawOptions;
    opt.numCpScanPoints = gridList(g);
    r = solveDispersionIOPHGO_Li2024(params, opt);
    plot(r.frequency/1e3, r.Cp, '--', 'LineWidth', 1.2, 'DisplayName', sprintf('raw tracker %d', gridList(g)));
    opt = normalizedOptions;
    opt.numCpScanPoints = gridList(g);
    r = solveDispersionIOPHGO_Li2024(params, opt);
    plot(r.frequency/1e3, r.Cp, ':', 'LineWidth', 1.2, 'DisplayName', sprintf('normalized tracker %d', gridList(g)));
end
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title(sprintf('Li 2024 corrected raw atlas branch candidate, IOP %.0f mmHg', iop));
legend('Location', 'best');
hold off;
end

function plotCandidateAcrossIOP(T)
figure('Color', 'w', 'Name', 'Li2024 raw branch candidate across IOP');
hold on; grid on;
iops = unique(T.IOP_mmHg, 'stable');
for i = 1:numel(iops)
    Ti = T(T.IOP_mmHg == iops(i), :);
    plot(Ti.Frequency_kHz, Ti.Cp_mps, 'LineWidth', 2, 'DisplayName', sprintf('IOP %.0f mmHg', iops(i)));
end
xlabel('frequency [kHz]');
ylabel('Candidate branch Cp [m/s]');
title('Li 2024 corrected raw atlas branch candidate across IOP');
legend('Location', 'best');
hold off;
end

function plotTrackerComparisonSummary(S)
figure('Color', 'w', 'Name', 'Li2024 raw branch tracker error summary');
labels = strcat(S.TrackerMethod, " | grid ", string(S.GridPoints), " | IOP ", string(S.IOP_mmHg));
bar(categorical(labels), S.MedianRelativeError);
grid on;
ylabel('median relative error vs atlas branch');
title('Tracker mismatch relative to corrected raw atlas branch candidate');
xtickangle(35);
end
