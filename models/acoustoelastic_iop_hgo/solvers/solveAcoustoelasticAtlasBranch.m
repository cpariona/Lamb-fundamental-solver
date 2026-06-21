function result = solveAcoustoelasticAtlasBranch(params, options)
%SOLVEACOUSTOELASTICATLASBRANCH Track a persistent atlas branch.
%
% Conservative official output:
%   result.Cp and result.validCp are always assigned from the maintained atlas
%   branch logic. The optional identityA0Diagnostic policy only adds separate
%   candidate fields under result.identityA0.

if nargin < 2 || isempty(options)
    options = defaultAcoustoelasticIOPHGOOptions();
end
options = setAtlasDefaults(options);

required = {'alpha','beta','gamma','thickness','rho','rhoF','fluidBulkModulus','frequency'};
for i = 1:numel(required)
    if ~isfield(params, required{i})
        error('Missing required Acoustoelastic IOP/HGO atlas-branch parameter: %s', required{i});
    end
end

frequency = params.frequency(:).';
cShear = sqrt(params.alpha / params.rho);
yGrid = logspace(log10(options.atlasYMin), log10(options.atlasYMax), options.atlasNumYPoints);
cGrid = yGrid(:) * cShear;

objectiveMap = nan(numel(cGrid), numel(frequency));
rows = [];

for k = 1:numel(frequency)
    f = frequency(k);
    for j = 1:numel(cGrid)
        objectiveMap(j,k) = objectiveAcoustoelasticResidual(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cGrid(j), options);
    end
    minima = localMinima(cGrid, objectiveMap(:,k), cShear, options.atlasTopNMinima, options);
    for m = 1:height(minima)
        row = struct();
        row.Frequency_Hz = f;
        row.Frequency_kHz = f/1e3;
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
    [minimaTable, branchTable] = linkBranches(minimaTable, options);
end

Cp = nan(size(frequency));
branchExistsAtFrequency = false(size(frequency));
interpolatedCp = false(size(frequency));
selectedBranchID = nan;
selectedBranch = table();
branchPoints = table();

if ~isempty(branchTable)
    [selectedBranch, selectedBranchID, branchTable] = selectBranch(branchTable, options);
    branchPoints = sortrows(minimaTable(minimaTable.BranchID == selectedBranchID, :), 'Frequency_Hz');
    [Cp, branchExistsAtFrequency, interpolatedCp] = assignCpFromBranch(frequency, branchPoints, options);
end

validCp = isfinite(Cp) & (branchExistsAtFrequency | interpolatedCp);
objective = nan(size(Cp));
nearestRank = nan(size(Cp));
nearestBranchID = nan(size(Cp));
pointStatus = repmat("missingSelectedBranch", size(Cp));
pointStatus(branchExistsAtFrequency) = "explicitBranchPoint";
pointStatus(interpolatedCp) = "interpolatedWithinAllowedGap";

for k = 1:numel(frequency)
    if isempty(minimaTable)
        continue;
    end
    candidates = minimaTable(minimaTable.Frequency_Hz == frequency(k), :);
    if ~isempty(candidates) && isfinite(Cp(k))
        [~, idx] = min(abs(candidates.Cp_mps - Cp(k)));
        objective(k) = candidates.Objective(idx);
        nearestRank(k) = candidates.MinRank(idx);
        nearestBranchID(k) = candidates.BranchID(idx);
    end
end

result = struct();
result.frequency = frequency;
result.Cp = Cp;
result.validCp = validCp;
result.branchExistsAtFrequency = branchExistsAtFrequency;
result.interpolatedCp = interpolatedCp;
result.pointStatus = pointStatus;
result.objective = objective;
result.nearestRank = nearestRank;
result.nearestBranchID = nearestBranchID;
result.selectedBranchID = selectedBranchID;
result.selectedBranch = selectedBranch;
result.selectedBranchPoints = branchPoints;
result.minimaTable = minimaTable;
result.branchTable = branchTable;
result.objectiveMap = objectiveMap;
result.yGrid = yGrid(:);
result.cGrid = cGrid(:);
result.cShear = cShear;
result.options = options;
result.reliability = summarizeReliability(result);
result.diagnostics = summarizeResult(result);

if strcmpi(string(options.atlasBranchPolicy), "identityA0Diagnostic")
    result.identityA0 = aeBuildIdentityA0DiagnosticBranch(result);
    result.diagnostics.identityA0CandidateValidPoints = result.identityA0.summary.CandidateValidPoints;
    result.diagnostics.identityA0AddedCandidatePoints = result.identityA0.summary.AddedCandidatePoints;
end
end

function options = setAtlasDefaults(options)
def = struct();
def.atlasBranchPolicy = "atlasA0";
def.atlasYMin = 0.003;
def.atlasYMax = 2.0;
def.atlasNumYPoints = 1000;
def.atlasTopNMinima = 18;
def.atlasMaxLogYJump = 0.075;
def.atlasMinBranchPoints = 12;
def.atlasCoverageWeight = 1.40;
def.atlasRoughnessWeight = 1.20;
def.atlasRankWeight = 0.70;
def.atlasLowYWeight = 0.35;
def.atlasIncreaseWeight = 0.50;
def.atlasDropWeight = 1.25;
def.atlasStartYWeight = 1.10;
def.atlasStartRankWeight = 0.55;
def.atlasStartCpWeight = 0.65;
def.atlasPreferPositiveSlope = true;
def.atlasSplitOnLargeCpJump = true;
def.atlasMaxRelativeCpJump = 0.05;
def.atlasRequireLowStartY = true;
def.atlasMaxStartY = 0.50;
def.atlasRequireStartRank = true;
def.atlasMaxStartRank = 3;
def.atlasFallbackToUnfilteredSelection = true;
def.atlasAllowInterpolationAcrossGaps = false;
def.atlasMaxInterpolationFrequencyRatio = 1.12;
names = fieldnames(def);
for i = 1:numel(names)
    if ~isfield(options, names{i}) || isempty(options.(names{i}))
        options.(names{i}) = def.(names{i});
    end
end

if isfield(options, 'atlasBranchPolicy')
    options.atlasBranchPolicy = aeNormalizeBranchPolicy(options.atlasBranchPolicy);
end
end

function minima = localMinima(cGrid, obj, cShear, topN, options)
idx = [];
for i = 2:numel(obj)-1
    if isfinite(obj(i-1)) && isfinite(obj(i)) && isfinite(obj(i+1)) && obj(i) <= obj(i-1) && obj(i) <= obj(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    minima = table([],[],[],[],[],[], 'VariableNames', {'Cp_mps','y','Objective','DepthRelativeToMedian','DepthRelativeToDeepest','SpacingToNearestLogY'});
    return;
end

if getLocalOption(options, 'refineLocalMinima', true)
    [cp, objective] = refineLocalMinimaOnLogGrid(cGrid, obj, idx(:));
else
    cp = cGrid(idx(:));
    objective = obj(idx(:));
end

y = cp ./ cShear;
finiteObj = obj(isfinite(obj));
medianObj = median(finiteObj, 'omitnan');
deepest = min(objective, [], 'omitnan');
depthMedian = medianObj - objective;
depthDeepest = objective - deepest;
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
depthMedian = depthMedian(order);
depthDeepest = depthDeepest(order);
spacing = spacing(order);
keep = 1:min(topN, numel(cp));
minima = table(cp(keep), y(keep), objective(keep), depthMedian(keep), depthDeepest(keep), spacing(keep), ...
    'VariableNames', {'Cp_mps','y','Objective','DepthRelativeToMedian','DepthRelativeToDeepest','SpacingToNearestLogY'});
end

function [cpRefined, objRefined] = refineLocalMinimaOnLogGrid(cGrid, obj, idx)
cpRefined = cGrid(idx);
objRefined = obj(idx);

logC = log(cGrid(:));
for n = 1:numel(idx)
    i = idx(n);
    if i <= 1 || i >= numel(cGrid)
        continue;
    end

    x = logC(i-1:i+1);
    y = obj(i-1:i+1);

    if any(~isfinite(x)) || any(~isfinite(y))
        continue;
    end

    p = polyfit(x(:), y(:), 2);
    if ~isfinite(p(1)) || p(1) <= 0
        continue;
    end

    x0 = -p(2) / (2*p(1));
    if x0 <= x(1) || x0 >= x(3)
        continue;
    end

    cpRefined(n) = exp(x0);
    objRefined(n) = polyval(p, x0);
end
end

function value = getLocalOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

function [minimaTable, branchTable] = linkBranches(minimaTable, options)
minimaTable = sortrows(minimaTable, {'Frequency_Hz','MinRank'});
minimaTable.BranchID(:) = nan;
lastLogY = [];
lastFreq = [];
branchID = 0;
freqList = unique(minimaTable.Frequency_Hz, 'stable');
for k = 1:numel(freqList)
    f = freqList(k);
    rows = find(minimaTable.Frequency_Hz == f);
    used = false(1, max(branchID,1));
    for ii = 1:numel(rows)
        r = rows(ii);
        best = nan;
        bestScore = inf;
        for b = 1:branchID
            if b <= numel(used) && used(b), continue; end
            if lastFreq(b) >= f, continue; end
            jump = abs(minimaTable.log10y(r) - lastLogY(b));
            if jump > options.atlasMaxLogYJump, continue; end
            score = jump + 0.02*minimaTable.MinRank(r);
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

if options.atlasSplitOnLargeCpJump
    minimaTable = splitBranchesOnLargeCpJump(minimaTable, options.atlasMaxRelativeCpJump, options.atlasMinBranchPoints);
end

branchTable = buildBranchTable(minimaTable, options.atlasMinBranchPoints);
end

function minimaTable = splitBranchesOnLargeCpJump(minimaTable, maxRelativeCpJump, minBranchPoints)
if isempty(minimaTable) || ~isfinite(maxRelativeCpJump) || maxRelativeCpJump <= 0
    return;
end
branchIDs = unique(minimaTable.BranchID(isfinite(minimaTable.BranchID)), 'stable');
if isempty(branchIDs)
    return;
end
nextID = max(branchIDs) + 1;
for ii = 1:numel(branchIDs)
    b = branchIDs(ii);
    idx = find(minimaTable.BranchID == b);
    if numel(idx) < 2
        continue;
    end
    [~, order] = sort(minimaTable.Frequency_Hz(idx));
    idx = idx(order);
    cp = minimaTable.Cp_mps(idx);
    relJump = abs(diff(cp)) ./ max(abs(cp(1:end-1)), eps);
    cutAfter = find(relJump > maxRelativeCpJump);
    if isempty(cutAfter)
        continue;
    end
    starts = [1; cutAfter(:)+1];
    ends = [cutAfter(:); numel(idx)];
    minimaTable.BranchID(idx) = nan;
    for s = 1:numel(starts)
        segIdx = idx(starts(s):ends(s));
        if numel(segIdx) >= minBranchPoints
            minimaTable.BranchID(segIdx) = nextID;
            nextID = nextID + 1;
        end
    end
end
end

function branchTable = buildBranchTable(minimaTable, minBranchPoints)
branchRows = [];
branchIDs = unique(minimaTable.BranchID(isfinite(minimaTable.BranchID)), 'stable');
for ii = 1:numel(branchIDs)
    b = branchIDs(ii);
    T = sortrows(minimaTable(minimaTable.BranchID == b,:), 'Frequency_Hz');
    if height(T) < minBranchPoints
        minimaTable.BranchID(minimaTable.BranchID == b) = nan;
        continue;
    end
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
    row.YStart = T.y(1);
    row.YEnd = T.y(end);
    row.StartRank = T.MinRank(1);
    row.EndRank = T.MinRank(end);
    row.MinCp_mps = min(T.Cp_mps);
    row.MaxCp_mps = max(T.Cp_mps);
    row.MedianCp_mps = median(T.Cp_mps, 'omitnan');
    row.MedianY = median(T.y, 'omitnan');
    row.MedianRank = median(T.MinRank, 'omitnan');
    row.MedianObjective = median(T.Objective, 'omitnan');
    row.MedianSpacingToNearestLogY = median(T.SpacingToNearestLogY, 'omitnan');
    row.NetCpIncrease_mps = T.Cp_mps(end) - T.Cp_mps(1);
    dCp = diff(T.Cp_mps);
    negativeDrops = -dCp(dCp < 0);
    row.NumCpDrops = numel(negativeDrops);
    if isempty(negativeDrops)
        row.MaxCpDrop_mps = 0;
        row.MaxRelativeCpDrop = 0;
    else
        row.MaxCpDrop_mps = max(negativeDrops);
        relDrop = -dCp ./ max(abs(T.Cp_mps(1:end-1)), eps);
        row.MaxRelativeCpDrop = max([0; relDrop(:)]);
    end
    if height(T) >= 3
        row.Roughness = median(abs(diff(T.Cp_mps,2)), 'omitnan') / max(median(abs(T.Cp_mps), 'omitnan'), eps);
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

function [branch, id, branchTable] = selectBranch(branchTable, options)
a0Mask = true(height(branchTable), 1);
if options.atlasRequireLowStartY
    a0Mask = a0Mask & branchTable.YStart <= options.atlasMaxStartY;
end
if options.atlasRequireStartRank
    a0Mask = a0Mask & branchTable.StartRank <= options.atlasMaxStartRank;
end
fallbackUsed = false;
selectionMask = a0Mask;
if ~any(selectionMask)
    if options.atlasFallbackToUnfilteredSelection
        selectionMask = true(height(branchTable), 1);
        fallbackUsed = true;
    else
        error('No atlas branch satisfies the hard A0-like start filters. Relax atlasMaxStartY or atlasMaxStartRank.');
    end
end

coverage = normMetric(branchTable.FrequencyCoverage_kHz);
roughness = normMetric(branchTable.Roughness);
rank = normMetric(branchTable.MedianRank);
lowY = normMetric(branchTable.MedianY);
increase = normMetric(branchTable.NetCpIncrease_mps);
dropPenalty = normMetric(branchTable.MaxRelativeCpDrop);
startY = normMetric(branchTable.YStart);
startRank = normMetric(branchTable.StartRank);
startCp = normMetric(branchTable.CpStart_mps);
score = -options.atlasCoverageWeight*coverage + options.atlasRoughnessWeight*roughness + ...
    options.atlasRankWeight*rank + options.atlasLowYWeight*lowY - options.atlasIncreaseWeight*increase + ...
    options.atlasDropWeight*dropPenalty + options.atlasStartYWeight*startY + ...
    options.atlasStartRankWeight*startRank + options.atlasStartCpWeight*startCp;
if options.atlasPreferPositiveSlope
    score(branchTable.NetCpIncrease_mps < 0) = score(branchTable.NetCpIncrease_mps < 0) + 1;
end
score(~selectionMask) = inf;
[~, idx] = min(score);
branchTable.A0StartFilterPassed = a0Mask;
branchTable.SelectionScore = score;
branchTable.SelectionFallbackUsed = repmat(fallbackUsed, height(branchTable), 1);
branch = branchTable(idx,:);
id = branch.BranchID;
end

function [Cp, branchExists, interpolated] = assignCpFromBranch(frequency, branchPoints, options)
Cp = nan(size(frequency));
branchExists = false(size(frequency));
interpolated = false(size(frequency));
if isempty(branchPoints)
    return;
end
[isMember, loc] = ismember(frequency, branchPoints.Frequency_Hz);
Cp(isMember) = branchPoints.Cp_mps(loc(isMember));
branchExists(isMember) = true;

if ~options.atlasAllowInterpolationAcrossGaps
    return;
end

missing = ~branchExists;
if ~any(missing)
    return;
end
for k = find(missing)
    f = frequency(k);
    leftIdx = find(branchPoints.Frequency_Hz < f, 1, 'last');
    rightIdx = find(branchPoints.Frequency_Hz > f, 1, 'first');
    if isempty(leftIdx) || isempty(rightIdx)
        continue;
    end
    fLeft = branchPoints.Frequency_Hz(leftIdx);
    fRight = branchPoints.Frequency_Hz(rightIdx);
    if fRight / max(fLeft, eps) <= options.atlasMaxInterpolationFrequencyRatio
        Cp(k) = interp1([fLeft, fRight], [branchPoints.Cp_mps(leftIdx), branchPoints.Cp_mps(rightIdx)], f, 'linear');
        interpolated(k) = true;
    end
end
end

function reliability = summarizeReliability(result)
valid = result.validCp & isfinite(result.Cp);
f = result.frequency;
reliability = struct();
reliability.PolicyName = string(result.options.atlasBranchPolicy);
reliability.TotalPoints = numel(result.Cp);
reliability.ValidPoints = nnz(valid);
reliability.MissingPoints = nnz(~valid);
reliability.ValidFraction = nnz(valid) / max(numel(result.Cp), 1);
reliability.InterpolatedPoints = nnz(result.interpolatedCp);
reliability.ExplicitBranchPoints = nnz(result.branchExistsAtFrequency);
reliability.SelectedBranchID = result.selectedBranchID;
if any(valid)
    validF = f(valid);
    reliability.FirstValidFrequency_Hz = validF(1);
    reliability.FirstValidFrequency_kHz = validF(1)/1e3;
    reliability.LastValidFrequency_Hz = validF(end);
    reliability.LastValidFrequency_kHz = validF(end)/1e3;
else
    reliability.FirstValidFrequency_Hz = nan;
    reliability.FirstValidFrequency_kHz = nan;
    reliability.LastValidFrequency_Hz = nan;
    reliability.LastValidFrequency_kHz = nan;
end
missingAfterStart = find(~valid & f >= reliability.FirstValidFrequency_Hz, 1, 'first');
if isempty(missingAfterStart)
    reliability.FirstMissingFrequency_Hz = nan;
    reliability.FirstMissingFrequency_kHz = nan;
else
    reliability.FirstMissingFrequency_Hz = f(missingAfterStart);
    reliability.FirstMissingFrequency_kHz = f(missingAfterStart)/1e3;
end
if ~isempty(result.selectedBranch)
    reliability.A0StartFilterPassed = logical(result.selectedBranch.A0StartFilterPassed);
    reliability.SelectionFallbackUsed = logical(result.selectedBranch.SelectionFallbackUsed);
    reliability.YStart = result.selectedBranch.YStart;
    reliability.StartRank = result.selectedBranch.StartRank;
    reliability.CpStart_mps = result.selectedBranch.CpStart_mps;
    reliability.MaxBranchRelativeCpDrop = result.selectedBranch.MaxRelativeCpDrop;
else
    reliability.A0StartFilterPassed = false;
    reliability.SelectionFallbackUsed = false;
    reliability.YStart = nan;
    reliability.StartRank = nan;
    reliability.CpStart_mps = nan;
    reliability.MaxBranchRelativeCpDrop = nan;
end
reliability.ValidityNote = "Cp is considered reliable only where validCp is true; high-frequency NaNs mean the selected atlasA0 branch is not explicitly traceable under the current atlas criteria.";
end

function x = normMetric(x)
x = x(:);
mask = isfinite(x);
if ~any(mask)
    x(:) = 0;
    return;
end
xmin = min(x(mask)); xmax = max(x(mask));
if abs(xmax-xmin) < eps
    x(mask) = 0;
else
    x(mask) = (x(mask)-xmin)./(xmax-xmin);
end
x(~mask) = 1;
end

function diagnostics = summarizeResult(result)
diagnostics = struct();
diagnostics.validCpPoints = nnz(result.validCp);
diagnostics.totalPoints = numel(result.Cp);
diagnostics.explicitBranchPoints = nnz(result.branchExistsAtFrequency);
diagnostics.interpolatedPoints = nnz(result.interpolatedCp);
diagnostics.missingBranchPoints = nnz(~result.validCp);
diagnostics.selectedBranchID = result.selectedBranchID;
diagnostics.policyName = string(result.options.atlasBranchPolicy);
diagnostics.lastValidFrequency_kHz = result.reliability.LastValidFrequency_kHz;
diagnostics.validFraction = result.reliability.ValidFraction;
if any(result.validCp)
    diagnostics.minCp = min(result.Cp(result.validCp));
    diagnostics.maxCp = max(result.Cp(result.validCp));
    diagnostics.medianCp = median(result.Cp(result.validCp), 'omitnan');
else
    diagnostics.minCp = nan; diagnostics.maxCp = nan; diagnostics.medianCp = nan;
end
end
