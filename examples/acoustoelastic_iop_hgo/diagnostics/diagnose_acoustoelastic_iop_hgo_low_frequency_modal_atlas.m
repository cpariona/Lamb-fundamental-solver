clear; clc; close all;
startup

% Li 2024 low-frequency modal atlas diagnostic.
%
% Purpose:
%   Extend the modal atlas toward low frequencies to identify whether a
%   Lamb-like A0 branch emerges cleanly from the low-frequency limit and to
%   test whether dense clusters of local minima persist or disappear under
%   alternative matrix/modeling conditions.
%
% This script saves data only: CSV tables and a MAT workspace. It does not
% save figures. Figures are generated only for interactive inspection.

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

% Low-frequency atlas settings.
baseParams.frequency = logspace(log10(100), log10(35e3), 160); % Hz
atlasIOP_mmHg = [5, 15, 25];
atlasIOP_Pa = atlasIOP_mmHg * 133.322;

% Dimensionless phase-velocity grid.
% y = Cp/sqrt(alpha/rho). The lower bound is intentionally small to allow
% inspection of a possible flexural A0 onset.
yGrid = logspace(log10(0.003), log10(2.0), 900);
topNMinimaPerFrequency = 16;
maxLogYJumpForBranch = 0.075;
minBranchPoints = 10;

baseOptions = defaultAcoustoelasticIOPHGOOptions();
baseOptions.branch = "A0";
baseOptions.trackingDirection = "backward";
baseOptions.trackingMethod = "globalScan";
baseOptions.minDimensionlessFrequency = 0.0;
baseOptions.usePhysicalCpWindow = false;

conditionList = makeLowFrequencyConditionList(baseOptions);

allMinima = table();
allBranches = table();
conditionSummary = table();
atlasMaps = struct();

fprintf('\nLi 2024 low-frequency modal atlas diagnostic\n');
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

        fprintf('  IOP %.1f mmHg: computing low-frequency atlas...\n', atlasIOP_mmHg(i));
        atlas = computeModalAtlasForCase(directParams, condition.options, yGrid, topNMinimaPerFrequency, ...
            maxLogYJumpForBranch, minBranchPoints);

        atlas.conditionLabel = condition.label;
        atlas.IOP_mmHg = atlasIOP_mmHg(i);
        atlas.state = state;
        atlas.directParams = directParams;

        minimaTable = decorateMinimaTable(atlas.minimaTable, condition.label, atlasIOP_mmHg(i), atlasIOP_Pa(i), state);
        branchTable = decorateBranchTable(atlas.branchTable, condition.label, atlasIOP_mmHg(i), atlasIOP_Pa(i), state);
        summaryTable = summarizeLowFrequencyAtlas(minimaTable, branchTable, condition.label, atlasIOP_mmHg(i));

        allMinima = [allMinima; minimaTable]; %#ok<AGROW>
        allBranches = [allBranches; branchTable]; %#ok<AGROW>
        conditionSummary = [conditionSummary; summaryTable]; %#ok<AGROW>

        key = matlab.lang.makeValidName(sprintf('%s_IOP_%g', condition.label, atlasIOP_mmHg(i)));
        atlasMaps.(key) = atlas;

        % plotLowFrequencyAtlasCase(atlas, condition); % disabled for routine short-entrypoint execution
    end
end

outputFolder = aeOutputFolder(pwd, 'modal_atlas_lowfreq');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

writetable(allMinima, fullfile(outputFolder, 'acoustoelastic_iop_hgo_low_frequency_modal_atlas_minima_table.csv'));
writetable(allBranches, fullfile(outputFolder, 'acoustoelastic_iop_hgo_low_frequency_modal_atlas_branch_table.csv'));
writetable(conditionSummary, fullfile(outputFolder, 'acoustoelastic_iop_hgo_low_frequency_modal_atlas_condition_summary_table.csv'));

save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_low_frequency_modal_atlas_workspace.mat'), ...
    'atlasMaps', 'allMinima', 'allBranches', 'conditionSummary', ...
    'baseParams', 'atlasIOP_mmHg', 'yGrid', 'conditionList', ...
    '-v7.3');

fprintf('\nLow-frequency minima table preview\n');
disp(head(allMinima, min(20, height(allMinima))));

fprintf('\nLow-frequency branch table\n');
disp(allBranches);

fprintf('\nLow-frequency condition summary table\n');
disp(conditionSummary);

fprintf('\nData files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOLowFrequencyAtlasMaps', atlasMaps);
assignin('base', 'AcoustoelasticIOPHGOLowFrequencyAtlasMinimaTable', allMinima);
assignin('base', 'AcoustoelasticIOPHGOLowFrequencyAtlasBranchTable', allBranches);
assignin('base', 'AcoustoelasticIOPHGOLowFrequencyAtlasConditionSummaryTable', conditionSummary);

function conditionList = makeLowFrequencyConditionList(baseOptions)
conditionList = struct([]);

opt = baseOptions;
opt.M54_variant = "corrected";
opt.normalizeRows = true;
conditionList(1).label = "corrected_row_normalized";
conditionList(1).description = "Corrected M54, row-normalized matrix";
conditionList(1).options = opt;

opt = baseOptions;
opt.M54_variant = "paper";
opt.normalizeRows = true;
conditionList(2).label = "paperM54_row_normalized";
conditionList(2).description = "Paper M54 expression, row-normalized matrix";
conditionList(2).options = opt;

opt = baseOptions;
opt.M54_variant = "corrected";
opt.normalizeRows = false;
conditionList(3).label = "corrected_raw_matrix";
conditionList(3).description = "Corrected M54, no row normalization";
conditionList(3).options = opt;
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

if isempty(minimaRows)
    minimaTable = table();
    branchTable = table();
else
    minimaTable = struct2table(minimaRows);
    [minimaTable, branchTable] = linkMinimaIntoBranches(minimaTable, maxLogYJump, minBranchPoints);
end

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
finiteObj = obj(isfinite(obj));
medianObj = median(finiteObj, 'omitnan');
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
    row.FrequencyStart_Hz = min(T.Frequency_Hz);
    row.FrequencyEnd_Hz = max(T.Frequency_Hz);
    row.FrequencyStart_kHz = min(T.Frequency_kHz);
    row.FrequencyEnd_kHz = max(T.Frequency_kHz);
    row.FrequencyCoverage_kHz = row.FrequencyEnd_kHz - row.FrequencyStart_kHz;
    row.CpStart_mps = T.Cp_mps(1);
    row.CpEnd_mps = T.Cp_mps(end);
    row.MinCp_mps = min(T.Cp_mps);
    row.MaxCp_mps = max(T.Cp_mps);
    row.MedianCp_mps = median(T.Cp_mps, 'omitnan');
    row.MedianY = median(T.y, 'omitnan');
    row.MedianRank = median(T.MinRank, 'omitnan');
    row.MedianObjective = median(T.Objective, 'omitnan');
    row.MedianDepthRelativeToMedian = median(T.DepthRelativeToMedian, 'omitnan');
    row.MedianSpacingToNearestLogY = median(T.SpacingToNearestLogY, 'omitnan');
    row.LowFrequencyCp_mps = T.Cp_mps(1);
    row.HighFrequencyCp_mps = T.Cp_mps(end);
    row.NetCpIncrease_mps = T.Cp_mps(end) - T.Cp_mps(1);
    if height(T) >= 3
        row.Roughness = median(abs(diff(T.Cp_mps, 2)), 'omitnan') / max(median(abs(T.Cp_mps), 'omitnan'), eps);
    else
        row.Roughness = nan;
    end
    branchRows = [branchRows; row]; %#ok<AGROW>
end

if isempty(branchRows)
    branchTable = table();
else
    branchTable = struct2table(branchRows);
end
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

function summary = summarizeLowFrequencyAtlas(minimaTable, branchTable, label, IOP_mmHg)
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
    [roughness, idxSmooth] = min(branchTable.Roughness);
    summary.SmoothestBranchID = branchTable.BranchID(idxSmooth);
    summary.SmoothestBranchRoughness = roughness;

    % Candidate Lamb-like low-frequency branch: broad coverage, low y at the
    % first frequency, positive Cp increase, and low roughness.
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

function plotLowFrequencyAtlasCase(atlas, condition)
figure('Color', 'w', 'Name', sprintf('Low frequency atlas %s IOP %.0f', condition.label, atlas.IOP_mmHg));
imagesc(atlas.frequency/1e3, atlas.yGrid, atlas.objectiveMap);
set(gca, 'YScale', 'log', 'XScale', 'log', 'YDir', 'normal');
hold on; grid on;
colormap(parula);
cb = colorbar;
cb.Label.String = 'log10(sigma_{min})';

T = atlas.minimaTable;
if ~isempty(T)
    validBranches = isfinite(T.BranchID);
    scatter(T.Frequency_kHz(validBranches), T.y(validBranches), 16, T.BranchID(validBranches), 'filled', ...
        'MarkerEdgeAlpha', 0.30, 'MarkerFaceAlpha', 0.70, 'HandleVisibility', 'off');
end
xlabel('frequency [kHz]');
ylabel('Cp / sqrt(alpha/rho) [-]');
title(sprintf('Low-frequency Li 2024 modal atlas: %s, IOP %.0f mmHg', condition.label, atlas.IOP_mmHg), 'Interpreter', 'none');
hold off;
end
