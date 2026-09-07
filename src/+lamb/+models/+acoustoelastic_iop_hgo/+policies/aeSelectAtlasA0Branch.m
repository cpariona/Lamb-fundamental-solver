function [branch, id, branchTable] = aeSelectAtlasA0Branch(branchTable, options)
%AESELECTATLASA0BRANCH Apply the maintained atlasA0 selection policy.

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
