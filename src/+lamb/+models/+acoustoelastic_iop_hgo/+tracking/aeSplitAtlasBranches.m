function minimaTable = aeSplitAtlasBranches(minimaTable, maxRelativeCpJump, minBranchPoints)
%AESPLITATLASBRANCHES Split linked branches at configured Cp jumps.

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
