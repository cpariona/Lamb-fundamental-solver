clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_RAW_BRANCH_CORNER Diagnose low-mu/high-IOP raw-branch ambiguity.
%
% Diagnostic only. This script focuses on the difficult corner identified by
% validate_atlas_raw_grid: IOP = 35 mmHg, mu = 25 kPa. It tests whether the
% selected raw_branch1 candidate is sensitive to raw-atlas numerical settings:
% y-grid resolution, retained minima count, and branch-link jump threshold.
%
% The script does not promote raw_branch1 and does not modify result.Cp or
% result.validCp.
%
% Outputs:
%   Results/ae_iop_hgo/raw_branch_corner

outputFolder = aeOutputFolder(launchFolder, 'raw_branch_corner');
plotFolder = fullfile(outputFolder, 'plots');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

caseParams = defaultCornerParams();
settings = defaultCornerSettings();
configs = makeCornerConfigs();

fprintf('\nraw_branch1 corner ambiguity diagnostic\n');
fprintf('Case: IOP %.0f mmHg, mu %.0f kPa, k1 %.0f kPa, k2 %.0f, h %.0f um\n', ...
    caseParams.IOP_mmHg, caseParams.mu / 1e3, caseParams.k1 / 1e3, caseParams.k2, caseParams.thickness * 1e6);
fprintf('Configurations: %d | frequencies: %d\n\n', height(configs), numel(settings.frequency));

params = caseParams;
params.IOP = caseParams.IOP_mmHg * 133.322;
params.frequency = settings.frequency;

atlasOptions = defaultSolverOptions(settings);
atlasOptions.atlasBranchPolicy = "atlasA0";
atlasResult = solveAcoustoelasticIOPHGOBranch(params, atlasOptions);

identityOptions = atlasOptions;
identityOptions.atlasBranchPolicy = "identityA0Diagnostic";
identityResult = solveAcoustoelasticIOPHGOBranch(params, identityOptions);

[directParams, state] = buildDirectParamsFromIOP(params);

pointRows = table();
summaryRows = table();
branchRows = table();
caseResults = struct();
referenceRawPoints = table();
referenceLabel = string(configs.ConfigLabel(1));

for i = 1:height(configs)
    config = configs(i, :);
    configLabel = char(config.ConfigLabel);
    fprintf('Config %d/%d: %s\n', i, height(configs), configLabel);

    rawAtlas = computeRawModalAtlas(directParams, config);
    [rawBranch, rawPoints] = selectRawBranch(rawAtlas.branchTable, rawAtlas.minimaTable);
    rawPoints = addContextColumns(rawPoints, config, caseParams, state);
    rawBranch = addContextColumns(rawBranch, config, caseParams, state);

    if i == 1
        referenceRawPoints = rawPoints;
    end

    comparison = compareConfig(config, caseParams, rawPoints, referenceRawPoints, atlasResult, identityResult, settings);

    pointRows = [pointRows; comparison.points]; %#ok<AGROW>
    summaryRows = [summaryRows; comparison.summary]; %#ok<AGROW>
    if ~isempty(rawBranch)
        branchRows = [branchRows; rawBranch]; %#ok<AGROW>
    end

    caseResults(i).ConfigLabel = string(configLabel); %#ok<SAGROW>
    caseResults(i).config = config;
    caseResults(i).rawAtlas = rawAtlas;
    caseResults(i).rawBranch = rawBranch;
    caseResults(i).rawPoints = rawPoints;
    caseResults(i).comparison = comparison;

    plotConfigComparison(comparison.points, configLabel, plotFolder);

    fprintf('  %s | raw frac %.3f | raw median rank %.3g | atlas overlap %.3f | atlas median err %.4g | ref median err %.4g\n', ...
        char(comparison.summary.Classification), comparison.summary.RawValidFraction, comparison.summary.RawMedianRank, ...
        comparison.summary.AtlasRawValidOverlapFraction, comparison.summary.MedianAtlasRawRelError, ...
        comparison.summary.MedianReferenceRawRelError);
end

aggregate = summarizeCorner(summaryRows);
plotSummary(summaryRows, plotFolder);

writetable(pointRows, fullfile(outputFolder, 'raw_branch_corner_points.csv'));
writetable(summaryRows, fullfile(outputFolder, 'raw_branch_corner_summary.csv'));
writetable(branchRows, fullfile(outputFolder, 'raw_branch_corner_branches.csv'));
writetable(configs, fullfile(outputFolder, 'raw_branch_corner_configs.csv'));
writetable(aggregate, fullfile(outputFolder, 'raw_branch_corner_aggregate.csv'));
save(fullfile(outputFolder, 'raw_branch_corner_workspace.mat'), ...
    'pointRows', 'summaryRows', 'branchRows', 'configs', 'aggregate', 'caseResults', ...
    'caseParams', 'settings', 'state', 'atlasResult', 'identityResult', 'referenceLabel', 'launchFolder', '-v7.3');

fprintf('\nCorner summary\n');
disp(summaryRows);
fprintf('\nCorner aggregate\n');
disp(aggregate);
fprintf('\nData files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGORawBranchCornerSummary', summaryRows);
assignin('base', 'AcoustoelasticIOPHGORawBranchCornerAggregate', aggregate);
assignin('base', 'AcoustoelasticIOPHGORawBranchCornerOutputFolder', outputFolder);

function params = defaultCornerParams()
params = struct();
params.IOP_mmHg = 35;
params.R = 7.8e-3;
params.thickness = 550e-6;
params.mu = 25e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = [];
end

function settings = defaultCornerSettings()
settings = struct();
settings.frequency = logspace(log10(100), log10(35e3), 160);
settings.RelativeMismatchThreshold = 0.05;
settings.ConsecutiveMismatchPoints = 3;
settings.MinimumRawCoverageFraction = 0.80;
settings.MaximumRawMedianRank = 8;
settings.AlignmentMedianThreshold = 0.05;
settings.AlignmentMaxThreshold = 0.10;
settings.ReferenceMedianThreshold = 0.05;
settings.ReferenceMaxThreshold = 0.15;
settings.AtlasNumYPoints = 1000;
settings.AtlasTopNMinima = 18;
end

function configs = makeCornerConfigs()
rows = [];
rows = addConfig(rows, 'base',       900,  16, 0.075, 10);
rows = addConfig(rows, 'strict_jump',900,  16, 0.050, 10);
rows = addConfig(rows, 'loose_jump', 900,  16, 0.110, 10);
rows = addConfig(rows, 'top24',      900,  24, 0.075, 10);
rows = addConfig(rows, 'top32',      900,  32, 0.075, 10);
rows = addConfig(rows, 'fine1400',   1400, 16, 0.075, 10);
rows = addConfig(rows, 'fine_top24', 1400, 24, 0.075, 10);
rows = addConfig(rows, 'fine_loose', 1400, 24, 0.110, 10);
rows = addConfig(rows, 'coarse600',  600,  16, 0.075, 10);
configs = struct2table(rows);
configs.ConfigLabel = string(configs.ConfigLabel);
end

function rows = addConfig(rows, label, numY, topN, maxJump, minBranchPoints)
row = struct();
row.ConfigLabel = label;
row.NumY = numY;
row.YMin = 0.003;
row.YMax = 2.0;
row.TopNMinimaPerFrequency = topN;
row.MaxLogYJumpForRawBranch = maxJump;
row.MinRawBranchPoints = minBranchPoints;
if isempty(rows)
    rows = row;
else
    rows(end+1, 1) = row; %#ok<AGROW>
end
end

function solverOptions = defaultSolverOptions(settings)
solverOptions = defaultAcoustoelasticIOPHGOOptions();
solverOptions.M54_variant = "corrected";
solverOptions.normalizeRows = false;
solverOptions.usePhysicalCpWindow = false;
solverOptions.atlasNumYPoints = settings.AtlasNumYPoints;
solverOptions.atlasTopNMinima = settings.AtlasTopNMinima;
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

function rawAtlas = computeRawModalAtlas(params, config)
rawOptions = defaultAcoustoelasticIOPHGOOptions();
rawOptions.M54_variant = "corrected";
rawOptions.normalizeRows = false;
rawOptions.branch = "A0";
rawOptions.trackingDirection = "backward";
rawOptions.trackingMethod = "globalScan";
rawOptions.minDimensionlessFrequency = 0.0;
rawOptions.usePhysicalCpWindow = false;

freq = params.frequency(:).';
yGrid = logspace(log10(config.YMin), log10(config.YMax), config.NumY);
cShear = sqrt(params.alpha / params.rho);
cGrid = yGrid(:) * cShear;
objectiveMap = nan(numel(yGrid), numel(freq));
rows = [];

for k = 1:numel(freq)
    f = freq(k);
    for j = 1:numel(cGrid)
        objectiveMap(j, k) = objectiveAcoustoelasticResidual(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cGrid(j), rawOptions);
    end
    minima = findTopLocalMinima(cGrid, objectiveMap(:, k), cShear, config.TopNMinimaPerFrequency);
    for m = 1:height(minima)
        row = struct();
        row.Frequency_Hz = f;
        row.Frequency_kHz = f / 1e3;
        row.MinRank = m;
        row.Cp_mps = minima.Cp_mps(m);
        row.y = minima.y(m);
        row.log10y = log10(minima.y(m));
        row.Objective = minima.Objective(m);
        row.DepthRelativeToMedian = minima.DepthRelativeToMedian(m);
        row.DepthRelativeToDeepest = minima.DepthRelativeToDeepest(m);
        row.SpacingToNearestLogY = minima.SpacingToNearestLogY(m);
        row.BranchID = nan;
        rows = [rows; row]; %#ok<AGROW>
    end
end

if isempty(rows)
    minimaTable = table();
    branchTable = table();
else
    minimaTable = struct2table(rows);
    [minimaTable, branchTable] = linkMinimaIntoBranches(minimaTable, config.MaxLogYJumpForRawBranch, config.MinRawBranchPoints);
end

rawAtlas = struct();
rawAtlas.frequency = freq;
rawAtlas.yGrid = yGrid(:);
rawAtlas.cGrid = cGrid(:);
rawAtlas.cShear = cShear;
rawAtlas.objectiveMap = objectiveMap;
rawAtlas.minimaTable = minimaTable;
rawAtlas.branchTable = branchTable;
rawAtlas.options = rawOptions;
end

function minima = findTopLocalMinima(cGrid, obj, cShear, topN)
idx = [];
for k = 2:numel(obj)-1
    if isfinite(obj(k-1)) && isfinite(obj(k)) && isfinite(obj(k+1)) && obj(k) <= obj(k-1) && obj(k) <= obj(k+1)
        idx(end+1) = k; %#ok<AGROW>
    end
end
if isempty(idx)
    minima = table([], [], [], [], [], [], 'VariableNames', ...
        {'Cp_mps','y','Objective','DepthRelativeToMedian','DepthRelativeToDeepest','SpacingToNearestLogY'});
    return;
end
cp = cGrid(idx(:));
y = cp ./ cShear;
objective = obj(idx(:));
finiteObj = obj(isfinite(obj));
medianObj = median(finiteObj, 'omitnan');
deepest = min(objective, [], 'omitnan');
depthRelMedian = medianObj - objective;
depthRelDeepest = objective - deepest;
logY = log10(y);
spacing = nan(size(logY));
for i = 1:numel(logY)
    other = logY;
    other(i) = [];
    if isempty(other)
        spacing(i) = inf;
    else
        spacing(i) = min(abs(logY(i) - other));
    end
end
[objective, order] = sort(objective, 'ascend');
cp = cp(order);
y = y(order);
depthRelMedian = depthRelMedian(order);
depthRelDeepest = depthRelDeepest(order);
spacing = spacing(order);
keep = 1:min(topN, numel(cp));
minima = table(cp(keep), y(keep), objective(keep), depthRelMedian(keep), depthRelDeepest(keep), spacing(keep), ...
    'VariableNames', {'Cp_mps','y','Objective','DepthRelativeToMedian','DepthRelativeToDeepest','SpacingToNearestLogY'});
end

function [minimaTable, branchTable] = linkMinimaIntoBranches(minimaTable, maxLogYJump, minBranchPoints)
minimaTable = sortrows(minimaTable, {'Frequency_Hz','MinRank'});
minimaTable.BranchID(:) = nan;
lastLogY = [];
lastFreq = [];
branchID = 0;
freqList = unique(minimaTable.Frequency_Hz, 'stable');
for k = 1:numel(freqList)
    f = freqList(k);
    rows = find(minimaTable.Frequency_Hz == f);
    used = false(1, max(branchID, 1));
    for ii = 1:numel(rows)
        r = rows(ii);
        best = nan;
        bestScore = inf;
        for b = 1:branchID
            if b <= numel(used) && used(b), continue; end
            if lastFreq(b) >= f, continue; end
            jump = abs(minimaTable.log10y(r) - lastLogY(b));
            if jump > maxLogYJump, continue; end
            score = jump + 0.02 * minimaTable.MinRank(r);
            if score < bestScore
                bestScore = score;
                best = b;
            end
        end
        if isnan(best)
            branchID = branchID + 1;
            best = branchID;
            used(best) = false;
        end
        minimaTable.BranchID(r) = best;
        lastLogY(best) = minimaTable.log10y(r); %#ok<AGROW>
        lastFreq(best) = f; %#ok<AGROW>
        used(best) = true;
    end
end
branchTable = buildBranchTable(minimaTable, minBranchPoints);
end

function branchTable = buildBranchTable(minimaTable, minBranchPoints)
branchRows = [];
branchIDs = unique(minimaTable.BranchID(isfinite(minimaTable.BranchID)), 'stable');
for i = 1:numel(branchIDs)
    id = branchIDs(i);
    T = sortrows(minimaTable(minimaTable.BranchID == id, :), 'Frequency_Hz');
    if height(T) < minBranchPoints
        continue;
    end
    row = struct();
    row.BranchID = id;
    row.NumPoints = height(T);
    row.FrequencyStart_Hz = min(T.Frequency_Hz);
    row.FrequencyEnd_Hz = max(T.Frequency_Hz);
    row.FrequencyStart_kHz = row.FrequencyStart_Hz / 1e3;
    row.FrequencyEnd_kHz = row.FrequencyEnd_Hz / 1e3;
    row.FrequencyCoverage_kHz = row.FrequencyEnd_kHz - row.FrequencyStart_kHz;
    row.CpStart_mps = T.Cp_mps(1);
    row.CpEnd_mps = T.Cp_mps(end);
    row.YStart = T.y(1);
    row.YEnd = T.y(end);
    row.StartRank = T.MinRank(1);
    row.EndRank = T.MinRank(end);
    row.MedianRank = median(T.MinRank, 'omitnan');
    row.MedianY = median(T.y, 'omitnan');
    row.MinCp_mps = min(T.Cp_mps);
    row.MaxCp_mps = max(T.Cp_mps);
    row.MedianCp_mps = median(T.Cp_mps, 'omitnan');
    row.MedianObjective = median(T.Objective, 'omitnan');
    row.MedianSpacingToNearestLogY = median(T.SpacingToNearestLogY, 'omitnan');
    row.NetCpIncrease_mps = T.Cp_mps(end) - T.Cp_mps(1);
    row.Roughness = branchRoughness(T.Cp_mps);
    branchRows = [branchRows; row]; %#ok<AGROW>
end
if isempty(branchRows)
    branchTable = table();
else
    branchTable = struct2table(branchRows);
end
end

function value = branchRoughness(cp)
if numel(cp) < 3
    value = nan;
else
    value = median(abs(diff(cp, 2)), 'omitnan') / max(median(abs(cp), 'omitnan'), eps);
end
end

function [branch, points] = selectRawBranch(branchTable, minimaTable)
if isempty(branchTable)
    branch = table();
    points = table();
    return;
end
coverage = normalizeMetric(branchTable.FrequencyCoverage_kHz);
roughness = normalizeMetric(branchTable.Roughness);
rank = normalizeMetric(branchTable.MedianRank);
y = normalizeMetric(branchTable.MedianY);
increase = normalizeMetric(branchTable.NetCpIncrease_mps);
score = -1.4*coverage + 1.2*roughness + 0.7*rank + 0.35*y - 0.5*increase;
[~, idx] = min(score);
branch = branchTable(idx, :);
branch.SelectionScore = score(idx);
points = sortrows(minimaTable(minimaTable.BranchID == branch.BranchID, :), 'Frequency_Hz');
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

function T = addContextColumns(T, config, caseParams, state)
if isempty(T)
    return;
end
n = height(T);
T.ConfigLabel = repmat(string(config.ConfigLabel), n, 1);
T.NumY = repmat(config.NumY, n, 1);
T.TopNMinimaPerFrequency = repmat(config.TopNMinimaPerFrequency, n, 1);
T.MaxLogYJumpForRawBranch = repmat(config.MaxLogYJumpForRawBranch, n, 1);
T.IOP_mmHg = repmat(caseParams.IOP_mmHg, n, 1);
T.Mu_kPa = repmat(caseParams.mu / 1e3, n, 1);
T.K1_kPa = repmat(caseParams.k1 / 1e3, n, 1);
T.K2 = repmat(caseParams.k2, n, 1);
T.Thickness_um = repmat(caseParams.thickness * 1e6, n, 1);
T.LambdaTheta = repmat(getStateValue(state, 'lambdaTheta'), n, 1);
T.SigmaTheta_kPa = repmat(getStateValue(state, 'sigmaTheta') / 1e3, n, 1);
end

function value = getStateValue(state, name)
if isfield(state, name)
    value = state.(name);
else
    value = nan;
end
end

function comparison = compareConfig(config, caseParams, rawPoints, refRawPoints, atlasResult, identityResult, settings)
f = atlasResult.frequency(:);
[rawCp, rawValid, rawRank] = assignRawBranchToFrequency(f, rawPoints);
[refCp, refValid, ~] = assignRawBranchToFrequency(f, refRawPoints);

atlasCp = atlasResult.Cp(:);
atlasValid = logical(atlasResult.validCp(:)) & isfinite(atlasCp);
identityCp = nan(size(f));
identityValid = false(size(f));
if isfield(identityResult, 'identityA0')
    identityCp = identityResult.identityA0.CpCandidate(:);
    identityValid = logical(identityResult.identityA0.validCandidate(:)) & isfinite(identityCp);
end

[atlasErr, atlasOverlap, atlasMismatch] = relativeError(rawCp, rawValid, atlasCp, atlasValid, settings.RelativeMismatchThreshold);
[identityErr, identityOverlap, identityMismatch] = relativeError(rawCp, rawValid, identityCp, identityValid, settings.RelativeMismatchThreshold);
[refErr, refOverlap, refMismatch] = relativeError(refCp, refValid, rawCp, rawValid, settings.RelativeMismatchThreshold);

firstAtlasMismatch = firstConsecutiveMismatch(f, atlasMismatch, settings.ConsecutiveMismatchPoints);
firstIdentityMismatch = firstConsecutiveMismatch(f, identityMismatch, settings.ConsecutiveMismatchPoints);
firstRefMismatch = firstConsecutiveMismatch(f, refMismatch, settings.ConsecutiveMismatchPoints);

points = table();
points.ConfigLabel = repmat(string(config.ConfigLabel), numel(f), 1);
points.IOP_mmHg = repmat(caseParams.IOP_mmHg, numel(f), 1);
points.Mu_kPa = repmat(caseParams.mu / 1e3, numel(f), 1);
points.Frequency_Hz = f;
points.Frequency_kHz = f ./ 1e3;
points.RawCp_mps = rawCp(:);
points.RawValid = rawValid(:);
points.RawRank = rawRank(:);
points.ReferenceRawCp_mps = refCp(:);
points.ReferenceRawValid = refValid(:);
points.ReferenceRawRelError = refErr(:);
points.ReferenceRawMismatch = refMismatch(:);
points.AtlasCp_mps = atlasCp(:);
points.AtlasValid = atlasValid(:);
points.AtlasRawRelError = atlasErr(:);
points.AtlasRawMismatch = atlasMismatch(:);
points.IdentityCp_mps = identityCp(:);
points.IdentityValid = identityValid(:);
points.IdentityRawRelError = identityErr(:);
points.IdentityRawMismatch = identityMismatch(:);

summary = table();
summary.ConfigLabel = string(config.ConfigLabel);
summary.IOP_mmHg = caseParams.IOP_mmHg;
summary.Mu_kPa = caseParams.mu / 1e3;
summary.NumY = config.NumY;
summary.TopNMinimaPerFrequency = config.TopNMinimaPerFrequency;
summary.MaxLogYJumpForRawBranch = config.MaxLogYJumpForRawBranch;
summary.FrequencyPoints = numel(f);
summary.RawValidPoints = nnz(rawValid);
summary.RawValidFraction = nnz(rawValid) / max(numel(f), 1);
summary.RawMedianRank = median(rawRank(rawValid), 'omitnan');
summary.AtlasValidPoints = nnz(atlasValid);
summary.AtlasValidFraction = nnz(atlasValid) / max(numel(f), 1);
summary.IdentityValidPoints = nnz(identityValid);
summary.IdentityValidFraction = nnz(identityValid) / max(numel(f), 1);
summary.AtlasRawValidOverlapFraction = nnz(atlasOverlap) / max(nnz(rawValid), 1);
summary.IdentityRawValidOverlapFraction = nnz(identityOverlap) / max(nnz(rawValid), 1);
summary.ReferenceRawValidOverlapFraction = nnz(refOverlap) / max(nnz(refValid), 1);
summary.FirstAtlasRawMismatchFrequency_kHz = firstAtlasMismatch / 1e3;
summary.FirstIdentityRawMismatchFrequency_kHz = firstIdentityMismatch / 1e3;
summary.FirstReferenceRawMismatchFrequency_kHz = firstRefMismatch / 1e3;
summary.MedianAtlasRawRelError = median(atlasErr(atlasOverlap), 'omitnan');
summary.MedianIdentityRawRelError = median(identityErr(identityOverlap), 'omitnan');
summary.MedianReferenceRawRelError = median(refErr(refOverlap), 'omitnan');
summary.MaxAtlasRawRelError = maxWithNaN(atlasErr(atlasOverlap));
summary.MaxIdentityRawRelError = maxWithNaN(identityErr(identityOverlap));
summary.MaxReferenceRawRelError = maxWithNaN(refErr(refOverlap));
summary.IdentityAddedPoints = nnz(identityValid & ~atlasValid);
summary.Classification = classifyCorner(summary, firstAtlasMismatch, firstIdentityMismatch, firstRefMismatch, settings);

comparison = struct();
comparison.points = points;
comparison.summary = summary;
end

function [rawCp, rawValid, rawRank] = assignRawBranchToFrequency(f, rawPoints)
rawCp = nan(size(f));
rawRank = nan(size(f));
rawValid = false(size(f));
if isempty(rawPoints)
    return;
end
[tf, loc] = ismember(f, rawPoints.Frequency_Hz);
rawCp(tf) = rawPoints.Cp_mps(loc(tf));
rawRank(tf) = rawPoints.MinRank(loc(tf));
rawValid(tf) = isfinite(rawCp(tf));
end

function [err, overlap, mismatch] = relativeError(referenceCp, referenceValid, candidateCp, candidateValid, threshold)
overlap = referenceValid(:) & candidateValid(:) & isfinite(referenceCp(:)) & isfinite(candidateCp(:));
err = nan(size(referenceCp(:)));
err(overlap) = abs(candidateCp(overlap) - referenceCp(overlap)) ./ max(abs(referenceCp(overlap)), eps);
mismatch = false(size(referenceCp(:)));
mismatch(overlap) = err(overlap) > threshold;
end

function fFirst = firstConsecutiveMismatch(f, mismatch, consecutivePoints)
fFirst = nan;
runCount = 0;
for k = 1:numel(mismatch)
    if mismatch(k)
        runCount = runCount + 1;
        if runCount >= consecutivePoints
            fFirst = f(k - consecutivePoints + 1);
            return;
        end
    else
        runCount = 0;
    end
end
end

function classification = classifyCorner(summary, firstAtlasMismatch, firstIdentityMismatch, firstRefMismatch, settings)
rawWeak = summary.RawValidFraction < settings.MinimumRawCoverageFraction || ...
    (isfinite(summary.RawMedianRank) && summary.RawMedianRank > settings.MaximumRawMedianRank);
refUnstable = ~isnan(firstRefMismatch) || ...
    summary.MedianReferenceRawRelError > settings.ReferenceMedianThreshold || ...
    summary.MaxReferenceRawRelError > settings.ReferenceMaxThreshold;
atlasAligned = isnan(firstAtlasMismatch) && ...
    summary.MedianAtlasRawRelError <= settings.AlignmentMedianThreshold && ...
    summary.MaxAtlasRawRelError <= settings.AlignmentMaxThreshold;
identityAligned = isnan(firstIdentityMismatch) && ...
    summary.MedianIdentityRawRelError <= settings.AlignmentMedianThreshold && ...
    summary.MaxIdentityRawRelError <= settings.AlignmentMaxThreshold;

if rawWeak && refUnstable
    classification = "raw_weak_and_selection_sensitive";
elseif rawWeak
    classification = "raw_branch_weak";
elseif refUnstable
    classification = "raw_selection_sensitive";
elseif atlasAligned && identityAligned
    classification = "stable_raw_and_aligned";
elseif atlasAligned
    classification = "stable_raw_atlas_aligned";
else
    classification = "atlas_mismatch_or_unresolved";
end
end

function value = maxWithNaN(x)
if isempty(x) || ~any(isfinite(x))
    value = nan;
else
    value = max(x, [], 'omitnan');
end
end

function aggregate = summarizeCorner(S)
if isempty(S)
    aggregate = table();
    return;
end
aggregate = table();
aggregate.Configurations = height(S);
aggregate.MinRawValidFraction = min(S.RawValidFraction, [], 'omitnan');
aggregate.MedianRawValidFraction = median(S.RawValidFraction, 'omitnan');
aggregate.MaxRawValidFraction = max(S.RawValidFraction, [], 'omitnan');
aggregate.MedianRawMedianRank = median(S.RawMedianRank, 'omitnan');
aggregate.MinAtlasRawOverlapFraction = min(S.AtlasRawValidOverlapFraction, [], 'omitnan');
aggregate.MedianAtlasRawRelError = median(S.MedianAtlasRawRelError, 'omitnan');
aggregate.MedianReferenceRawRelError = median(S.MedianReferenceRawRelError, 'omitnan');
aggregate.MaxReferenceRawRelError = max(S.MaxReferenceRawRelError, [], 'omitnan');
aggregate.ConfigsWithRawWeakness = nnz(S.RawValidFraction < 0.80 | S.RawMedianRank > 8);
aggregate.ConfigsWithReferenceMismatch = nnz(~isnan(S.FirstReferenceRawMismatchFrequency_kHz));
end

function plotConfigComparison(points, configLabel, plotFolder)
figure('Color', 'w', 'Name', configLabel);
hold on; grid on;
plot(points.Frequency_kHz, points.RawCp_mps, '-', 'LineWidth', 2.4, 'DisplayName', 'selected raw_branch1');
plot(points.Frequency_kHz, points.ReferenceRawCp_mps, '--', 'LineWidth', 1.8, 'DisplayName', 'base raw reference');
plot(points.Frequency_kHz, points.AtlasCp_mps, ':', 'LineWidth', 1.8, 'DisplayName', 'atlasA0 official');
plot(points.Frequency_kHz, points.IdentityCp_mps, '-.', 'LineWidth', 1.8, 'DisplayName', 'identityA0 diagnostic');
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title(sprintf('%s: raw branch corner comparison', configLabel), 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
hold off;
saveas(gcf, fullfile(plotFolder, sprintf('%s.png', configLabel)));
saveas(gcf, fullfile(plotFolder, sprintf('%s.fig', configLabel)));
end

function plotSummary(S, plotFolder)
if isempty(S)
    return;
end
figure('Color', 'w', 'Name', 'raw branch corner coverage');
hold on; grid on;
plot(1:height(S), S.RawValidFraction, '-o', 'LineWidth', 1.5, 'DisplayName', 'raw valid fraction');
plot(1:height(S), S.AtlasRawValidOverlapFraction, '-s', 'LineWidth', 1.5, 'DisplayName', 'atlas/raw overlap fraction');
plot(1:height(S), S.ReferenceRawValidOverlapFraction, '-d', 'LineWidth', 1.5, 'DisplayName', 'raw/base overlap fraction');
xticks(1:height(S));
xticklabels(S.ConfigLabel);
xtickangle(35);
ylabel('fraction');
title('Raw branch corner coverage sensitivity', 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
hold off;
saveas(gcf, fullfile(plotFolder, 'raw_branch_corner_coverage.png'));
saveas(gcf, fullfile(plotFolder, 'raw_branch_corner_coverage.fig'));

figure('Color', 'w', 'Name', 'raw branch corner relative errors');
hold on; grid on;
plot(1:height(S), S.MedianAtlasRawRelError, '-o', 'LineWidth', 1.5, 'DisplayName', 'median atlas/raw');
plot(1:height(S), S.MedianIdentityRawRelError, '-s', 'LineWidth', 1.5, 'DisplayName', 'median identity/raw');
plot(1:height(S), S.MedianReferenceRawRelError, '-d', 'LineWidth', 1.5, 'DisplayName', 'median raw/base');
xticks(1:height(S));
xticklabels(S.ConfigLabel);
xtickangle(35);
ylabel('relative error');
title('Raw branch corner error sensitivity', 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
hold off;
saveas(gcf, fullfile(plotFolder, 'raw_branch_corner_relative_errors.png'));
saveas(gcf, fullfile(plotFolder, 'raw_branch_corner_relative_errors.fig'));
end
