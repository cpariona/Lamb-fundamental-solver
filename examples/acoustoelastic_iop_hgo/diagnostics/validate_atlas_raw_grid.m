clear; clc; close all;
launchFolder = pwd;
startup

%VALIDATE_ATLAS_RAW_GRID Compare atlasA0/identityA0 against raw_branch1 over a grid.
%
% Diagnostic only. This script computes a corrected-raw-matrix modal atlas for
% each case, extracts a persistent raw_branch1 candidate, and compares it against
% official atlasA0 and identityA0Diagnostic outputs. It does not promote
% raw_branch1 and does not modify result.Cp or result.validCp.
%
% Outputs:
%   Results/ae_iop_hgo/atlas_vs_raw_branch1_grid

outputFolder = aeOutputFolder(launchFolder, 'atlas_vs_raw_branch1_grid');
plotFolder = fullfile(outputFolder, 'plots');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

cases = makeValidationCases();
settings = defaultGridSettings();

pointRows = table();
summaryRows = table();
rawCurveRows = table();
rawBranchRows = table();
caseResults = struct();

fprintf('\natlasA0 versus raw_branch1 grid diagnostic\n');
fprintf('Cases: %d | frequencies: %d | y-grid: %d\n\n', height(cases), numel(settings.frequency), numel(settings.yGrid));

for i = 1:height(cases)
    params = defaultExampleParams();
    params.IOP = cases.IOP_mmHg(i) * 133.322;
    params.mu = cases.Mu_kPa(i) * 1e3;
    params.k1 = cases.K1_kPa(i) * 1e3;
    params.k2 = cases.K2(i);
    params.thickness = cases.Thickness_um(i) * 1e-6;
    params.frequency = settings.frequency;

    fprintf('Case %d/%d: IOP %.0f mmHg, mu %.0f kPa, k1 %.0f kPa, k2 %.0f, h %.0f um\n', ...
        i, height(cases), cases.IOP_mmHg(i), cases.Mu_kPa(i), cases.K1_kPa(i), cases.K2(i), cases.Thickness_um(i));

    [directParams, state] = buildDirectParamsFromIOP(params);
    rawAtlas = computeRawModalAtlas(directParams, settings);
    [rawBranch, rawPoints] = selectRawBranch(rawAtlas.branchTable, rawAtlas.minimaTable);
    rawPoints = addCaseColumns(rawPoints, cases(i, :), state);
    rawBranch = addCaseColumns(rawBranch, cases(i, :), state);

    atlasOptions = defaultSolverOptions(settings);
    atlasOptions.atlasBranchPolicy = "atlasA0";
    atlasResult = solveAcoustoelasticIOPHGOBranch(params, atlasOptions);

    identityOptions = atlasOptions;
    identityOptions.atlasBranchPolicy = "identityA0Diagnostic";
    identityResult = solveAcoustoelasticIOPHGOBranch(params, identityOptions);

    comparison = compareCase(cases(i, :), rawPoints, atlasResult, identityResult, settings);

    pointRows = [pointRows; comparison.points]; %#ok<AGROW>
    summaryRows = [summaryRows; comparison.summary]; %#ok<AGROW>
    rawCurveRows = [rawCurveRows; rawPoints]; %#ok<AGROW>
    rawBranchRows = [rawBranchRows; rawBranch]; %#ok<AGROW>

    caseResults(i).CaseLabel = cases.CaseLabel(i); %#ok<SAGROW>
    caseResults(i).case = cases(i, :);
    caseResults(i).state = state;
    caseResults(i).rawAtlas = rawAtlas;
    caseResults(i).rawBranch = rawBranch;
    caseResults(i).rawPoints = rawPoints;
    caseResults(i).atlasResult = atlasResult;
    caseResults(i).identityResult = identityResult;
    caseResults(i).comparison = comparison;

    plotCaseComparison(comparison.points, cases(i, :), plotFolder);

    fprintf('  %s | raw frac %.3f | atlas frac %.3f | identity frac %.3f | atlas median err %.4g\n', ...
        comparison.summary.Classification, comparison.summary.RawValidFraction, ...
        comparison.summary.AtlasValidFraction, comparison.summary.IdentityValidFraction, ...
        comparison.summary.MedianAtlasRawRelError);
end

aggregate = summarizeAggregate(summaryRows);
plotAggregate(summaryRows, plotFolder);

writetable(pointRows, fullfile(outputFolder, 'atlas_vs_raw_branch1_grid_points.csv'));
writetable(summaryRows, fullfile(outputFolder, 'atlas_vs_raw_branch1_grid_summary.csv'));
writetable(rawCurveRows, fullfile(outputFolder, 'raw_branch1_grid_curve.csv'));
writetable(rawBranchRows, fullfile(outputFolder, 'raw_branch1_grid_branch_summary.csv'));
writetable(aggregate, fullfile(outputFolder, 'atlas_vs_raw_branch1_grid_aggregate.csv'));
save(fullfile(outputFolder, 'atlas_vs_raw_branch1_grid_workspace.mat'), ...
    'pointRows', 'summaryRows', 'rawCurveRows', 'rawBranchRows', 'aggregate', ...
    'caseResults', 'cases', 'settings', 'launchFolder', '-v7.3');

fprintf('\nGrid summary\n');
disp(summaryRows);
fprintf('\nAggregate\n');
disp(aggregate);
fprintf('\nData files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOAtlasVsRawBranch1GridSummary', summaryRows);
assignin('base', 'AcoustoelasticIOPHGOAtlasVsRawBranch1GridAggregate', aggregate);
assignin('base', 'AcoustoelasticIOPHGOAtlasVsRawBranch1GridOutputFolder', outputFolder);

function cases = makeValidationCases()
IOP = [5 15 25 35];
mu = [25 50 100];
rows = [];
for i = 1:numel(IOP)
    for j = 1:numel(mu)
        row = struct();
        row.CaseLabel = sprintf('iop_%gmmHg_mu_%gkPa', IOP(i), mu(j));
        row.IOP_mmHg = IOP(i);
        row.Mu_kPa = mu(j);
        row.K1_kPa = 25;
        row.K2 = 100;
        row.Thickness_um = 550;
        rows = [rows; row]; %#ok<AGROW>
    end
end
cases = struct2table(rows);
cases.CaseLabel = string(cases.CaseLabel);
end

function settings = defaultGridSettings()
settings = struct();
settings.frequency = logspace(log10(100), log10(35e3), 160);
settings.yGrid = logspace(log10(0.003), log10(2.0), 900);
settings.TopNMinimaPerFrequency = 16;
settings.MaxLogYJumpForRawBranch = 0.075;
settings.MinRawBranchPoints = 10;
settings.RelativeMismatchThreshold = 0.05;
settings.ConsecutiveMismatchPoints = 3;
settings.MinimumRawCoverageFraction = 0.80;
settings.MaximumRawMedianRank = 8;
settings.AlignmentMedianThreshold = 0.05;
settings.AlignmentMaxThreshold = 0.10;
settings.AtlasNumYPoints = 1000;
settings.AtlasTopNMinima = 18;
end

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

function rawAtlas = computeRawModalAtlas(params, settings)
rawOptions = defaultAcoustoelasticIOPHGOOptions();
rawOptions.M54_variant = "corrected";
rawOptions.normalizeRows = false;
rawOptions.branch = "A0";
rawOptions.trackingDirection = "backward";
rawOptions.trackingMethod = "globalScan";
rawOptions.minDimensionlessFrequency = 0.0;
rawOptions.usePhysicalCpWindow = false;

freq = params.frequency(:).';
cShear = sqrt(params.alpha / params.rho);
yGrid = settings.yGrid(:);
cGrid = yGrid * cShear;
objectiveMap = nan(numel(yGrid), numel(freq));
rows = [];

for k = 1:numel(freq)
    f = freq(k);
    for j = 1:numel(cGrid)
        objectiveMap(j, k) = objectiveAcoustoelasticResidual(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cGrid(j), rawOptions);
    end
    minima = findTopLocalMinima(cGrid, objectiveMap(:, k), cShear, settings.TopNMinimaPerFrequency);
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
    [minimaTable, branchTable] = linkMinimaIntoBranches(minimaTable, settings.MaxLogYJumpForRawBranch, settings.MinRawBranchPoints);
end

rawAtlas = struct();
rawAtlas.frequency = freq;
rawAtlas.yGrid = yGrid;
rawAtlas.cGrid = cGrid;
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

function T = addCaseColumns(T, caseRow, state)
if isempty(T)
    T = table();
end
n = height(T);
T.CaseLabel = repmat(string(caseRow.CaseLabel), n, 1);
T.IOP_mmHg = repmat(caseRow.IOP_mmHg, n, 1);
T.Mu_kPa = repmat(caseRow.Mu_kPa, n, 1);
T.K1_kPa = repmat(caseRow.K1_kPa, n, 1);
T.K2 = repmat(caseRow.K2, n, 1);
T.Thickness_um = repmat(caseRow.Thickness_um, n, 1);
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

function comparison = compareCase(caseRow, rawPoints, atlasResult, identityResult, settings)
f = atlasResult.frequency(:);
[rawCp, rawValid, rawRank] = assignRawBranchToFrequency(f, rawPoints);

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
firstAtlasMismatch = firstConsecutiveMismatch(f, atlasMismatch, settings.ConsecutiveMismatchPoints);
firstIdentityMismatch = firstConsecutiveMismatch(f, identityMismatch, settings.ConsecutiveMismatchPoints);

points = table();
points.CaseLabel = repmat(string(caseRow.CaseLabel), numel(f), 1);
points.IOP_mmHg = repmat(caseRow.IOP_mmHg, numel(f), 1);
points.Mu_kPa = repmat(caseRow.Mu_kPa, numel(f), 1);
points.K1_kPa = repmat(caseRow.K1_kPa, numel(f), 1);
points.K2 = repmat(caseRow.K2, numel(f), 1);
points.Thickness_um = repmat(caseRow.Thickness_um, numel(f), 1);
points.Frequency_Hz = f;
points.Frequency_kHz = f ./ 1e3;
points.RawCp_mps = rawCp(:);
points.RawValid = rawValid(:);
points.RawRank = rawRank(:);
points.AtlasCp_mps = atlasCp(:);
points.AtlasValid = atlasValid(:);
points.AtlasRawRelError = atlasErr(:);
points.AtlasRawMismatch = atlasMismatch(:);
points.IdentityCp_mps = identityCp(:);
points.IdentityValid = identityValid(:);
points.IdentityRawRelError = identityErr(:);
points.IdentityRawMismatch = identityMismatch(:);

summary = table();
summary.CaseLabel = string(caseRow.CaseLabel);
summary.IOP_mmHg = caseRow.IOP_mmHg;
summary.Mu_kPa = caseRow.Mu_kPa;
summary.K1_kPa = caseRow.K1_kPa;
summary.K2 = caseRow.K2;
summary.Thickness_um = caseRow.Thickness_um;
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
summary.FirstAtlasRawMismatchFrequency_kHz = firstAtlasMismatch / 1e3;
summary.FirstIdentityRawMismatchFrequency_kHz = firstIdentityMismatch / 1e3;
summary.MedianAtlasRawRelError = median(atlasErr(atlasOverlap), 'omitnan');
summary.MedianIdentityRawRelError = median(identityErr(identityOverlap), 'omitnan');
summary.MaxAtlasRawRelError = maxWithNaN(atlasErr(atlasOverlap));
summary.MaxIdentityRawRelError = maxWithNaN(identityErr(identityOverlap));
summary.IdentityAddedPoints = nnz(identityValid & ~atlasValid);
summary.Classification = classifyComparison(summary, firstAtlasMismatch, firstIdentityMismatch, settings);

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

function [err, overlap, mismatch] = relativeError(rawCp, rawValid, candidateCp, candidateValid, threshold)
overlap = rawValid(:) & candidateValid(:) & isfinite(rawCp(:)) & isfinite(candidateCp(:));
err = nan(size(rawCp(:)));
err(overlap) = abs(candidateCp(overlap) - rawCp(overlap)) ./ max(abs(rawCp(overlap)), eps);
mismatch = false(size(rawCp(:)));
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

function classification = classifyComparison(summary, firstAtlasMismatch, firstIdentityMismatch, settings)
rawUncertain = summary.RawValidFraction < settings.MinimumRawCoverageFraction || ...
    (isfinite(summary.RawMedianRank) && summary.RawMedianRank > settings.MaximumRawMedianRank);
if rawUncertain
    classification = "raw_branch_uncertain";
    return;
end
atlasAligned = isnan(firstAtlasMismatch) && ...
    summary.MedianAtlasRawRelError <= settings.AlignmentMedianThreshold && ...
    summary.MaxAtlasRawRelError <= settings.AlignmentMaxThreshold;
identityAligned = isnan(firstIdentityMismatch) && ...
    summary.MedianIdentityRawRelError <= settings.AlignmentMedianThreshold && ...
    summary.MaxIdentityRawRelError <= settings.AlignmentMaxThreshold;
atlasTruncated = summary.AtlasValidFraction < 0.98;
identityExtends = summary.IdentityAddedPoints > 0 && summary.IdentityRawValidOverlapFraction > summary.AtlasRawValidOverlapFraction;
if atlasAligned && atlasTruncated
    classification = "atlas_truncated_but_aligned";
elseif atlasAligned
    classification = "aligned_with_raw_branch";
elseif identityExtends && identityAligned
    classification = "identity_extension_aligned";
elseif identityExtends && ~identityAligned
    classification = "identity_extension_modal_mismatch";
elseif ~isnan(firstAtlasMismatch)
    classification = "atlas_branch_switch_suspected";
else
    classification = "raw_branch_uncertain";
end
end

function value = maxWithNaN(x)
if isempty(x) || ~any(isfinite(x))
    value = nan;
else
    value = max(x, [], 'omitnan');
end
end

function aggregate = summarizeAggregate(S)
if isempty(S)
    aggregate = table();
    return;
end
[G, cls] = findgroups(S.Classification);
aggregate = table();
aggregate.Classification = cls;
aggregate.Cases = splitapply(@numel, S.CaseLabel, G);
aggregate.MedianAtlasValidFraction = splitapply(@(x) median(x, 'omitnan'), S.AtlasValidFraction, G);
aggregate.MedianIdentityValidFraction = splitapply(@(x) median(x, 'omitnan'), S.IdentityValidFraction, G);
aggregate.MedianAtlasRawRelError = splitapply(@(x) median(x, 'omitnan'), S.MedianAtlasRawRelError, G);
aggregate.MedianIdentityRawRelError = splitapply(@(x) median(x, 'omitnan'), S.MedianIdentityRawRelError, G);
end

function plotCaseComparison(points, caseRow, plotFolder)
figure('Color', 'w', 'Name', char(caseRow.CaseLabel));
hold on; grid on;
plot(points.Frequency_kHz, points.RawCp_mps, '-', 'LineWidth', 2.5, 'DisplayName', 'raw_branch1');
plot(points.Frequency_kHz, points.AtlasCp_mps, '--', 'LineWidth', 1.8, 'DisplayName', 'atlasA0 official');
plot(points.Frequency_kHz, points.IdentityCp_mps, ':', 'LineWidth', 1.8, 'DisplayName', 'identityA0 diagnostic');
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title(sprintf('%s: atlasA0 and identityA0 versus raw_branch1', caseRow.CaseLabel), 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
hold off;
saveas(gcf, fullfile(plotFolder, sprintf('%s.png', caseRow.CaseLabel)));
saveas(gcf, fullfile(plotFolder, sprintf('%s.fig', caseRow.CaseLabel)));
end

function plotAggregate(S, plotFolder)
figure('Color', 'w', 'Name', 'atlas versus raw grid median errors');
hold on; grid on;
for mu = unique(S.Mu_kPa(:).')
    T = S(S.Mu_kPa == mu, :);
    T = sortrows(T, 'IOP_mmHg');
    plot(T.IOP_mmHg, T.MedianAtlasRawRelError, '-o', 'LineWidth', 1.5, 'DisplayName', sprintf('atlasA0 mu %.0f kPa', mu));
    plot(T.IOP_mmHg, T.MedianIdentityRawRelError, '--s', 'LineWidth', 1.5, 'DisplayName', sprintf('identityA0 mu %.0f kPa', mu));
end
xlabel('IOP [mmHg]');
ylabel('median relative error vs raw_branch1', 'Interpreter', 'none');
title('Grid median relative error against raw_branch1', 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
hold off;
saveas(gcf, fullfile(plotFolder, 'atlas_vs_raw_branch1_grid_median_error.png'));
saveas(gcf, fullfile(plotFolder, 'atlas_vs_raw_branch1_grid_median_error.fig'));
end
