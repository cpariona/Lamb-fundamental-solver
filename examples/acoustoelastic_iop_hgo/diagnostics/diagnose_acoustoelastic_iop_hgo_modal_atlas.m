clear; clc; close all;
startup

% Li 2024 modal atlas diagnostic.
%
% This diagnostic builds a full frequency-Cp map of the characteristic-matrix
% objective and then identifies local-minimum families as continuous branches.
%
% Main goal:
%   Stop trusting a single tracker blindly. Instead, visualize and quantify:
%     1. all local minima in the f-Cp plane,
%     2. which minima organize into smooth persistent branches,
%     3. which branch each existing tracker is following,
%     4. whether dense clusters of low-Cp minima persist or disappear under
%        alternative numerical/modeling conditions.

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

referenceFrequency = 20e3;
baseParams.frequency = ensureFrequencyIncludesReference(linspace(6e3, 35e3, 100), referenceFrequency);

% Keep this list focused at first. Add 5 and 10 mmHg later if needed.
atlasIOP_mmHg = [15, 20, 25];
atlasIOP_Pa = atlasIOP_mmHg * 133.322;

% Logarithmic y-grid reveals Lamb-like valleys more clearly than a linear Cp grid.
% y = Cp / sqrt(alpha/rho).
yGrid = logspace(log10(0.03), log10(1.60), 720);
topNMinimaPerFrequency = 14;
maxLogYJumpForBranch = 0.085;
minBranchPoints = 8;

% Existing tracker overlays. These are not used to define branches.
trackerGridPoints = [900, 1800, 3600];

baseOptions = defaultAcoustoelasticIOPHGOOptions();
baseOptions.branch = "A0";
baseOptions.trackingDirection = "backward";
baseOptions.trackingMethod = "globalScan";
baseOptions.minDimensionlessFrequency = 0.20;

conditionList = makeConditionList(baseOptions);

allMinima = table();
allBranches = table();
allTrackerMatches = table();
conditionSummary = table();
atlasMaps = struct();
trackerResults = struct();

fprintf('\nLi 2024 modal atlas diagnostic\n');
fprintf('Frequency points: %d, y-grid points: %d\n', numel(baseParams.frequency), numel(yGrid));
fprintf('IOP values: %s mmHg\n\n', mat2str(atlasIOP_mmHg));

for c = 1:numel(conditionList)
    condition = conditionList(c);
    fprintf('Condition %d/%d: %s\n', c, numel(conditionList), condition.label);

    for i = 1:numel(atlasIOP_mmHg)
        params = baseParams;
        params.IOP = atlasIOP_Pa(i);
        [directParams, state] = buildDirectParamsFromIOP(params);

        fprintf('  IOP %.1f mmHg: building objective map...\n', atlasIOP_mmHg(i));
        atlas = computeModalAtlasForCase(directParams, condition.options, yGrid, topNMinimaPerFrequency, ...
            maxLogYJumpForBranch, minBranchPoints);

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

outputFolder = aeOutputFolder(pwd, 'modal_atlas');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
writetable(allMinima, fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_minima_table.csv'));
writetable(allBranches, fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_branch_table.csv'));
writetable(allTrackerMatches, fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_tracker_match_table.csv'));
writetable(conditionSummary, fullfile(outputFolder, 'acoustoelastic_iop_hgo_modal_atlas_condition_summary_table.csv'));

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

function frequency = ensureFrequencyIncludesReference(frequency, fRef)
frequency = unique([frequency(:); fRef]);
frequency = sort(frequency(:)).';
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

function atlas = computeModalAtlasForCase(params, options, yGrid, topN, maxLogYJump, minBranchPoints)
freq = params.frequency(:).';
cShear = sqrt(params.alpha / params.rho);
cGrid = yGrid(:) * cShear;
objectiveMap = nan(numel(yGrid), numel(freq));
minimaRows = [];

for k = 1:numel(freq)
    f = freq(k);
    for j = 1:numel(cGrid)
        objectiveMap(j, k) = objectiveAcoustoelasticResidual(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cGrid(j), options);
    end

    minima = findTopLocalMinima(cGrid, objectiveMap(:, k), cShear, topN);
    for m = 1:height(minima)
        row = struct();
        row.Frequency_Hz = f;
        row.Frequency_kHz = f / 1e3;
        row.MinRank = m;
        row.Cp_mps = minima.Cp(m);
        row.y = minima.y(m);
        row.log10y = log10(minima.y(m));
        row.Objective = minima.Objective(m);
        row.DepthRelativeToMedian = minima.DepthRelativeToMedian(m);
        row.DepthRelativeToDeepest = minima.DepthRelativeToDeepest(m);
        row.SpacingToNearestLogY = minima.SpacingToNearestLogY(m);
        row.BranchID = nan;
        minimaRows = [minimaRows; row]; %#ok<AGROW>
    end
end

minimaTable = struct2table(minimaRows);
[minimaTable, branchTable] = linkMinimaIntoBranches(minimaTable, maxLogYJump, minBranchPoints);

atlas = struct();
atlas.frequency = freq;
atlas.yGrid = yGrid(:);
atlas.cGrid = cGrid(:);
atlas.objectiveMap = objectiveMap;
atlas.minimaTable = minimaTable;
atlas.branchTable = branchTable;
atlas.options = options;
atlas.cShear = cShear;
end

function minimaTable = findTopLocalMinima(cGrid, obj, cShear, topN)
idx = [];
for k = 2:numel(obj)-1
    if isfinite(obj(k-1)) && isfinite(obj(k)) && isfinite(obj(k+1)) && obj(k) <= obj(k-1) && obj(k) <= obj(k+1)
        idx(end+1) = k; %#ok<AGROW>
    end
end
if isempty(idx)
    minimaTable = table([], [], [], [], [], [], 'VariableNames', ...
        {'Cp','y','Objective','DepthRelativeToMedian','DepthRelativeToDeepest','SpacingToNearestLogY'});
    return;
end

cp = cGrid(idx(:));
y = cp / cShear;
objective = obj(idx(:));
medianObj = median(obj(isfinite(obj)), 'omitnan');
deepest = min(objective, [], 'omitnan');
depthRelMedian = medianObj - objective;
depthRelDeepest = objective - deepest;

logY = log10(y);
spacing = nan(size(logY));
for i = 1:numel(logY)
    others = logY;
    others(i) = [];
    if isempty(others)
        spacing(i) = inf;
    else
        spacing(i) = min(abs(logY(i) - others));
    end
end

[objective, order] = sort(objective, 'ascend');
cp = cp(order);
y = y(order);
depthRelMedian = depthRelMedian(order);
depthRelDeepest = depthRelDeepest(order);
spacing = spacing(order);
keep = 1:min(topN, numel(cp));
minimaTable = table(cp(keep), y(keep), objective(keep), depthRelMedian(keep), depthRelDeepest(keep), spacing(keep), ...
    'VariableNames', {'Cp','y','Objective','DepthRelativeToMedian','DepthRelativeToDeepest','SpacingToNearestLogY'});
end

function [minimaTable, branchTable] = linkMinimaIntoBranches(minimaTable, maxLogYJump, minBranchPoints)
if isempty(minimaTable)
    branchTable = table();
    return;
end

minimaTable = sortrows(minimaTable, {'Frequency_Hz','MinRank'});
minimaTable.BranchID(:) = nan;
branchLastLogY = [];
branchLastFreq = [];
branchLastRow = [];
branchID = 0;

freqList = unique(minimaTable.Frequency_Hz, 'stable');
for k = 1:numel(freqList)
    f = freqList(k);
    idx = find(minimaTable.Frequency_Hz == f);
    assignedBranches = false(1, max(branchID, 1));

    for ii = 1:numel(idx)
        r = idx(ii);
        yLog = minimaTable.log10y(r);
        bestBranch = nan;
        bestScore = inf;

        for b = 1:branchID
            if b <= numel(assignedBranches) && assignedBranches(b)
                continue;
            end
            if branchLastFreq(b) >= f
                continue;
            end
            jump = abs(yLog - branchLastLogY(b));
            if jump > maxLogYJump
                continue;
            end
            score = jump + 0.02 * minimaTable.MinRank(r);
            if score < bestScore
                bestScore = score;
                bestBranch = b;
            end
        end

        if isnan(bestBranch)
            branchID = branchID + 1;
            bestBranch = branchID;
            assignedBranches(bestBranch) = false;
        end

        minimaTable.BranchID(r) = bestBranch;
        branchLastLogY(bestBranch) = yLog; %#ok<AGROW>
        branchLastFreq(bestBranch) = f; %#ok<AGROW>
        branchLastRow(bestBranch) = r; %#ok<AGROW>
        assignedBranches(bestBranch) = true;
    end
end

branchRows = [];
for b = 1:branchID
    mask = minimaTable.BranchID == b;
    T = minimaTable(mask, :);
    if height(T) < minBranchPoints
        minimaTable.BranchID(mask) = nan;
        continue;
    end
    T = sortrows(T, 'Frequency_Hz');
    row = struct();
    row.BranchID = b;
    row.NumPoints = height(T);
    row.FrequencyStart_kHz = min(T.Frequency_kHz);
    row.FrequencyEnd_kHz = max(T.Frequency_kHz);
    row.FrequencyCoverage_kHz = row.FrequencyEnd_kHz - row.FrequencyStart_kHz;
    row.CpStart_mps = T.Cp_mps(1);
    row.CpEnd_mps = T.Cp_mps(end);
    row.MinCp_mps = min(T.Cp_mps);
    row.MaxCp_mps = max(T.Cp_mps);
    row.MedianCp_mps = median(T.Cp_mps, 'omitnan');
    row.MedianRank = median(T.MinRank, 'omitnan');
    row.MedianObjective = median(T.Objective, 'omitnan');
    row.MedianDepthRelativeToMedian = median(T.DepthRelativeToMedian, 'omitnan');
    row.MedianSpacingToNearestLogY = median(T.SpacingToNearestLogY, 'omitnan');
    if height(T) >= 3
        row.Roughness = median(abs(diff(T.Cp_mps, 2)), 'omitnan') / max(median(abs(T.Cp_mps), 'omitnan'), eps);
    else
        row.Roughness = nan;
    end
    branchRows = [branchRows; row]; %#ok<AGROW>
end
branchTable = struct2table(branchRows);
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
summary.MedianMinimaPerFrequency = median(splitapply(@numel, minimaTable.Cp_mps, findgroups(minimaTable.Frequency_Hz)), 'omitnan');
if isempty(branchTable)
    summary.MaxBranchCoverage_kHz = nan;
    summary.SmoothestBranchID = nan;
    summary.SmoothestBranchRoughness = nan;
else
    summary.MaxBranchCoverage_kHz = max(branchTable.FrequencyCoverage_kHz);
    [roughness, idx] = min(branchTable.Roughness);
    summary.SmoothestBranchID = branchTable.BranchID(idx);
    summary.SmoothestBranchRoughness = roughness;
end
end

function [trackerTable, trackerResultsForCase] = computeTrackerMatchesForCase(params, options, atlas, gridList)
rows = [];
trackerResultsForCase = cell(numel(gridList), 1);
for g = 1:numel(gridList)
    opt = options;
    opt.numCpScanPoints = gridList(g);
    result = solveAcoustoelasticIOPHGODispersion(params, opt);
    trackerResultsForCase{g} = result;

    for k = 1:numel(result.frequency)
        f = result.frequency(k);
        cpTracked = result.Cp(k);
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
set(gca, 'YScale', 'log', 'YDir', 'normal');
hold on; grid on;
colormap(parula);
cb = colorbar;
cb.Label.String = 'log10(sigma_{min})';

T = atlas.minimaTable;
validBranches = isfinite(T.BranchID);
scatter(T.Frequency_kHz(validBranches), T.y(validBranches), 18, T.BranchID(validBranches), 'filled', ...
    'MarkerEdgeAlpha', 0.35, 'MarkerFaceAlpha', 0.70, 'HandleVisibility', 'off');

if condition.overlayTrackers && isfield(trackerResults, key)
    tracker = trackerResults.(key);
    markerList = {'w-', 'c-', 'm-', 'g-'};
    for g = 1:numel(tracker)
        r = tracker{g};
        if isempty(r)
            continue;
        end
        yTracked = r.Cp ./ atlas.cShear;
        valid = r.validCp & isfinite(yTracked);
        style = markerList{min(g, numel(markerList))};
        plot(r.frequency(valid)/1e3, yTracked(valid), style, 'LineWidth', 1.8, ...
            'DisplayName', sprintf('tracker grid %d', r.options.numCpScanPoints));
    end
    legend('Location', 'best');
end

xlabel('frequency [kHz]');
ylabel('Cp / sqrt(alpha/rho) [-]');
title(sprintf('Li 2024 modal atlas: %s, IOP %.0f mmHg', condition.label, atlas.IOP_mmHg), 'Interpreter', 'none');
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
title('Li 2024 modal atlas branch persistence summary');
cb = colorbar;
cb.Label.String = 'median minimum rank';
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
