function [minimaTable, branchTable] = aeLinkAtlasBranches(minimaTable, options)
%AELINKATLASBRANCHES Link ranked atlas minima into production branches.

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
    minimaTable = lamb.models.acoustoelastic_iop_hgo.tracking.aeSplitAtlasBranches(minimaTable, options.atlasMaxRelativeCpJump, options.atlasMinBranchPoints);
end

branchTable = buildBranchTable(minimaTable, options.atlasMinBranchPoints);
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
