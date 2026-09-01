function result = solveAcoustoelasticAtlasBranch(params, options)
%SOLVEACOUSTOELASTICATLASBRANCH Track and refine a persistent atlas branch.
%
% The atlas stage discovers discrete local minima, links candidate branches,
% and selects the maintained A0 branch. Continuous minimization is then applied
% only to the selected branch before official Cp assignment.

if nargin < 2
    options = [];
end
options = aeResolveConfiguration(options);
aeValidateRequest(params, 'Context', "directAtlas");

frequency = params.frequency(:).';
[objectiveMap, yGrid, cGrid, cShear] = aeBuildAtlas(params, options);
rows = [];

for k = 1:numel(frequency)
    f = frequency(k);
    minima = aeFindAtlasLocalMinima(cGrid, objectiveMap(:,k), cShear, options.atlasTopNMinima);
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
    [minimaTable, branchTable] = aeLinkAtlasBranches(minimaTable, options);
end

Cp = nan(size(frequency));
branchExistsAtFrequency = false(size(frequency));
interpolatedCp = false(size(frequency));
selectedBranchID = nan;
selectedBranch = table();
branchPoints = table();

if ~isempty(branchTable)
    [selectedBranch, selectedBranchID, branchTable] = aeSelectAtlasA0Branch(branchTable, options);
    branchPoints = sortrows(minimaTable(minimaTable.BranchID == selectedBranchID, :), 'Frequency_Hz');
    branchPoints = aeRefineSelectedAtlasBranch(branchPoints, params, cGrid, options);
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
    if ~isfinite(Cp(k))
        continue;
    end

    explicitRow = find(branchPoints.Frequency_Hz == frequency(k), 1, 'first');
    if ~isempty(explicitRow)
        objective(k) = branchPoints.Objective(explicitRow);
        nearestRank(k) = branchPoints.MinRank(explicitRow);
        nearestBranchID(k) = branchPoints.BranchID(explicitRow);
        continue;
    end

    if isempty(minimaTable)
        continue;
    end
    candidates = minimaTable(minimaTable.Frequency_Hz == frequency(k), :);
    if ~isempty(candidates)
        [~, idx] = min(abs(candidates.Cp_mps - Cp(k)));
        objective(k) = candidates.Objective(idx);
        nearestRank(k) = candidates.MinRank(idx);
        nearestBranchID(k) = candidates.BranchID(idx);
    end
end

fields = struct();
fields.frequency = frequency;
fields.Cp = Cp;
fields.validCp = validCp;
fields.branchExistsAtFrequency = branchExistsAtFrequency;
fields.interpolatedCp = interpolatedCp;
fields.pointStatus = pointStatus;
fields.objective = objective;
fields.nearestRank = nearestRank;
fields.nearestBranchID = nearestBranchID;
fields.selectedBranchID = selectedBranchID;
fields.selectedBranch = selectedBranch;
fields.selectedBranchPoints = branchPoints;
fields.minimaTable = minimaTable;
fields.branchTable = branchTable;
fields.objectiveMap = objectiveMap;
fields.yGrid = yGrid(:);
fields.cGrid = cGrid(:);
fields.cShear = cShear;
fields.options = options;
result = aeBuildResult(struct('fields', fields));

if strcmpi(string(options.atlasBranchPolicy), "identityA0Diagnostic")
    identity = aeBuildIdentityA0DiagnosticBranch(result);
    spec = struct();
    spec.baseResult = result;
    spec.postSummaryFields = struct('identityA0', identity);
    spec.diagnosticFields = struct( ...
        'identityA0CandidateValidPoints', identity.summary.CandidateValidPoints, ...
        'identityA0AddedCandidatePoints', identity.summary.AddedCandidatePoints);
    result = aeBuildResult(spec);
end
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
