function fig = plotParametricSweepCp(sweepResults, modelName, branchName, varargin)
%PLOTPARAMETRICSWEEPCP Plot Cp(f) curves from runParametricSweep output.
%
% Examples:
%   plotParametricSweepCp(S, "mRLFEHanViscoRealK", "A0Like")
%   plotParametricSweepCp(S, "mRLFEElasticRealK", "S0Like")
%   plotParametricSweepCp(S, "RayleighLamb", "A0")

p = inputParser;
addParameter(p, 'Title', "", @(x)ischar(x) || isstring(x) || iscellstr(x));
addParameter(p, 'NewFigure', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'ShowLastValidPoint', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'LastValidPointMarkerSize', 7, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'FrequencyScale', 1, @(x)isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'FrequencyUnit', "Hz", @(x)ischar(x) || isstring(x));
addParameter(p, 'StartFrequencyAtZero', false, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});

if p.Results.NewFigure
    fig = figure('Color', 'w');
else
    fig = gcf;
end
ax = gca;
hold(ax, 'on'); grid(ax, 'on');

n = numel(sweepResults.results);
legendText = strings(1, n);
lastPointHandles = gobjects(0);

for i = 1:n
    result = sweepResults.results{i};
    branch = extractSweepBranch(result, modelName, branchName);
    if isempty(branch)
        warning('Missing branch %s / %s for sweep case %d.', string(modelName), string(branchName), i);
        continue;
    end

    valid = getBranchValidityMask(branch);
    xRaw = branch.frequency(:) ./ p.Results.FrequencyScale;
    yRaw = branch.Cp(:);
    valid = valid & isfinite(xRaw) & isfinite(yRaw);

    x = xRaw;
    y = yRaw;
    x(~valid) = nan;
    y(~valid) = nan;

    lineHandle = plot(ax, x, y, 'LineWidth', 1.8);
    legendText(i) = makeLegendLabel(sweepResults, i);

    if p.Results.ShowLastValidPoint && any(valid)
        lastValidIdx = find(valid, 1, 'last');
        markerHandle = plot(ax, xRaw(lastValidIdx), yRaw(lastValidIdx), 'o', ...
            'MarkerSize', p.Results.LastValidPointMarkerSize, ...
            'LineWidth', 1.4, ...
            'Color', lineHandle.Color, ...
            'MarkerFaceColor', lineHandle.Color, ...
            'HandleVisibility', 'off');
        lastPointHandles(end+1) = markerHandle; %#ok<AGROW>
    end
end

xlabel(ax, "Frequency [" + string(p.Results.FrequencyUnit) + "]");
ylabel(ax, 'Phase velocity Cp [m/s]');
setSweepPlotLimits(ax, 'CpAxis', 'y');
if logical(p.Results.StartFrequencyAtZero)
    setFrequencyAxisFromZero(ax);
end

requestedTitle = string(p.Results.Title);
if any(strlength(requestedTitle(:)) > 0)
    title(ax, requestedTitle, 'Interpreter', 'none');
else
    title(ax, sprintf('%s %s Cp sweep', string(modelName), string(branchName)), 'Interpreter', 'none');
end

legend(ax, legendText(legendText ~= ""), 'Location', 'best', 'Interpreter', 'none');

if p.Results.ShowLastValidPoint && ~isempty(lastPointHandles)
    addLastValidPointNote(ax);
end

hold(ax, 'off');
end

function branch = extractSweepBranch(result, modelName, branchName)
branch = [];
modelName = string(modelName);
branchName = string(branchName);

if modelName == "RayleighLamb"
    if isfield(result, 'modes') && isfield(result.modes, char(branchName))
        branch = result.modes.(char(branchName));
    end
    return;
end

if isfield(result, 'models') && isfield(result.models, char(modelName)) && ...
        isfield(result.models.(char(modelName)), 'branches') && ...
        isfield(result.models.(char(modelName)).branches, char(branchName))
    branch = result.models.(char(modelName)).branches.(char(branchName));
end
end

function valid = getBranchValidityMask(branch)
if isfield(branch, 'validCp')
    valid = branch.validCp(:) & isfinite(branch.Cp(:));
elseif isfield(branch, 'valid')
    valid = branch.valid(:) & isfinite(branch.Cp(:));
else
    valid = isfinite(branch.Cp(:));
end
end

function txt = makeLegendLabel(sweepResults, idx)
spec = sweepResults.spec;
value = sweepResults.displayValues(idx);

if isfield(spec, 'units') && strlength(string(spec.units)) > 0
    txt = sprintf('%s = %.4g %s', string(spec.label), value, string(spec.units));
else
    txt = sprintf('%s = %.4g', string(spec.label), value);
end
end

function setFrequencyAxisFromZero(ax)
values = [];
children = ax.Children;
for i = 1:numel(children)
    child = children(i);
    if isprop(child, 'XData')
        values = [values; child.XData(:)]; %#ok<AGROW>
    end
end
finiteValues = values(isfinite(values));
if isempty(finiteValues)
    upper = 1;
else
    upper = max(finiteValues(:));
end
if ~isfinite(upper) || upper <= 0
    upper = 1;
end
xlim(ax, [0 upper * 1.05]);
end

function addLastValidPointNote(ax)
xl = xlim(ax);
yl = ylim(ax);
text(ax, xl(1) + 0.02 * diff(xl), yl(2) - 0.06 * diff(yl), ...
    'o = last valid Cp point', ...
    'FontSize', 9, ...
    'VerticalAlignment', 'top', ...
    'BackgroundColor', 'w', ...
    'Margin', 3, ...
    'EdgeColor', [0.7 0.7 0.7]);
end
