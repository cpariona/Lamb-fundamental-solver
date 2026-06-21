function setSweepPlotLimits(ax, varargin)
%SETSWEEPPLOTLIMITS Apply consistent visual limits for sweep plots.
%
% Policy:
%   - The Cp axis starts at zero.
%   - Non-Cp axes use data-driven limits with padding.
%   - This helper is intended for sweep visualizations, not for general plots.

p = inputParser();
addParameter(p, 'CpAxis', 'y', @(x)ischar(x) || isstring(x));
addParameter(p, 'PaddingFraction', 0.05, @(x)isnumeric(x) && isscalar(x) && x >= 0);
parse(p, varargin{:});

cpAxis = lower(string(p.Results.CpAxis));
paddingFraction = p.Results.PaddingFraction;

axisNames = ["x", "y", "z"];
for i = 1:numel(axisNames)
    axisName = axisNames(i);
    if axisName == cpAxis
        setCpAxisLimit(ax, axisName, paddingFraction);
    elseif isAxisAvailable(ax, axisName)
        setDataAxisLimit(ax, axisName, paddingFraction);
    end
end
end

function tf = isAxisAvailable(ax, axisName)
switch axisName
    case {"x", "y"}
        tf = true;
    case "z"
        tf = ~isempty(findobj(ax.Children, '-property', 'ZData'));
    otherwise
        tf = false;
end
end

function setCpAxisLimit(ax, axisName, paddingFraction)
values = collectAxisData(ax, axisName);
finiteValues = values(isfinite(values));
if isempty(finiteValues)
    upper = 1;
else
    upper = max(finiteValues(:));
end
if ~isfinite(upper) || upper <= 0
    upper = 1;
end
upper = upper * (1 + paddingFraction);
applyAxisLimits(ax, axisName, [0 upper]);
end

function setDataAxisLimit(ax, axisName, paddingFraction)
values = collectAxisData(ax, axisName);
finiteValues = values(isfinite(values));
if isempty(finiteValues)
    return;
end
lo = min(finiteValues(:));
hi = max(finiteValues(:));
if lo == hi
    delta = max(abs(lo) * paddingFraction, 0.5);
else
    delta = (hi - lo) * paddingFraction;
end
applyAxisLimits(ax, axisName, [lo - delta, hi + delta]);
end

function values = collectAxisData(ax, axisName)
values = [];
children = ax.Children;
for i = 1:numel(children)
    child = children(i);
    propertyName = char(upper(axisName) + "Data");
    if isprop(child, propertyName)
        childValues = child.(propertyName);
        values = [values; childValues(:)]; %#ok<AGROW>
    end
end
end

function applyAxisLimits(ax, axisName, limits)
switch axisName
    case "x"
        xlim(ax, limits);
    case "y"
        ylim(ax, limits);
    case "z"
        zlim(ax, limits);
end
end
