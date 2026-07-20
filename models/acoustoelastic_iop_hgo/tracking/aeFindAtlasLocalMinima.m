function minima = aeFindAtlasLocalMinima(cGrid, obj, cShear, topN)
%AEFINDATLASLOCALMINIMA Find and rank discrete local minima in one atlas column.
%
% Candidate discovery remains strictly on the atlas velocity grid. Continuous
% refinement belongs to the selected-branch stage after branch linking and A0
% policy selection.

idx = [];
for i = 2:numel(obj)-1
    if isfinite(obj(i-1)) && isfinite(obj(i)) && isfinite(obj(i+1)) && ...
            obj(i) <= obj(i-1) && obj(i) <= obj(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    minima = table([],[],[],[],[],[], ...
        'VariableNames', {'Cp_mps','y','Objective','DepthRelativeToMedian', ...
        'DepthRelativeToDeepest','SpacingToNearestLogY'});
    return;
end

cp = cGrid(idx(:));
objective = obj(idx(:));
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
minima = table(cp(keep), y(keep), objective(keep), depthMedian(keep), ...
    depthDeepest(keep), spacing(keep), ...
    'VariableNames', {'Cp_mps','y','Objective','DepthRelativeToMedian', ...
    'DepthRelativeToDeepest','SpacingToNearestLogY'});
end
