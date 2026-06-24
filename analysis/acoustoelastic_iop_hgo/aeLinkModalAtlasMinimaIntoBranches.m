function [minimaTable, branchTable] = aeLinkModalAtlasMinimaIntoBranches(minimaTable, maxLogYJump, minBranchPoints, mode)
%AELINKMODALATLASMINIMAINTOBRANCHES Link modal-atlas local minima into branch families.

if nargin < 4 || strlength(string(mode)) == 0
    mode = "standard";
end
mode = string(mode);

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
    row = makeBranchRow(b, T, mode);
    branchRows = [branchRows; row]; %#ok<AGROW>
end

if isempty(branchRows)
    branchTable = table();
else
    branchTable = struct2table(branchRows);
end
end

function row = makeBranchRow(branchID, T, mode)
row = struct();
row.BranchID = branchID;
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

if mode == "lowFrequency"
    row.FrequencyStart_Hz = min(T.Frequency_Hz);
    row.FrequencyEnd_Hz = max(T.Frequency_Hz);
    row.MedianY = median(T.y, 'omitnan');
    row.LowFrequencyCp_mps = T.Cp_mps(1);
    row.HighFrequencyCp_mps = T.Cp_mps(end);
    row.NetCpIncrease_mps = T.Cp_mps(end) - T.Cp_mps(1);
end
end
