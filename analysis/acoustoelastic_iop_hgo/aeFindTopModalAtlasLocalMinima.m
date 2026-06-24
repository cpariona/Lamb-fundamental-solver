function minimaTable = aeFindTopModalAtlasLocalMinima(cGrid, obj, cShear, topN)
%AEFINDTOPMODALATLASLOCALMINIMA Find top local minima in an AE modal-atlas Cp scan.

idx = [];
for k = 2:numel(obj)-1
    if isfinite(obj(k-1)) && isfinite(obj(k)) && isfinite(obj(k+1)) && obj(k) <= obj(k-1) && obj(k) <= obj(k+1)
        idx(end+1) = k; %#ok<AGROW>
    end
end

if isempty(idx)
    minimaTable = table([], [], [], [], [], [], 'VariableNames', ...
        {'Cp','y','Objective','DepthRelativeToMedian','DepthRelativeToDeepest','SpacingToNearestLogY'});
    return;
end

cp = cGrid(idx(:));
y = cp / cShear;
objective = obj(idx(:));
finiteObj = obj(isfinite(obj));
medianObj = median(finiteObj, 'omitnan');
deepest = min(objective, [], 'omitnan');
depthRelMedian = medianObj - objective;
depthRelDeepest = objective - deepest;

logY = log10(y);
spacing = nan(size(logY));
for i = 1:numel(logY)
    others = logY;
    others(i) = [];
    if isempty(others)
        spacing(i) = inf;
    else
        spacing(i) = min(abs(logY(i) - others));
    end
end

[objective, order] = sort(objective, 'ascend');
cp = cp(order);
y = y(order);
depthRelMedian = depthRelMedian(order);
depthRelDeepest = depthRelDeepest(order);
spacing = spacing(order);
keep = 1:min(topN, numel(cp));
minimaTable = table(cp(keep), y(keep), objective(keep), depthRelMedian(keep), depthRelDeepest(keep), spacing(keep), ...
    'VariableNames', {'Cp','y','Objective','DepthRelativeToMedian','DepthRelativeToDeepest','SpacingToNearestLogY'});
end
