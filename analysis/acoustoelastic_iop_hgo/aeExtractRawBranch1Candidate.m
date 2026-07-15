function rawBranch = aeExtractRawBranch1Candidate(launchFolder, varargin)
%AEEXTRACTRAWBRANCH1CANDIDATE Extract corrected raw-matrix branch-1 candidate.
%
% rawBranch = aeExtractRawBranch1Candidate(launchFolder) reads the modal-atlas
% tables, selects a persistent raw_branch1 candidate for each IOP condition,
% and writes the raw_branch1 outputs under Results/ae_iop_hgo/raw_branch1
% relative to launchFolder.
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

inputFolder = fullfile(launchFolder, 'Results', 'ae_iop_hgo', 'modal_atlas');
legacyLowFrequencyFolder = fullfile(launchFolder, 'Results', 'ae_iop_hgo', 'modal_atlas_lowfreq');
legacyInputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_low_frequency_modal_atlas');
if ~exist(inputFolder, 'dir') && exist(legacyLowFrequencyFolder, 'dir')
    inputFolder = legacyLowFrequencyFolder;
elseif ~exist(inputFolder, 'dir') && exist(legacyInputFolder, 'dir')
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
    error('No corrected_raw_matrix modal-atlas rows were found. Run diagnose_acoustoelastic_iop_hgo_modal_atlas first.');
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
minimaFile = fullfile(inputFolder, 'modal_atlas_minima.csv');
branchFile = fullfile(inputFolder, 'modal_atlas_branches.csv');
legacyMinimaFile = fullfile(inputFolder, 'acoustoelastic_iop_hgo_modal_atlas_minima_table.csv');
legacyBranchFile = fullfile(inputFolder, 'acoustoelastic_iop_hgo_modal_atlas_branch_table.csv');
legacyLowMinimaFile = fullfile(inputFolder, 'acoustoelastic_iop_hgo_low_frequency_modal_atlas_minima_table.csv');
legacyLowBranchFile = fullfile(inputFolder, 'acoustoelastic_iop_hgo_low_frequency_modal_atlas_branch_table.csv');

if ~exist(minimaFile, 'file') && exist(legacyMinimaFile, 'file')
    minimaFile = legacyMinimaFile;
elseif ~exist(minimaFile, 'file') && exist(legacyLowMinimaFile, 'file')
    minimaFile = legacyLowMinimaFile;
end
if ~exist(branchFile, 'file') && exist(legacyBranchFile, 'file')
    branchFile = legacyBranchFile;
elseif ~exist(branchFile, 'file') && exist(legacyLowBranchFile, 'file')
    branchFile = legacyLowBranchFile;
end

if ~exist(minimaFile, 'file') || ~exist(branchFile, 'file')
    error('Modal-atlas CSV files were not found. Run diagnose_acoustoelastic_iop_hgo_modal_atlas first.');
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

function trackerComparison = compareTrackers(params, points, rawOptions, normalizedOptions, gridPoints, iop)
trackerComparison = table();
for g = 1:numel(gridPoints)
    opt = rawOptions;
    opt.numCpScanPoints = gridPoints(g);
    rawResult = solveAcoustoelasticIOPHGODispersion(params, opt);

    opt = normalizedOptions;
    opt.numCpScanPoints = gridPoints(g);
    normalizedResult = solveAcoustoelasticIOPHGODispersion(params, opt);

    trackerComparison = [trackerComparison; compareTrackerCase(points, rawResult, iop, gridPoints(g), "corrected_raw_matrix")]; %#ok<AGROW>
    trackerComparison = [trackerComparison; compareTrackerCase(points, normalizedResult, iop, gridPoints(g), "corrected_row_normalized")]; %#ok<AGROW>
end
end

function T = compareTrackerCase(points, result, iop, gridPoints, condition)
cpInterp = interp1(points.Frequency_Hz, points.Cp_mps, result.frequency(:), 'linear', nan);
valid = result.validCp(:) & isfinite(result.Cp(:)) & isfinite(cpInterp);
T = table();
T.Condition = repmat(condition, numel(result.frequency), 1);
T.IOP_mmHg = repmat(iop, numel(result.frequency), 1);
T.GridPoints = repmat(gridPoints, numel(result.frequency), 1);
T.Frequency_Hz = result.frequency(:);
T.Frequency_kHz = result.frequency(:)/1e3;
T.CandidateCp_mps = cpInterp(:);
T.TrackerCp_mps = result.Cp(:);
T.ValidComparison = valid(:);
T.RelativeDifference = abs(T.TrackerCp_mps - T.CandidateCp_mps) ./ max(abs(T.CandidateCp_mps), eps);
end

function summary = summarizeTrackerComparison(T)
validRows = T(T.ValidComparison, :);
[G, condition, iop, gridPoints] = findgroups(validRows.Condition, validRows.IOP_mmHg, validRows.GridPoints);
medianDiff = splitapply(@(x) median(x, 'omitnan'), validRows.RelativeDifference, G);
maxDiff = splitapply(@(x) max(x, [], 'omitnan'), validRows.RelativeDifference, G);
numPoints = splitapply(@numel, validRows.RelativeDifference, G);
summary = table(condition, iop, gridPoints, numPoints, medianDiff, maxDiff, ...
    'VariableNames', {'Condition','IOP_mmHg','GridPoints','ValidPoints','MedianRelativeDifference','MaxRelativeDifference'});
end

function plotCandidateVsTrackers(params, points, rawOptions, normalizedOptions, gridPoints, iop, outputFolder)
figure('Color', 'w');
plot(points.Frequency_kHz, points.Cp_mps, 'k-', 'LineWidth', 2.5, 'DisplayName', 'raw branch-1 candidate');
hold on;
styles = {'--', ':', '-.'};
for g = 1:numel(gridPoints)
    opt = rawOptions;
    opt.numCpScanPoints = gridPoints(g);
    rawResult = solveAcoustoelasticIOPHGODispersion(params, opt);
    valid = rawResult.validCp & isfinite(rawResult.Cp);
    plot(rawResult.frequency(valid)/1e3, rawResult.Cp(valid), styles{min(g, numel(styles))}, ...
        'LineWidth', 1.4, 'DisplayName', sprintf('raw matrix tracker %d', gridPoints(g)));

    opt = normalizedOptions;
    opt.numCpScanPoints = gridPoints(g);
    normalizedResult = solveAcoustoelasticIOPHGODispersion(params, opt);
    valid = normalizedResult.validCp & isfinite(normalizedResult.Cp);
    plot(normalizedResult.frequency(valid)/1e3, normalizedResult.Cp(valid), styles{min(g, numel(styles))}, ...
        'LineWidth', 1.4, 'DisplayName', sprintf('row-normalized tracker %d', gridPoints(g)));
end
hold off;
grid on;
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title(sprintf('Corrected raw branch-1 candidate vs trackers, IOP %.1f mmHg', iop));
legend('Location', 'best');
saveas(gcf, fullfile(outputFolder, sprintf('raw_branch1_vs_trackers_IOP_%g.fig', iop)));
saveas(gcf, fullfile(outputFolder, sprintf('raw_branch1_vs_trackers_IOP_%g.png', iop)));
end

function plotCandidateAcrossIOP(candidateCurve, outputFolder)
figure('Color', 'w');
hold on;
iopList = unique(candidateCurve.IOP_mmHg, 'stable');
for i = 1:numel(iopList)
    T = candidateCurve(candidateCurve.IOP_mmHg == iopList(i), :);
    plot(T.Frequency_kHz, T.Cp_mps, 'LineWidth', 1.8, 'DisplayName', sprintf('IOP %.1f mmHg', iopList(i)));
end
hold off;
grid on;
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title('Corrected raw branch-1 candidate across IOP');
legend('Location', 'best');
saveas(gcf, fullfile(outputFolder, 'raw_branch1_candidate_across_iop.fig'));
saveas(gcf, fullfile(outputFolder, 'raw_branch1_candidate_across_iop.png'));
end

function plotTrackerComparisonSummary(summary, outputFolder)
figure('Color', 'w');
labels = strcat(summary.Condition, " | IOP ", string(summary.IOP_mmHg), " | N ", string(summary.GridPoints));
bar(categorical(labels), summary.MedianRelativeDifference);
grid on;
ylabel('median relative difference');
title('Tracker agreement with corrected raw branch-1 candidate');
xtickangle(35);
saveas(gcf, fullfile(outputFolder, 'raw_branch1_tracker_summary.fig'));
saveas(gcf, fullfile(outputFolder, 'raw_branch1_tracker_summary.png'));
end
