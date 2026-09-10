function [fields, objectiveMap] = aeEvaluateSelectedAtlasBranch(trackingResult, params, options)
%AEEVALUATESELECTEDATLASBRANCH Evaluate a fixed identity on requested frequencies.
% Requested samples never enter linking or branch scoring. Between consecutive
% internal points, require a unique discrete minimum inside the selected
% branch's atlas-cell corridor and the existing continuity bounds. Missing or
% ambiguous identity stays invalid; Cp is never interpolated across a gap.

frequency = params.frequency(:).';
trackingFrequency = trackingResult.frequency_Hz(:).';
cGrid = trackingResult.cGrid;
fields = struct('frequency', frequency, 'Cp', nan(size(frequency)), ...
    'validCp', false(size(frequency)), ...
    'branchExistsAtFrequency', false(size(frequency)), ...
    'interpolatedCp', false(size(frequency)), 'objective', nan(size(frequency)), ...
    'nearestRank', nan(size(frequency)), 'nearestBranchID', nan(size(frequency)), ...
    'pointStatus', repmat("missingSelectedBranch", size(frequency)), 'objectiveMap', []);
objectiveMap = nan(numel(cGrid), numel(frequency));
if isempty(trackingFrequency)
    fields.pointStatus = repmat("belowAtlasInitializationRange", size(frequency));
    return;
end
fields.pointStatus(frequency < trackingFrequency(1)) = "belowAtlasInitializationRange";
[tracked, loc] = ismember(frequency, trackingFrequency);
names = {'Cp','validCp','branchExistsAtFrequency','interpolatedCp', ...
    'objective','nearestRank','nearestBranchID','pointStatus'};
sources = {'phaseVelocity_mps','validMask','branchExistsAtFrequency','interpolatedCp', ...
    'objective','nearestRank','nearestBranchID','pointStatus'};
for j = 1:numel(names)
    fields.(names{j})(tracked) = trackingResult.(sources{j})(loc(tracked));
end
objectiveMap(:, tracked) = trackingResult.objectiveMap(:, loc(tracked));

discrete = trackingResult.minimaTable;
if isempty(discrete) || isempty(trackingResult.selectedBranch)
    return;
end
discrete = discrete(discrete.BranchID == trackingResult.selectedBranchID, :);
discrete = sortrows(discrete, 'Frequency_Hz');
pending = find(~tracked & frequency >= trackingFrequency(1) & frequency <= trackingFrequency(end));
if isempty(pending) || isempty(discrete)
    return;
end
outputParams = params;
outputParams.frequency = frequency(pending);
[map, ~, ~, cShear] = lamb.models.acoustoelastic_iop_hgo.solvers.aeBuildAtlas(outputParams, options);
objectiveMap(:, pending) = map;
selected = discrete([],:);
outputIndices = [];
for j = 1:numel(pending)
    k = pending(j);
    left = find(trackingFrequency < frequency(k), 1, 'last');
    right = left + 1;
    a = find(discrete.Frequency_Hz == trackingFrequency(left), 1);
    b = find(discrete.Frequency_Hz == trackingFrequency(right), 1);
    if isempty(a) || isempty(b)
        continue;
    end
    cpAnchors = discrete.Cp_mps([a b]);
    [~, gridIndices] = ismember(cpAnchors, cGrid);
    lower = cGrid(max(1, min(gridIndices) - 1));
    upper = cGrid(min(numel(cGrid), max(gridIndices) + 1));
    candidates = lamb.models.acoustoelastic_iop_hgo.tracking.aeFindAtlasLocalMinima( ...
        cGrid, map(:,j), cShear, options.atlasTopNMinima);
    compatible = candidates.Cp_mps >= lower & candidates.Cp_mps <= upper;
    for anchor = cpAnchors(:).'
        compatible = compatible & abs(log10(candidates.Cp_mps / anchor)) <= options.atlasMaxLogYJump;
        if options.atlasSplitOnLargeCpJump
            compatible = compatible & abs(candidates.Cp_mps - anchor) / anchor <= options.atlasMaxRelativeCpJump;
        end
    end
    if nnz(compatible) ~= 1
        fields.pointStatus(k) = "unresolvedSelectedIdentity";
        continue;
    end
    rank = find(compatible);
    row = discrete(a,:);
    row.Frequency_Hz = frequency(k);
    row.Frequency_kHz = frequency(k)/1e3;
    row.MinRank = rank;
    row.Cp_mps = candidates.Cp_mps(rank);
    row.y = candidates.y(rank);
    row.log10y = log10(row.y);
    row.Objective = candidates.Objective(rank);
    row.DepthRelativeToMedian = candidates.DepthRelativeToMedian(rank);
    row.DepthRelativeToDeepest = candidates.DepthRelativeToDeepest(rank);
    row.SpacingToNearestLogY = candidates.SpacingToNearestLogY(rank);
    selected = [selected; row]; %#ok<AGROW>
    outputIndices(end+1) = k; %#ok<AGROW>
end
% Identity and validity are fixed before continuous minimization.
selected = lamb.models.acoustoelastic_iop_hgo.tracking.aeRefineSelectedAtlasBranch(selected, params, cGrid, options);
fields.Cp(outputIndices) = selected.Cp_mps;
fields.validCp(outputIndices) = true;
fields.branchExistsAtFrequency(outputIndices) = true;
fields.objective(outputIndices) = selected.Objective;
fields.nearestRank(outputIndices) = selected.MinRank;
fields.nearestBranchID(outputIndices) = selected.BranchID;
fields.pointStatus(outputIndices) = "explicitBranchPoint";
end
