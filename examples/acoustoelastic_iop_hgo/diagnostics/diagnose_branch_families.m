clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_BRANCH_FAMILIES Diagnose competing branch families in the difficult corner.
%
% Diagnostic only. This script focuses on IOP = 35 mmHg, mu = 25 kPa and
% ranks several persistent raw-atlas branches instead of selecting a single
% raw_branch1. It does not modify result.Cp or result.validCp.
%
% Outputs:
%   Results/ae_iop_hgo/branch_families

outputFolder = aeOutputFolder(launchFolder, 'branch_families');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

params = defaultCaseParams();
settings = defaultSettings();
configs = makeConfigs();
params.IOP = params.IOP_mmHg * 133.322;
params.frequency = settings.frequency;

atlasOptions = defaultSolverOptions(settings);
atlasOptions.atlasBranchPolicy = "atlasA0";
atlasResult = solveAcoustoelasticIOPHGOBranch(params, atlasOptions);

identityOptions = atlasOptions;
identityOptions.atlasBranchPolicy = "identityA0Diagnostic";
identityResult = solveAcoustoelasticIOPHGOBranch(params, identityOptions);

[directParams, state] = buildDirectParamsFromIOP(params);

familyRows = table();
pointRows = table();
caseResults = struct();

fprintf('\ncompeting branch families diagnostic\n');
fprintf('Case: IOP %.0f mmHg, mu %.0f kPa, k1 %.0f kPa, k2 %.0f, h %.0f um\n', ...
    params.IOP_mmHg, params.mu/1e3, params.k1/1e3, params.k2, params.thickness*1e6);

for i = 1:height(configs)
    config = configs(i, :);
    fprintf('Config %d/%d: %s\n', i, height(configs), char(config.ConfigLabel));

    rawAtlas = computeRawAtlas(directParams, config);
    families = rankFamilies(rawAtlas.branchTable, rawAtlas.minimaTable, config, params, state, settings);

    for j = 1:height(families)
        branchPoints = rawAtlas.minimaTable(rawAtlas.minimaTable.BranchID == families.BranchID(j), :);
        branchPoints = compareFamilyPoints(sortrows(branchPoints, 'Frequency_Hz'), families(j, :), atlasResult, identityResult, settings);
        pointRows = [pointRows; branchPoints]; %#ok<AGROW>
    end

    familyRows = [familyRows; families]; %#ok<AGROW>
    caseResults(i).ConfigLabel = config.ConfigLabel; %#ok<SAGROW>
    caseResults(i).config = config;
    caseResults(i).rawAtlas = rawAtlas;
    caseResults(i).families = families;

    fprintf('  retained families: %d | best coverage %.3f | best median rank %.3g\n', ...
        height(families), families.FrequencyCoverageFraction(1), families.MedianRank(1));
end

aggregate = summarizeFamilies(familyRows);

writetable(familyRows, fullfile(outputFolder, 'branch_families_summary.csv'));
writetable(pointRows, fullfile(outputFolder, 'branch_families_points.csv'));
writetable(aggregate, fullfile(outputFolder, 'branch_families_aggregate.csv'));
writetable(configs, fullfile(outputFolder, 'branch_families_configs.csv'));
save(fullfile(outputFolder, 'branch_families_workspace.mat'), ...
    'familyRows', 'pointRows', 'aggregate', 'configs', 'caseResults', ...
    'params', 'settings', 'state', 'atlasResult', 'identityResult', 'launchFolder', '-v7.3');

fprintf('\nBranch family summary\n');
disp(familyRows);
fprintf('\nAggregate\n');
disp(aggregate);
fprintf('\nData files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOBranchFamiliesSummary', familyRows);
assignin('base', 'AcoustoelasticIOPHGOBranchFamiliesAggregate', aggregate);
assignin('base', 'AcoustoelasticIOPHGOBranchFamiliesOutputFolder', outputFolder);

function params = defaultCaseParams()
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

function settings = defaultSettings()
settings = struct();
settings.frequency = logspace(log10(100), log10(35e3), 160);
settings.MaxFamiliesToReport = 5;
settings.RelativeMismatchThreshold = 0.05;
settings.AtlasNumYPoints = 1000;
settings.AtlasTopNMinima = 18;
end

function configs = makeConfigs()
rows = [];
rows = addConfig(rows, 'base', 900, 16, 0.075, 10);
rows = addConfig(rows, 'top24', 900, 24, 0.075, 10);
rows = addConfig(rows, 'top32', 900, 32, 0.075, 10);
rows = addConfig(rows, 'fine_top24', 1400, 24, 0.075, 10);
rows = addConfig(rows, 'fine_loose', 1400, 24, 0.110, 10);
configs = struct2table(rows);
configs.ConfigLabel = string(configs.ConfigLabel);
end

function rows = addConfig(rows, label, numY, topN, maxJump, minPoints)
row = struct();
row.ConfigLabel = label;
row.NumY = numY;
row.YMin = 0.003;
row.YMax = 2.0;
row.TopNMinimaPerFrequency = topN;
row.MaxLogYJumpForRawBranch = maxJump;
row.MinBranchPoints = minPoints;
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

function rawAtlas = computeRawAtlas(params, config)
rawOptions = defaultAcoustoelasticIOPHGOOptions();
rawOptions.M54_variant = "corrected";
rawOptions.normalizeRows = false;
rawOptions.usePhysicalCpWindow = false;
rawOptions.minDimensionlessFrequency = 0.0;

freq = params.frequency(:).';
yGrid = logspace(log10(config.YMin), log10(config.YMax), config.NumY);
cShear = sqrt(params.alpha / params.rho);
cGrid = yGrid(:) * cShear;
rows = [];

for k = 1:numel(freq)
    obj = nan(numel(cGrid), 1);
    for j = 1:numel(cGrid)
        obj(j) = objectiveAcoustoelasticResidual(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, freq(k), cGrid(j), rawOptions);
    end
    minima = findMinima(cGrid, obj, cShear, config.TopNMinimaPerFrequency);
    for m = 1:height(minima)
        row = struct();
        row.Frequency_Hz = freq(k);
        row.Frequency_kHz = freq(k) / 1e3;
        row.MinRank = m;
        row.Cp_mps = minima.Cp_mps(m);
        row.y = minima.y(m);
        row.log10y = log10(minima.y(m));
        row.Objective = minima.Objective(m);
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
    [minimaTable, branchTable] = linkBranches(minimaTable, config.MaxLogYJumpForRawBranch, config.MinBranchPoints);
end
rawAtlas = struct('frequency', freq, 'yGrid', yGrid(:), 'cGrid', cGrid(:), ...
    'minimaTable', minimaTable, 'branchTable', branchTable, 'options', rawOptions);
end

function minima = findMinima(cGrid, obj, cShear, topN)
idx = [];
for k = 2:numel(obj)-1
    if isfinite(obj(k-1)) && isfinite(obj(k)) && isfinite(obj(k+1)) && obj(k) <= obj(k-1) && obj(k) <= obj(k+1)
        idx(end+1) = k; %#ok<AGROW>
    end
end
if isempty(idx)
    minima = table([], [], [], [], 'VariableNames', {'Cp_mps','y','Objective','SpacingToNearestLogY'});
    return;
end
cp = cGrid(idx(:));
y = cp ./ cShear;
objective = obj(idx(:));
logY = log10(y);
spacing = nan(size(logY));
for i = 1:numel(logY)
    other = logY;
    other(i) = [];
    spacing(i) = min(abs(logY(i) - other));
end
[objective, order] = sort(objective, 'ascend');
cp = cp(order);
y = y(order);
spacing = spacing(order);
keep = 1:min(topN, numel(cp));
minima = table(cp(keep), y(keep), objective(keep), spacing(keep), ...
    'VariableNames', {'Cp_mps','y','Objective','SpacingToNearestLogY'});
end

function [minimaTable, branchTable] = linkBranches(minimaTable, maxJump, minPoints)
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
            if jump > maxJump, continue; end
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
branchTable = buildBranchTable(minimaTable, minPoints);
end

function branchTable = buildBranchTable(minimaTable, minPoints)
branchRows = [];
freqCount = numel(unique(minimaTable.Frequency_Hz));
ids = unique(minimaTable.BranchID(isfinite(minimaTable.BranchID)), 'stable');
for i = 1:numel(ids)
    T = sortrows(minimaTable(minimaTable.BranchID == ids(i), :), 'Frequency_Hz');
    if height(T) < minPoints
        continue;
    end
    row = struct();
    row.BranchID = ids(i);
    row.NumPoints = height(T);
    row.FrequencyCoverageFraction = height(T) / freqCount;
    row.FrequencyStart_kHz = min(T.Frequency_Hz) / 1e3;
    row.FrequencyEnd_kHz = max(T.Frequency_Hz) / 1e3;
    row.MedianRank = median(T.MinRank, 'omitnan');
    row.MedianY = median(T.y, 'omitnan');
    row.MedianCp_mps = median(T.Cp_mps, 'omitnan');
    row.MinCp_mps = min(T.Cp_mps);
    row.MaxCp_mps = max(T.Cp_mps);
    row.Roughness = branchRoughness(T.Cp_mps);
    row.MedianObjective = median(T.Objective, 'omitnan');
    row.MedianSpacingToNearestLogY = median(T.SpacingToNearestLogY, 'omitnan');
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

function families = rankFamilies(branchTable, minimaTable, config, params, state, settings) %#ok<INUSD>
if isempty(branchTable)
    families = table();
    return;
end
coverage = normalizeMetric(branchTable.FrequencyCoverageFraction);
roughness = normalizeMetric(branchTable.Roughness);
rank = normalizeMetric(branchTable.MedianRank);
spacing = normalizeMetric(-branchTable.MedianSpacingToNearestLogY);
score = -1.8*coverage + 1.2*roughness + 0.8*rank + 0.3*spacing;
branchTable.FamilyScore = score;
[~, order] = sort(score, 'ascend');
keep = order(1:min(settings.MaxFamiliesToReport, numel(order)));
families = sortrows(branchTable(keep, :), 'FamilyScore');
families.FamilyRank = (1:height(families)).';
families.ConfigLabel = repmat(string(config.ConfigLabel), height(families), 1);
families.NumY = repmat(config.NumY, height(families), 1);
families.TopNMinimaPerFrequency = repmat(config.TopNMinimaPerFrequency, height(families), 1);
families.MaxLogYJumpForRawBranch = repmat(config.MaxLogYJumpForRawBranch, height(families), 1);
families.IOP_mmHg = repmat(params.IOP_mmHg, height(families), 1);
families.Mu_kPa = repmat(params.mu/1e3, height(families), 1);
families.SigmaTheta_kPa = repmat(getStateValue(state, 'sigma')/1e3, height(families), 1);
families.LambdaTheta = repmat(getStateValue(state, 'lambda'), height(families), 1);
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

function value = getStateValue(state, name)
if isfield(state, name)
    value = state.(name);
else
    value = nan;
end
end

function points = compareFamilyPoints(branchPoints, familyRow, atlasResult, identityResult, settings)
f = atlasResult.frequency(:);
[rawCp, rawValid, rawRank] = assignToFrequency(f, branchPoints);
atlasCp = atlasResult.Cp(:);
atlasValid = logical(atlasResult.validCp(:)) & isfinite(atlasCp);
[identityCp, identityValid] = identityCandidateOnFrequencyGrid(identityResult, f);
[atlasErr, atlasOverlap] = relativeError(rawCp, rawValid, atlasCp, atlasValid, settings.RelativeMismatchThreshold);
[identityErr, identityOverlap] = relativeError(rawCp, rawValid, identityCp, identityValid, settings.RelativeMismatchThreshold);
points = table();
points.ConfigLabel = repmat(string(familyRow.ConfigLabel), numel(f), 1);
points.FamilyRank = repmat(familyRow.FamilyRank, numel(f), 1);
points.BranchID = repmat(familyRow.BranchID, numel(f), 1);
points.Frequency_Hz = f;
points.Frequency_kHz = f ./ 1e3;
points.RawCp_mps = rawCp(:);
points.RawValid = rawValid(:);
points.RawRank = rawRank(:);
points.AtlasCp_mps = atlasCp(:);
points.AtlasValid = atlasValid(:);
points.AtlasRawRelError = atlasErr(:);
points.AtlasRawOverlap = atlasOverlap(:);
points.IdentityCp_mps = identityCp(:);
points.IdentityValid = identityValid(:);
points.IdentityRawRelError = identityErr(:);
points.IdentityRawOverlap = identityOverlap(:);
end

function [cp, valid, rank] = assignToFrequency(f, points)
cp = nan(size(f));
rank = nan(size(f));
valid = false(size(f));
if isempty(points), return; end
[tf, loc] = ismember(f, points.Frequency_Hz);
cp(tf) = points.Cp_mps(loc(tf));
rank(tf) = points.MinRank(loc(tf));
valid(tf) = isfinite(cp(tf));
end

function [cp, valid] = identityCandidateOnFrequencyGrid(identityResult, f)
f = f(:);
cp = nan(size(f));
valid = false(size(f));

if ~isstruct(identityResult) || ~isfield(identityResult, 'identityA0') || ~isstruct(identityResult.identityA0)
    return;
end

identity = identityResult.identityA0;
if ~isfield(identity, 'CpCandidate') || isempty(identity.CpCandidate)
    return;
end

candidateCp = identity.CpCandidate(:);
if isfield(identity, 'validCandidate') && ~isempty(identity.validCandidate)
    candidateValid = logical(identity.validCandidate(:));
else
    candidateValid = isfinite(candidateCp);
end

candidateFrequency = [];
if isfield(identity, 'frequency') && ~isempty(identity.frequency)
    candidateFrequency = identity.frequency(:);
elseif isfield(identityResult, 'frequency') && ~isempty(identityResult.frequency)
    candidateFrequency = identityResult.frequency(:);
end

if numel(candidateCp) == numel(f) && (isempty(candidateFrequency) || numel(candidateFrequency) ~= numel(candidateCp) || sameFrequencyGrid(candidateFrequency, f))
    cp = candidateCp(:);
    valid = candidateValid(:) & isfinite(cp);
    return;
end

if numel(candidateFrequency) ~= numel(candidateCp)
    warning('diagnose_branch_families:IdentityGridMismatch', ...
        'identityA0Diagnostic candidate length does not match either the output grid or its own frequency grid. Marking identity candidate invalid for this case.');
    return;
end

[candidateFrequency, order] = sort(candidateFrequency(:));
candidateCp = candidateCp(order);
candidateValid = candidateValid(order) & isfinite(candidateCp);

[candidateFrequency, uniqueIdx] = unique(candidateFrequency, 'stable');
candidateCp = candidateCp(uniqueIdx);
candidateValid = candidateValid(uniqueIdx);

candidateCp(~candidateValid) = nan;
cp = interp1(candidateFrequency, candidateCp, f, 'linear', nan);
valid = isfinite(cp);
end

function tf = sameFrequencyGrid(a, b)
a = a(:);
b = b(:);
if numel(a) ~= numel(b)
    tf = false;
    return;
end
tol = 10 * eps(max(1, max(abs([a; b]))));
tf = max(abs(a - b)) <= tol;
end

function [err, overlap] = relativeError(referenceCp, referenceValid, candidateCp, candidateValid, threshold) %#ok<INUSD>
overlap = referenceValid(:) & candidateValid(:) & isfinite(referenceCp(:)) & isfinite(candidateCp(:));
err = nan(size(referenceCp(:)));
err(overlap) = abs(candidateCp(overlap) - referenceCp(overlap)) ./ max(abs(referenceCp(overlap)), eps);
end

function aggregate = summarizeFamilies(familyRows)
if isempty(familyRows)
    aggregate = table();
    return;
end
best = familyRows(familyRows.FamilyRank == 1, :);
aggregate = table();
aggregate.Configurations = numel(unique(familyRows.ConfigLabel));
aggregate.FamiliesReported = height(familyRows);
aggregate.BestFamilyMedianCoverage = median(best.FrequencyCoverageFraction, 'omitnan');
aggregate.BestFamilyMinCoverage = min(best.FrequencyCoverageFraction, [], 'omitnan');
aggregate.BestFamilyMaxCoverage = max(best.FrequencyCoverageFraction, [], 'omitnan');
aggregate.BestFamilyMedianRank = median(best.MedianRank, 'omitnan');
aggregate.ReportedFamiliesWithCoverageAbove080 = nnz(familyRows.FrequencyCoverageFraction >= 0.80);
aggregate.ReportedFamiliesWithMedianRankBelowOrEqual4 = nnz(familyRows.MedianRank <= 4);
aggregate.ReportedFamiliesWithCoverageAbove080AndRankBelowOrEqual4 = nnz(familyRows.FrequencyCoverageFraction >= 0.80 & familyRows.MedianRank <= 4);
end
