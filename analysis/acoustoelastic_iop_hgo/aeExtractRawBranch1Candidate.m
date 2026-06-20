function rawBranch = aeExtractRawBranch1Candidate(launchFolder, varargin)
%AEEXTRACTRAWBRANCH1CANDIDATE Extract corrected raw-matrix branch-1 candidate.
%
% rawBranch = aeExtractRawBranch1Candidate(launchFolder) reads the
% low-frequency modal-atlas tables, selects a persistent raw_branch1
% candidate for each IOP condition, and writes the raw_branch1 outputs under
% Results/ae_iop_hgo/raw_branch1 relative to launchFolder.
%
% This is diagnostic infrastructure only. It does not modify result.Cp or
% result.validCp and does not promote raw_branch1 to production output.
%
% Name-value options:
%   'RunTrackerComparison'  logical, default true
%   'MakePlots'             logical, default true
%   'WriteOutputs'          logical, default true
%
% The lightweight mode used by compare_atlasA0_vs_raw_branch1 is:
%   aeExtractRawBranch1Candidate(launchFolder, ...
%       'RunTrackerComparison', false, 'MakePlots', false)

opts = parseOptions(varargin{:});

inputFolder = fullfile(launchFolder, 'Results', 'ae_iop_hgo', 'modal_atlas_lowfreq');
legacyInputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_low_frequency_modal_atlas');
if ~exist(inputFolder, 'dir') && exist(legacyInputFolder, 'dir')
    inputFolder = legacyInputFolder;
end

outputFolder = aeOutputFolder(launchFolder, 'raw_branch1');
if opts.WriteOutputs && ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

[minimaFile, branchFile] = resolveModalAtlasFiles(inputFolder);

minimaTable = readtable(minimaFile);
branchTable = readtable(branchFile);

rawBranchTable = branchTable(branchTable.Condition == "corrected_raw_matrix", :);
rawMinimaTable = minimaTable(minimaTable.Condition == "corrected_raw_matrix", :);

if isempty(rawBranchTable) || isempty(rawMinimaTable)
    error('No corrected_raw_matrix modal-atlas rows were found. Run diagnose_modal_atlas_lowfreq first.');
end

IOP_mmHg = unique(rawBranchTable.IOP_mmHg, 'stable');
trackerGridPoints = [900, 1800, 3600];

baseParams = defaultRawBranchParams();
rawOptions = defaultRawBranchOptions(false);
normalizedOptions = defaultRawBranchOptions(true);

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

    if opts.RunTrackerComparison || opts.MakePlots
        params = baseParams;
        params.IOP = iop * 133.322;
        params.frequency = points.Frequency_Hz(:).';
    end

    if opts.RunTrackerComparison
        trackerComparison = [trackerComparison; compareTrackers(params, points, rawOptions, normalizedOptions, trackerGridPoints, iop)]; %#ok<AGROW>
    end

    if opts.MakePlots
        plotCandidateVsTrackers(params, points, rawOptions, normalizedOptions, trackerGridPoints, iop, outputFolder);
    end
end

if opts.RunTrackerComparison && ~isempty(trackerComparison)
    comparisonSummary = summarizeTrackerComparison(trackerComparison);
else
    comparisonSummary = table();
end

if opts.MakePlots
    plotCandidateAcrossIOP(candidateCurve, outputFolder);
    if ~isempty(comparisonSummary)
        plotTrackerComparisonSummary(comparisonSummary, outputFolder);
    end
end

if opts.WriteOutputs
    writetable(candidateSummary, fullfile(outputFolder, 'raw_branch1_summary.csv'));
    writetable(candidateCurve, fullfile(outputFolder, 'raw_branch1_curve.csv'));
    if opts.RunTrackerComparison
        writetable(trackerComparison, fullfile(outputFolder, 'raw_branch1_tracker_comparison.csv'));
        writetable(comparisonSummary, fullfile(outputFolder, 'raw_branch1_tracker_summary.csv'));
    end

    save(fullfile(outputFolder, 'raw_branch1_workspace.mat'), ...
        'candidateSummary', 'candidateCurve', 'trackerComparison', 'comparisonSummary', ...
        'rawOptions', 'normalizedOptions', 'trackerGridPoints', 'launchFolder', 'inputFolder', ...
        'minimaFile', 'branchFile', '-v7.3');
end

rawBranch = struct();
rawBranch.candidateSummary = candidateSummary;
rawBranch.candidateCurve = candidateCurve;
rawBranch.trackerComparison = trackerComparison;
rawBranch.comparisonSummary = comparisonSummary;
rawBranch.rawOptions = rawOptions;
rawBranch.normalizedOptions = normalizedOptions;
rawBranch.trackerGridPoints = trackerGridPoints;
rawBranch.inputFolder = inputFolder;
rawBranch.outputFolder = outputFolder;
rawBranch.minimaFile = minimaFile;
rawBranch.branchFile = branchFile;
rawBranch.curveFile = fullfile(outputFolder, 'raw_branch1_curve.csv');
rawBranch.workspaceFile = fullfile(outputFolder, 'raw_branch1_workspace.mat');
end

function opts = parseOptions(varargin)
opts = struct();
opts.RunTrackerComparison = true;
opts.MakePlots = true;
opts.WriteOutputs = true;

if mod(numel(varargin), 2) ~= 0
    error('Options must be provided as name-value pairs.');
end

for k = 1:2:numel(varargin)
    name = varargin{k};
    value = varargin{k+1};
    if isstring(name)
        name = char(name);
    end
    if ~ischar(name)
        error('Option names must be character vectors or strings.');
    end
    switch lower(name)
        case 'runtrackercomparison'
            opts.RunTrackerComparison = logical(value);
        case 'makeplots'
            opts.MakePlots = logical(value);
        case 'writeoutputs'
            opts.WriteOutputs = logical(value);
        otherwise
            error('Unknown option: %s', name);
    end
end
end

function [minimaFile, branchFile] = resolveModalAtlasFiles(inputFolder)
minimaFile = fullfile(inputFolder, 'modal_atlas_lowfreq_minima.csv');
branchFile = fullfile(inputFolder, 'modal_atlas_lowfreq_branches.csv');
legacyMinimaFile = fullfile(inputFolder, 'acoustoelastic_iop_hgo_low_frequency_modal_atlas_minima_table.csv');
legacyBranchFile = fullfile(inputFolder, 'acoustoelastic_iop_hgo_low_frequency_modal_atlas_branch_table.csv');

if ~exist(minimaFile, 'file') && exist(legacyMinimaFile, 'file')
    minimaFile = legacyMinimaFile;
end
if ~exist(branchFile, 'file') && exist(legacyBranchFile, 'file')
    branchFile = legacyBranchFile;
end

if ~exist(minimaFile, 'file') || ~exist(branchFile, 'file')
    error('Low-frequency atlas CSV files were not found. Run diagnose_modal_atlas_lowfreq first.');
end
end

function params = defaultRawBranchParams()
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

function rawOptions = defaultRawBranchOptions(normalizeRows)
rawOptions = defaultAcoustoelasticIOPHGOOptions();
rawOptions.M54_variant = "corrected";
rawOptions.normalizeRows = normalizeRows;
rawOptions.branch = "A0";
rawOptions.trackingDirection = "backward";
rawOptions.trackingMethod = "globalScan";
rawOptions.minDimensionlessFrequency = 0.0;
rawOptions.usePhysicalCpWindow = false;
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
        result = solveAcoustoelasticIOPHGODispersion(params, opt);
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

function plotCandidateVsTrackers(params, branchPoints, rawOptions, normalizedOptions, gridList, iop, outputFolder)
figure('Color', 'w', 'Name', sprintf('AE raw branch candidate IOP %.0f', iop));
hold on; grid on;
plot(branchPoints.Frequency_kHz, branchPoints.Cp_mps, 'k-', 'LineWidth', 3, 'DisplayName', 'atlas candidate');
for g = 1:numel(gridList)
    opt = rawOptions;
    opt.numCpScanPoints = gridList(g);
    r = solveAcoustoelasticIOPHGODispersion(params, opt);
    plot(r.frequency/1e3, r.Cp, '--', 'LineWidth', 1.2, 'DisplayName', sprintf('raw tracker %d', gridList(g)));
    opt = normalizedOptions;
    opt.numCpScanPoints = gridList(g);
    r = solveAcoustoelasticIOPHGODispersion(params, opt);
    plot(r.frequency/1e3, r.Cp, ':', 'LineWidth', 1.2, 'DisplayName', sprintf('normalized tracker %d', gridList(g)));
end
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title(sprintf('Corrected raw atlas branch candidate, IOP %.0f mmHg', iop));
legend('Location', 'best');
hold off;
saveas(gcf, fullfile(outputFolder, sprintf('raw_branch1_iop_%g.png', iop)));
saveas(gcf, fullfile(outputFolder, sprintf('raw_branch1_iop_%g.fig', iop)));
end

function plotCandidateAcrossIOP(T, outputFolder)
figure('Color', 'w', 'Name', 'AE raw branch candidate across IOP');
hold on; grid on;
iops = unique(T.IOP_mmHg, 'stable');
for i = 1:numel(iops)
    Ti = T(T.IOP_mmHg == iops(i), :);
    plot(Ti.Frequency_kHz, Ti.Cp_mps, 'LineWidth', 2, 'DisplayName', sprintf('IOP %.0f mmHg', iops(i)));
end
xlabel('frequency [kHz]');
ylabel('Candidate branch Cp [m/s]');
title('Corrected raw atlas branch candidate across IOP');
legend('Location', 'best');
hold off;
saveas(gcf, fullfile(outputFolder, 'raw_branch1_across_iop.png'));
saveas(gcf, fullfile(outputFolder, 'raw_branch1_across_iop.fig'));
end

function plotTrackerComparisonSummary(S, outputFolder)
figure('Color', 'w', 'Name', 'AE raw branch tracker error summary');
labels = strcat(S.TrackerMethod, " | grid ", string(S.GridPoints), " | IOP ", string(S.IOP_mmHg));
bar(categorical(labels), S.MedianRelativeError);
grid on;
ylabel('median relative error vs atlas branch');
title('Tracker mismatch relative to corrected raw atlas branch candidate');
xtickangle(35);
saveas(gcf, fullfile(outputFolder, 'raw_branch1_tracker_summary.png'));
saveas(gcf, fullfile(outputFolder, 'raw_branch1_tracker_summary.fig'));
end
