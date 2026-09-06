clear; clc; close all;
addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

% Li 2024 modal atlas diagnostic.
%
% This diagnostic builds a full low-frequency-to-high-frequency Cp map of the
% characteristic-matrix objective and identifies local-minimum families as
% continuous branches.
%
% Main goal:
%   Stop trusting a single tracker blindly. Instead, visualize and quantify:
%     1. all local minima in the f-Cp plane,
%     2. which minima organize into smooth persistent branches,
%     3. which branch each existing tracker is following,
%     4. whether dense clusters of low-Cp minima persist or disappear under
%        alternative numerical/modeling conditions.
%
% Frequency convention:
%   The modal atlas must start at low frequency. A separate low-frequency
%   diagnostic is intentionally not maintained; low-frequency onset is part of
%   the standard atlas definition.

baseParams = struct();

% Geometry.
baseParams.R = 7.8e-3;                  % m
baseParams.thickness = 550e-6;          % m

% HGO parameters. Example values for pipeline testing only.
baseParams.mu = 50e3;                   % Pa
baseParams.k1 = 25e3;                   % Pa
baseParams.k2 = 100;                    % dimensionless

% Densities and fluid bulk modulus.
baseParams.rho = 1060;                  % kg/m^3
baseParams.rhoF = 1000;                 % kg/m^3
baseParams.fluidBulkModulus = 2.2e9;    % Pa

% Low-frequency-to-high-frequency atlas grid.
baseParams.frequency = logspace(log10(100), log10(35e3), 160); % Hz
atlasIOP_mmHg = [5, 15, 25];
atlasIOP_Pa = atlasIOP_mmHg * 133.322;

% Dimensionless phase-velocity grid.
% y = Cp/sqrt(alpha/rho). The lower bound is intentionally small to allow
% inspection of the flexural A0 onset.
yGrid = logspace(log10(0.003), log10(2.0), 900);
topNMinimaPerFrequency = 16;
maxLogYJumpForBranch = 0.075;
minBranchPoints = 10;

% Existing tracker overlays. These are not used to define branches.
trackerGridPoints = [900, 1800, 3600];

baseOptions = defaultAcoustoelasticIOPHGOOptions();
baseOptions.branch = "A0";
baseOptions.trackingDirection = "backward";
baseOptions.trackingMethod = "globalScan";
baseOptions.minDimensionlessFrequency = 0.0;
baseOptions.usePhysicalCpWindow = false;

conditionList = makeConditionList(baseOptions);

allMinima = table();
allBranches = table();
allTrackerMatches = table();
conditionSummary = table();
atlasMaps = struct();
trackerResults = struct();

fprintf('\nLi 2024 modal atlas diagnostic\n');
fprintf('Frequency range: %.3g Hz to %.3g kHz, %d points\n', min(baseParams.frequency), max(baseParams.frequency)/1e3, numel(baseParams.frequency));
fprintf('y-grid range: %.4g to %.4g, %d points\n', min(yGrid), max(yGrid), numel(yGrid));
fprintf('IOP values: %s mmHg\n\n', mat2str(atlasIOP_mmHg));

for c = 1:numel(conditionList)
    condition = conditionList(c);
    fprintf('Condition %d/%d: %s\n', c, numel(conditionList), condition.label);

    for i = 1:numel(atlasIOP_mmHg)
        params = baseParams;
        params.IOP = atlasIOP_Pa(i);
        [directParams, state] = buildDirectParamsFromIOP(params);

        fprintf('  IOP %.1f mmHg: building objective map...\n', atlasIOP_mmHg(i));
        atlas = aeComputeModalAtlasForCase(directParams, condition.options, yGrid, topNMinimaPerFrequency, ...
            maxLogYJumpForBranch, minBranchPoints, "lowFrequency");

        atlas.conditionLabel = condition.label;
        atlas.IOP_mmHg = atlasIOP_mmHg(i);
        atlas.state = state;
        atlas.directParams = directParams;

        minimaTable = decorateMinimaTable(atlas.minimaTable, condition.label, atlasIOP_mmHg(i), atlasIOP_Pa(i), state);
        branchTable = decorateBranchTable(atlas.branchTable, condition.label, atlasIOP_mmHg(i), atlasIOP_Pa(i), state);
        summaryTable = summarizeAtlasCondition(minimaTable, branchTable, condition.label, atlasIOP_mmHg(i));

        allMinima = [allMinima; minimaTable]; %#ok<AGROW>
        allBranches = [allBranches; branchTable]; %#ok<AGROW>
        conditionSummary = [conditionSummary; summaryTable]; %#ok<AGROW>

        key = matlab.lang.makeValidName(sprintf('%s_IOP_%g', condition.label, atlasIOP_mmHg(i)));
        atlasMaps.(key) = atlas;

        if condition.overlayTrackers
            [trackerTable, trackerResultsForCase] = computeTrackerMatchesForCase(params, condition.options, atlas, trackerGridPoints);
            allTrackerMatches = [allTrackerMatches; decorateTrackerTable(trackerTable, condition.label, atlasIOP_mmHg(i))]; %#ok<AGROW>
            trackerResults.(key) = trackerResultsForCase;
        end

        plotModalAtlasCase(atlas, condition, trackerResults, key);
    end
end

plotBranchPersistenceSummary(allBranches);
plotConditionMinimaDensity(conditionSummary);

outputFolder = resolveModelOutputFolder(pwd, 'ae_iop_hgo', 'modal_atlas');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
writetable(allMinima, fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_minima_table.csv'));
writetable(allBranches, fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_branch_table.csv'));
writetable(allTrackerMatches, fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_tracker_match_table.csv'));
writetable(conditionSummary, fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_condition_summary_table.csv'));

% Short canonical aliases used by downstream diagnostic helpers.
writetable(allMinima, fullfile(outputFolder, 'modal_atlas_minima.csv'));
writetable(allBranches, fullfile(outputFolder, 'modal_atlas_branches.csv'));

save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_workspace.mat'), ...
    'atlasMaps', 'allMinima', 'allBranches', 'allTrackerMatches', 'conditionSummary', ...
    'baseParams', 'atlasIOP_mmHg', 'yGrid', 'conditionList', 'trackerResults', '-v7.3');

fprintf('\nModal-atlas minima table\n');
disp(head(allMinima, min(20, height(allMinima))));

fprintf('\nModal-atlas branch table\n');
disp(allBranches);

fprintf('\nModal-atlas tracker match table\n');
disp(head(allTrackerMatches, min(30, height(allTrackerMatches))));

fprintf('\nCondition summary table\n');
disp(conditionSummary);

fprintf('\nCSV files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOModalAtlasMaps', atlasMaps);
assignin('base', 'AcoustoelasticIOPHGOModalAtlasMinimaTable', allMinima);
assignin('base', 'AcoustoelasticIOPHGOModalAtlasBranchTable', allBranches);
assignin('base', 'AcoustoelasticIOPHGOModalAtlasTrackerMatchTable', allTrackerMatches);
assignin('base', 'AcoustoelasticIOPHGOModalAtlasConditionSummaryTable', conditionSummary);
assignin('base', 'AcoustoelasticIOPHGOModalAtlasTrackerResults', trackerResults);

function conditionList = makeConditionList(baseOptions)
conditionList = struct([]);

opt = baseOptions;
opt.M54_variant = "corrected";
opt.normalizeRows = true;
conditionList(1).label = "corrected_row_normalized";
conditionList(1).description = "Corrected M54, row-normalized matrix";
conditionList(1).options = opt;
conditionList(1).overlayTrackers = true;

opt = baseOptions;
opt.M54_variant = "paper";
opt.normalizeRows = true;
conditionList(2).label = "paperM54_row_normalized";
conditionList(2).description = "Paper M54 expression, row-normalized matrix";
conditionList(2).options = opt;
conditionList(2).overlayTrackers = false;

opt = baseOptions;
opt.M54_variant = "corrected";
opt.normalizeRows = false;
conditionList(3).label = "corrected_raw_matrix";
conditionList(3).description = "Corrected M54, no row normalization";
conditionList(3).options = opt;
conditionList(3).overlayTrackers = false;
end

function [directParams, state] = buildDirectParamsFromIOP(params)
[alpha, beta, gamma, state] = computeAcoustoelasticABGFromIOPHGO( ...
    params.IOP, params.R, params.thickness, params.mu, params.k1, params.k2);
directParams = struct();
directParams.alpha = alpha;
directParams.beta = beta;
directParams.gamma = gamma;
directParams.thickness = params.thickness;
directParams.rho = params.rho;
directParams.rhoF = params.rhoF;
directParams.fluidBulkModulus = params.fluidBulkModulus;
directParams.frequency = params.frequency(:).';
end

function T = decorateMinimaTable(T, label, IOP_mmHg, IOP_Pa, state)
if isempty(T)
    return;
end
T.Condition = repmat(string(label), height(T), 1);
T.IOP_mmHg = repmat(IOP_mmHg, height(T), 1);
T.IOP_kPa = repmat(IOP_Pa/1e3, height(T), 1);
T.Sigma_kPa = repmat(state.sigma/1e3, height(T), 1);
T.Lambda = repmat(state.lambda, height(T), 1);
T = movevars(T, {'Condition','IOP_mmHg','IOP_kPa','Sigma_kPa','Lambda'}, 'Before', 1);
end

function T = decorateBranchTable(T, label, IOP_mmHg, IOP_Pa, state)
if isempty(T)
    return;
end
T.Condition = repmat(string(label), height(T), 1);
T.IOP_mmHg = repmat(IOP_mmHg, height(T), 1);
T.IOP_kPa = repmat(IOP_Pa/1e3, height(T), 1);
T.Sigma_kPa = repmat(state.sigma/1e3, height(T), 1);
T.Lambda = repmat(state.lambda, height(T), 1);
T = movevars(T, {'Condition','IOP_mmHg','IOP_kPa','Sigma_kPa','Lambda'}, 'Before', 1);
end

function summary = summarizeAtlasCondition(minimaTable, branchTable, label, IOP_mmHg)
summary = table();
summary.Condition = string(label);
summary.IOP_mmHg = IOP_mmHg;
summary.NumMinima = height(minimaTable);
summary.NumPersistentBranches = height(branchTable);
if isempty(minimaTable)
    summary.MedianMinimaPerFrequency = nan;
    summary.MedianNearestSpacingLogY = nan;
else
    [G, ~] = findgroups(minimaTable.Frequency_Hz);
    summary.MedianMinimaPerFrequency = median(splitapply(@numel, minimaTable.Cp_mps, G), 'omitnan');
    summary.MedianNearestSpacingLogY = median(minimaTable.SpacingToNearestLogY, 'omitnan');
end
if isempty(branchTable)
    summary.MaxBranchCoverage_kHz = nan;
    summary.SmoothestBranchID = nan;
    summary.SmoothestBranchRoughness = nan;
    summary.BestLowFrequencyCandidateID = nan;
else
    summary.MaxBranchCoverage_kHz = max(branchTable.FrequencyCoverage_kHz);
    [roughness, idx] = min(branchTable.Roughness);
    summary.SmoothestBranchID = branchTable.BranchID(idx);
    summary.SmoothestBranchRoughness = roughness;

    score = normalizeMetric(branchTable.MedianY) + normalizeMetric(branchTable.Roughness) ...
        - normalizeMetric(branchTable.FrequencyCoverage_kHz) - 0.5*normalizeMetric(branchTable.NetCpIncrease_mps);
    [~, idxBest] = min(score);
    summary.BestLowFrequencyCandidateID = branchTable.BranchID(idxBest);
end
end

function x = normalizeMetric(x)
x = x(:);
finiteMask = isfinite(x);
if ~any(finiteMask)
    x(:) = 0;
    return;
end
xmin = min(x(finiteMask));
xmax = max(x(finiteMask));
if abs(xmax - xmin) < eps
    x(finiteMask) = 0;
else
    x(finiteMask) = (x(finiteMask) - xmin) ./ (xmax - xmin);
end
x(~finiteMask) = 1;
end

function [trackerTable, trackerResultsForCase] = computeTrackerMatchesForCase(params, options, atlas, gridList)
rows = [];
trackerResultsForCase = cell(numel(gridList), 1);
for g = 1:numel(gridList)
    opt = options;
    opt.numCpScanPoints = gridList(g);
    result = solveAcoustoelasticIOPHGODispersion(params, opt);
    trackerResultsForCase{g} = result;

    for k = 1:numel(result.frequency_Hz)
        f = result.frequency_Hz(k);
        cpTracked = result.phaseVelocity_mps(k);
        candidates = atlas.minimaTable(atlas.minimaTable.Frequency_Hz == f, :);
        row = struct();
        row.GridPoints = gridList(g);
        row.Frequency_Hz = f;
        row.Frequency_kHz = f/1e3;
        row.TrackedCp_mps = cpTracked;
        row.NearestBranchID = nan;
        row.NearestMinRank = nan;
        row.NearestMinCp_mps = nan;
        row.DistanceToNearestMin_mps = nan;
        row.RelativeDistanceToNearestMin = nan;
        row.NearestMinObjective = nan;
        if isfinite(cpTracked) && ~isempty(candidates)
            [distance, idx] = min(abs(candidates.Cp_mps - cpTracked));
            nearestCp = candidates.Cp_mps(idx);
            row.NearestBranchID = candidates.BranchID(idx);
            row.NearestMinRank = candidates.MinRank(idx);
            row.NearestMinCp_mps = nearestCp;
            row.DistanceToNearestMin_mps = distance;
            row.RelativeDistanceToNearestMin = distance / max(abs(nearestCp), eps);
            row.NearestMinObjective = candidates.Objective(idx);
        end
        rows = [rows; row]; %#ok<AGROW>
    end
end
trackerTable = struct2table(rows);
end

function T = decorateTrackerTable(T, label, IOP_mmHg)
if isempty(T)
    return;
end
T.Condition = repmat(string(label), height(T), 1);
T.IOP_mmHg = repmat(IOP_mmHg, height(T), 1);
T = movevars(T, {'Condition','IOP_mmHg'}, 'Before', 1);
end

function plotModalAtlasCase(atlas, condition, trackerResults, key)
figure('Color', 'w', 'Name', sprintf('Modal atlas %s IOP %.0f', condition.label, atlas.IOP_mmHg));
imagesc(atlas.frequency/1e3, atlas.yGrid, atlas.objectiveMap);
set(gca, 'YScale', 'log', 'XScale', 'log', 'YDir', 'normal');
hold on; grid on;
colormap(parula);
colorbar;

T = atlas.minimaTable;
if ~isempty(T)
    validBranches = isfinite(T.BranchID);
    scatter(T.Frequency_kHz(validBranches), T.y(validBranches), 18, T.BranchID(validBranches), 'filled', ...
        'MarkerEdgeAlpha', 0.35, 'MarkerFaceAlpha', 0.70, 'HandleVisibility', 'off');
end

if condition.overlayTrackers && isfield(trackerResults, key)
    tracker = trackerResults.(key);
    markerList = {'w-', 'c-', 'm-', 'g-'};
    for g = 1:numel(tracker)
        r = tracker{g};
        if isempty(r)
            continue;
        end
        yTracked = r.phaseVelocity_mps ./ atlas.cShear;
        valid = r.validMask & isfinite(yTracked);
        style = markerList{min(g, numel(markerList))};
        plot(r.frequency_Hz(valid)/1e3, yTracked(valid), style, 'LineWidth', 1.8, ...
            'DisplayName', sprintf('tracker grid %d', r.options.numCpScanPoints));
    end
    legend('Location', 'best');
end

xlabel('frequency [kHz]');
ylabel('Cp / sqrt(alpha/rho) [-]');
title(sprintf('Li 2024 modal atlas: %s, IOP %.0f mmHg | color = log10 objective', condition.label, atlas.IOP_mmHg), 'Interpreter', 'none');
hold off;
end

function plotBranchPersistenceSummary(branchTable)
if isempty(branchTable)
    return;
end
figure('Color', 'w');
scatter(branchTable.FrequencyCoverage_kHz, branchTable.Roughness, 60, branchTable.MedianRank, 'filled');
grid on;
xlabel('branch frequency coverage [kHz]');
ylabel('branch roughness');
title('Li 2024 modal atlas branch persistence summary | color = median minimum rank');
colorbar;
end

function plotConditionMinimaDensity(summaryTable)
if isempty(summaryTable)
    return;
end
figure('Color', 'w');
labels = strcat(summaryTable.Condition, " | ", string(summaryTable.IOP_mmHg), " mmHg");
bar(categorical(labels), summaryTable.MedianMinimaPerFrequency);
grid on;
ylabel('median local minima per frequency');
title('Li 2024 modal atlas: density of local minima across conditions');
xtickangle(35);
end
