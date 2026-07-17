function minima = aeFindAtlasLocalMinima(cGrid, obj, cShear, topN, options)
%AEFINDATLASLOCALMINIMA Find and rank local minima in one atlas column.

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
