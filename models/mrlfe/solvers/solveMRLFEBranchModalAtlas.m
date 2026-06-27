function branch = solveMRLFEBranchModalAtlas(name, seedMode, material, geometry, mrlfeParams, options)
%SOLVEMRLFEBRANCHMODALATLAS Experimental modal-atlas real-k mRLFE branch solver.
%
% Diagnostic/experimental solver. It evaluates the real-k mRLFE residual over a
% Cp-frequency atlas, extracts local minima at each frequency, links minima into
% modal families, and selects one family using modal-identity criteria.
%
% The Rayleigh-Lamb seed is used to define a broad Cp scan window and to report
% comparison metadata. It is not used as pointwise continuation reference.
%
% Optional ambiguity handling:
%   mrlfeModalAtlasApplyAmbiguityCut = false/true
% When enabled, modal escape clusters are marked invalid instead of forcing a
% jump to another modal family. Continuous Cp is always preserved in
% branch.modalAtlas.continuousCp.

if nargin < 6 || isempty(options)
    options = struct();
end
if nargin < 5 || ~isstruct(mrlfeParams)
    error('mrlfeParams must be a structure.');
end

name = string(name);
frequency = seedMode.frequency(:);
omega = seedMode.omega(:);
seedCp = getSeedCp(seedMode);

mrlfeParams.solveComplexK = false;
if ~isfield(mrlfeParams, 'etaS') || isempty(mrlfeParams.etaS)
    mrlfeParams.etaS = 0;
end
if ~isfield(mrlfeParams, 'etaL') || isempty(mrlfeParams.etaL)
    mrlfeParams.etaL = 0;
end
if ~isfield(mrlfeParams, 'useComplexLambda') || isempty(mrlfeParams.useComplexLambda)
    mrlfeParams.useComplexLambda = false;
end

atlasOptions = defaultAtlasOptions(options, name);
CpScan = buildCpScan(seedCp, atlasOptions);
minimaTable = buildMinimaTable(frequency, omega, CpScan, material, geometry, mrlfeParams, atlasOptions);
[minimaTable, branchTable] = linkModalFamilies(minimaTable, frequency, atlasOptions);
selected = selectModalFamily(branchTable, minimaTable, frequency, atlasOptions, name);

[Cp, residual, candidateRank, candidateIndex, familyId] = reconstructSelectedBranch(selected, minimaTable, frequency);
continuousCp = Cp;
continuousResidual = residual;
continuousFamilyId = familyId;

[ambiguityMask, ambiguityClusters, ambiguityTriggers] = detectModalAmbiguity(frequency, Cp, residual, familyId, minimaTable, atlasOptions);
if atlasOptions.applyAmbiguityCut
    Cp(ambiguityMask) = nan;
    residual(ambiguityMask) = nan;
    candidateRank(ambiguityMask) = nan;
    candidateIndex(ambiguityMask) = nan;
    familyId(ambiguityMask) = nan;
end

kReal = omega ./ Cp;
kReal(~isfinite(Cp) | Cp <= 0) = nan;
kImag = zeros(size(kReal));
k = kReal;
kThickness = kReal .* geometry.thickness;
validResidual = isfinite(residual) & residual <= atlasOptions.residualTolerance;
validCp = isfinite(Cp) & Cp > 0;
valid = validCp;
if atlasOptions.requireResidualValidity
    valid = valid & validResidual;
end

branch = struct();
branch.name = name;
branch.family = name;
branch.frequency = frequency;
branch.omega = omega;
branch.k = k;
branch.kReal = kReal;
branch.kImag = kImag;
branch.attenuation = kImag;
branch.Cp = Cp;
branch.kThickness = kThickness;
branch.residual = residual;
branch.score = residual;
branch.seedCp = seedCp;
branch.seedK = omega ./ seedCp;
branch.validResidual = validResidual;
branch.validReference = true(size(valid));
branch.validSmooth = validCp;
branch.validCp = valid;
branch.valid = valid;
branch.validAttenuation = false(size(valid));
branch.candidateIndex = candidateIndex;
branch.candidateRank = candidateRank;
branch.modalAtlasFamilyId = familyId;
branch.modalAmbiguityMask = ambiguityMask;
branch.modalAmbiguityClusters = ambiguityClusters;
branch.modalAmbiguityTriggers = ambiguityTriggers;
branch.modalAtlas = struct();
branch.modalAtlas.CpScan = CpScan(:);
branch.modalAtlas.minimaTable = minimaTable;
branch.modalAtlas.branchTable = branchTable;
branch.modalAtlas.selectedFamily = selected;
branch.modalAtlas.options = atlasOptions;
branch.modalAtlas.seedFamily = getSeedFamily(seedMode);
branch.modalAtlas.etaS = mrlfeParams.etaS;
branch.modalAtlas.continuousCp = continuousCp;
branch.modalAtlas.continuousResidual = continuousResidual;
branch.modalAtlas.continuousFamilyId = continuousFamilyId;
branch.modalAtlas.applyAmbiguityCut = atlasOptions.applyAmbiguityCut;
branch.note = "Experimental mRLFE modal atlas branch. Diagnostic only.";
end

function [Cp, residual, candidateRank, candidateIndex, familyId] = reconstructSelectedBranch(selected, minimaTable, frequency)
Cp = nan(size(frequency));
residual = nan(size(frequency));
candidateRank = nan(size(frequency));
candidateIndex = nan(size(frequency));
familyId = nan(size(frequency));
if isempty(selected) || ~isfinite(selected.BranchID)
    return;
end
rows = minimaTable(minimaTable.BranchID == selected.BranchID, :);
for i = 1:height(rows)
    idx = rows.FrequencyIndex(i);
    if idx < 1 || idx > numel(frequency)
        continue;
    end
    Cp(idx) = rows.Cp_mps(i);
    residual(idx) = rows.Objective(i);
    candidateRank(idx) = rows.MinRank(i);
    candidateIndex(idx) = rows.LocalIndex(i);
    familyId(idx) = rows.BranchID(i);
end
end

function seedCp = getSeedCp(seedMode)
if isfield(seedMode, 'Cp') && ~isempty(seedMode.Cp)
    seedCp = seedMode.Cp(:);
elseif isfield(seedMode, 'omega') && isfield(seedMode, 'k')
    seedCp = seedMode.omega(:) ./ real(seedMode.k(:));
else
    error('seedMode must contain Cp or omega/k fields.');
end
end

function family = getSeedFamily(seedMode)
family = "unknown";
if isfield(seedMode, 'family')
    family = string(seedMode.family);
elseif isfield(seedMode, 'name')
    family = string(seedMode.name);
end
end

function atlasOptions = defaultAtlasOptions(options, branchName)
atlasOptions = struct();
atlasOptions.branchName = string(branchName);
atlasOptions.cpScanPoints = getOption(options, 'mrlfeModalAtlasCpScanPoints', 900);
atlasOptions.edgeGuardPoints = getOption(options, 'mrlfeModalAtlasEdgeGuardPoints', 4);
atlasOptions.topNMinima = getOption(options, 'mrlfeModalAtlasTopNMinima', 16);
atlasOptions.refineMinima = getOption(options, 'mrlfeModalAtlasRefineMinima', false);
atlasOptions.refineTolX = getOption(options, 'mrlfeModalAtlasRefineTolX', 1e-6);
atlasOptions.refineMaxIter = getOption(options, 'mrlfeModalAtlasRefineMaxIter', 20);
atlasOptions.refineMaxFunEvals = getOption(options, 'mrlfeModalAtlasRefineMaxFunEvals', 50);
atlasOptions.cpMinFactor = getOption(options, 'mrlfeModalAtlasCpMinFactor', 0.20);
atlasOptions.cpMaxFactor = getOption(options, 'mrlfeModalAtlasCpMaxFactor', 2.80);
atlasOptions.cpMinFloor = getOption(options, 'mrlfeModalAtlasCpMinFloor', 0.20);
atlasOptions.cpMaxCeiling = getOption(options, 'mrlfeModalAtlasCpMaxCeiling', 120);
atlasOptions.maxLogCpJump = getOption(options, 'mrlfeModalAtlasMaxLogCpJump', 0.070);
atlasOptions.minBranchPoints = getOption(options, 'mrlfeModalAtlasMinBranchPoints', 8);
atlasOptions.maxFamiliesToScore = getOption(options, 'mrlfeModalAtlasMaxFamiliesToScore', 12);
atlasOptions.maxStartRank = getOption(options, 'mrlfeModalAtlasMaxStartRank', 5);
atlasOptions.maxStartCpFactorToSeed = getOption(options, 'mrlfeModalAtlasMaxStartCpFactorToSeed', 2.50);
atlasOptions.requireLowStartRank = getOption(options, 'mrlfeModalAtlasRequireLowStartRank', false);
atlasOptions.residualTolerance = max(getOption(options, 'mrlfeResidualTolerance', 1e-4), 1e-3);
atlasOptions.requireResidualValidity = getOption(options, 'mrlfeModalAtlasRequireResidualValidity', false);

atlasOptions.coverageWeight = getOption(options, 'mrlfeModalAtlasCoverageWeight', 2.0);
atlasOptions.rankWeight = getOption(options, 'mrlfeModalAtlasRankWeight', 0.8);
atlasOptions.roughnessWeight = getOption(options, 'mrlfeModalAtlasRoughnessWeight', 1.2);
atlasOptions.residualWeight = getOption(options, 'mrlfeModalAtlasResidualWeight', 0.8);
atlasOptions.startCpWeight = getOption(options, 'mrlfeModalAtlasStartCpWeight', 0.5);

atlasOptions.applyAmbiguityCut = getOption(options, 'mrlfeModalAtlasApplyAmbiguityCut', false);
atlasOptions.ambiguityResidualRatio = getOption(options, 'mrlfeModalAtlasAmbiguityResidualRatio', 4.0);
atlasOptions.ambiguityMinCpSeparation = getOption(options, 'mrlfeModalAtlasAmbiguityMinCpSeparation', 0.16);
atlasOptions.ambiguityMaxGapPoints = getOption(options, 'mrlfeModalAtlasAmbiguityMaxGapPoints', 6);
atlasOptions.ambiguityPaddingPoints = getOption(options, 'mrlfeModalAtlasAmbiguityPaddingPoints', 1);
atlasOptions.ambiguityMinClusterTriggers = getOption(options, 'mrlfeModalAtlasAmbiguityMinClusterTriggers', 2);
atlasOptions.ambiguityRequireHigherCpAlternative = getOption(options, 'mrlfeModalAtlasAmbiguityRequireHigherCpAlternative', true);
end

function CpScan = buildCpScan(seedCp, atlasOptions)
valid = isfinite(seedCp) & seedCp > 0;
if any(valid)
    cpMin = max(atlasOptions.cpMinFloor, min(seedCp(valid)) * atlasOptions.cpMinFactor);
    cpMax = min(atlasOptions.cpMaxCeiling, max(seedCp(valid)) * atlasOptions.cpMaxFactor);
else
    cpMin = atlasOptions.cpMinFloor;
    cpMax = atlasOptions.cpMaxCeiling;
end
if cpMax <= cpMin
    cpMax = cpMin + 10;
end
CpScan = linspace(cpMin, cpMax, atlasOptions.cpScanPoints);
end

function minimaTable = buildMinimaTable(frequency, omega, CpScan, material, geometry, mrlfeParams, atlasOptions)
rows = [];
for iFreq = 1:numel(frequency)
    residual = residualVsCp(CpScan, omega(iFreq), material, geometry, mrlfeParams);
    minima = findLocalMinima(CpScan, residual, omega(iFreq), material, geometry, mrlfeParams, atlasOptions);
    for iMin = 1:height(minima)
        row = struct();
        row.Frequency_Hz = frequency(iFreq);
        row.FrequencyIndex = iFreq;
        row.LocalIndex = iMin;
        row.MinRank = iMin;
        row.Cp_mps = minima.Cp_mps(iMin);
        row.logCp = log(max(minima.Cp_mps(iMin), eps));
        row.Objective = minima.Objective(iMin);
        row.BranchID = nan;
        rows = [rows; row]; %#ok<AGROW>
    end
end
if isempty(rows)
    minimaTable = table();
else
    minimaTable = struct2table(rows);
end
end

function residual = residualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    cp = CpScan(i);
    if ~isfinite(cp) || cp <= 0
        residual(i) = inf;
    else
        residual(i) = mrlfeResidual(omega / cp, omega, material, geometry, mrlfeParams);
    end
end
end

function minima = findLocalMinima(CpScan, residual, omega, material, geometry, mrlfeParams, atlasOptions)
firstAllowed = 1 + atlasOptions.edgeGuardPoints;
lastAllowed = numel(residual) - atlasOptions.edgeGuardPoints;
idx = [];
for i = max(2, firstAllowed):min(numel(residual)-1, lastAllowed)
    if isfinite(residual(i)) && residual(i) <= residual(i-1) && residual(i) <= residual(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    minima = table([], [], 'VariableNames', {'Cp_mps','Objective'});
    return;
end
[~, order] = sort(residual(idx), 'ascend');
idx = idx(order);
idx = idx(1:min(atlasOptions.topNMinima, numel(idx)));
cp = CpScan(idx(:));
obj = residual(idx(:));
if atlasOptions.refineMinima
    [cp, obj] = refineMinima(CpScan, idx, cp, obj, omega, material, geometry, mrlfeParams, atlasOptions);
    [obj, order] = sort(obj, 'ascend');
    cp = cp(order);
end
minima = table(cp(:), obj(:), 'VariableNames', {'Cp_mps','Objective'});
end

function [cp, obj] = refineMinima(CpScan, idx, cp, obj, omega, material, geometry, mrlfeParams, atlasOptions)
opt = optimset('Display', 'off', 'TolX', atlasOptions.refineTolX, ...
    'MaxIter', atlasOptions.refineMaxIter, 'MaxFunEvals', atlasOptions.refineMaxFunEvals);
for i = 1:numel(idx)
    k = idx(i);
    if k <= 1 || k >= numel(CpScan)
        continue;
    end
    lower = CpScan(k-1);
    upper = CpScan(k+1);
    if ~(isfinite(lower) && isfinite(upper) && upper > lower)
        continue;
    end
    try
        objective = @(candidateCp) mrlfeResidual(omega / candidateCp, omega, material, geometry, mrlfeParams);
        [candidateCp, candidateObj] = fminbnd(objective, lower, upper, opt);
        if isfinite(candidateCp) && isfinite(candidateObj) && candidateObj <= obj(i)
            cp(i) = candidateCp;
            obj(i) = candidateObj;
        end
    catch
    end
end
end

function [minimaTable, branchTable] = linkModalFamilies(minimaTable, frequency, atlasOptions)
if isempty(minimaTable)
    branchTable = table();
    return;
end
minimaTable = sortrows(minimaTable, {'FrequencyIndex','MinRank'});
lastLogCp = [];
lastFreqIdx = [];
branchID = 0;
for iFreq = 1:numel(frequency)
    rows = find(minimaTable.FrequencyIndex == iFreq);
    used = false(1, max(branchID, 1));
    for iRow = 1:numel(rows)
        r = rows(iRow);
        best = nan;
        bestScore = inf;
        for b = 1:branchID
            if b <= numel(used) && used(b)
                continue;
            end
            if lastFreqIdx(b) >= iFreq
                continue;
            end
            jump = abs(minimaTable.logCp(r) - lastLogCp(b));
            if jump > atlasOptions.maxLogCpJump
                continue;
            end
            gapPenalty = 0.02 * max(0, iFreq - lastFreqIdx(b) - 1);
            rankPenalty = 0.005 * minimaTable.MinRank(r);
            score = jump + gapPenalty + rankPenalty;
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
        lastLogCp(best) = minimaTable.logCp(r); %#ok<AGROW>
        lastFreqIdx(best) = iFreq; %#ok<AGROW>
        used(best) = true;
    end
end
branchTable = summarizeBranches(minimaTable, frequency, atlasOptions);
end

function branchTable = summarizeBranches(minimaTable, frequency, atlasOptions)
rows = [];
ids = unique(minimaTable.BranchID(isfinite(minimaTable.BranchID)), 'stable');
for i = 1:numel(ids)
    T = sortrows(minimaTable(minimaTable.BranchID == ids(i), :), 'FrequencyIndex');
    if height(T) < atlasOptions.minBranchPoints
        continue;
    end
    row = struct();
    row.BranchID = ids(i);
    row.NumPoints = height(T);
    row.FrequencyCoverageFraction = height(T) / numel(frequency);
    row.FrequencyStart_Hz = T.Frequency_Hz(1);
    row.FrequencyEnd_Hz = T.Frequency_Hz(end);
    row.StartRank = T.MinRank(1);
    row.StartCp_mps = T.Cp_mps(1);
    row.MedianRank = median(T.MinRank, 'omitnan');
    row.MedianCp_mps = median(T.Cp_mps, 'omitnan');
    row.Roughness = branchRoughness(T.Cp_mps);
    row.MedianObjective = median(T.Objective, 'omitnan');
    row.MaxObjective = max(T.Objective, [], 'omitnan');
    row.Score = nan;
    rows = [rows; row]; %#ok<AGROW>
end
if isempty(rows)
    branchTable = table();
else
    branchTable = struct2table(rows);
end
end

function value = branchRoughness(cp)
cp = cp(:);
if numel(cp) < 3
    value = nan;
else
    value = median(abs(diff(cp, 2)), 'omitnan') / max(median(abs(cp), 'omitnan'), eps);
end
end

function selected = selectModalFamily(branchTable, minimaTable, frequency, atlasOptions, branchName) %#ok<INUSD>
selected = table();
if isempty(branchTable)
    selected = emptySelectedFamily();
    return;
end
T = branchTable;
if atlasOptions.requireLowStartRank
    T = T(T.StartRank <= atlasOptions.maxStartRank, :);
end
T = T(T.StartRank <= max(atlasOptions.maxStartRank, 1) | T.FrequencyCoverageFraction > 0.75, :);
if isempty(T)
    selected = emptySelectedFamily();
    return;
end
T = sortrows(T, {'FrequencyStart_Hz','StartRank','Score'});
T = T(1:min(height(T), atlasOptions.maxFamiliesToScore), :);
coverageCost = 1 - T.FrequencyCoverageFraction;
rankCost = normalizeMetric(T.MedianRank);
roughCost = normalizeMetric(T.Roughness);
resCost = normalizeMetric(log10(max(T.MedianObjective, realmin)));
startCpCost = normalizeMetric(T.StartCp_mps);
score = atlasOptions.coverageWeight * coverageCost + ...
    atlasOptions.rankWeight * rankCost + ...
    atlasOptions.roughnessWeight * roughCost + ...
    atlasOptions.residualWeight * resCost + ...
    atlasOptions.startCpWeight * startCpCost;
T.Score = score;
T = sortrows(T, 'Score');
selected = T(1, :);
end

function [ambiguityMask, clusters, triggers] = detectModalAmbiguity(frequency, Cp, residual, familyId, minimaTable, atlasOptions)
triggerMask = false(size(frequency));
triggerRows = [];
for i = 1:numel(frequency)
    if ~isfinite(Cp(i)) || ~isfinite(residual(i)) || ~isfinite(familyId(i))
        continue;
    end
    Tf = minimaTable(minimaTable.FrequencyIndex == i, :);
    if isempty(Tf)
        continue;
    end
    Tf = sortrows(Tf, 'Objective');
    best = Tf(1, :);
    if best.BranchID == familyId(i)
        continue;
    end
    if atlasOptions.ambiguityRequireHigherCpAlternative && best.Cp_mps <= Cp(i)
        continue;
    end
    relSep = abs(best.Cp_mps - Cp(i)) / max(abs(Cp(i)), eps);
    objRatio = residual(i) / max(best.Objective, realmin);
    if relSep >= atlasOptions.ambiguityMinCpSeparation && objRatio >= atlasOptions.ambiguityResidualRatio
        triggerMask(i) = true;
        row = struct();
        row.Frequency_Hz = frequency(i);
        row.FrequencyIndex = i;
        row.SelectedCp_mps = Cp(i);
        row.SelectedObjective = residual(i);
        row.SelectedFamilyID = familyId(i);
        row.BestCp_mps = best.Cp_mps;
        row.BestObjective = best.Objective;
        row.BestRank = best.MinRank;
        row.BestFamilyID = best.BranchID;
        row.RelativeCpSeparation = relSep;
        row.ObjectiveRatio = objRatio;
        triggerRows = [triggerRows; row]; %#ok<AGROW>
    end
end
[ambiguityMask, clusters] = clusterTriggers(triggerMask, frequency, atlasOptions);
if isempty(triggerRows)
    triggers = table();
else
    triggers = struct2table(triggerRows);
end
end

function [cutMask, clusters] = clusterTriggers(triggerMask, frequency, atlasOptions)
idx = find(triggerMask(:));
cutMask = false(size(triggerMask(:)));
rows = [];
if isempty(idx)
    clusters = table();
    return;
end
startIdx = idx(1);
lastIdx = idx(1);
nTrig = 1;
for k = 2:numel(idx)
    if idx(k) - lastIdx <= atlasOptions.ambiguityMaxGapPoints + 1
        lastIdx = idx(k);
        nTrig = nTrig + 1;
    else
        [cutMask, rows] = addCluster(cutMask, rows, startIdx, lastIdx, nTrig, frequency, atlasOptions);
        startIdx = idx(k);
        lastIdx = idx(k);
        nTrig = 1;
    end
end
[cutMask, rows] = addCluster(cutMask, rows, startIdx, lastIdx, nTrig, frequency, atlasOptions);
if isempty(rows)
    clusters = table();
else
    clusters = struct2table(rows);
end
end

function [cutMask, rows] = addCluster(cutMask, rows, startIdx, lastIdx, nTrig, frequency, atlasOptions)
if nTrig < atlasOptions.ambiguityMinClusterTriggers
    return;
end
pad = atlasOptions.ambiguityPaddingPoints;
a = max(1, startIdx - pad);
b = min(numel(cutMask), lastIdx + pad);
cutMask(a:b) = true;
row = struct();
row.StartIndex = a;
row.EndIndex = b;
row.TriggerCount = nTrig;
row.StartFrequency_Hz = frequency(a);
row.EndFrequency_Hz = frequency(b);
row.CutPoints = b - a + 1;
rows = [rows; row]; %#ok<AGROW>
end

function x = normalizeMetric(x)
x = x(:);
mask = isfinite(x);
if ~any(mask)
    x(:) = 1;
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

function T = emptySelectedFamily()
T = table(nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, ...
    'VariableNames', {'BranchID','NumPoints','FrequencyCoverageFraction','FrequencyStart_Hz','FrequencyEnd_Hz', ...
    'StartRank','StartCp_mps','MedianRank','MedianCp_mps','Roughness','Score'});
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end
