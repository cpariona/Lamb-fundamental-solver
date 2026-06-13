clear; clc; close all;
startup

% Residual-landscape diagnostic for the Li 2024 acoustoelastic matrix.
%
% This diagnostic does not solve/track a branch. Instead, it scans the
% characteristic matrix objective:
%
%   log10(sigma_min(M))
%
% as a function of the dimensionless phase velocity
%
%   y = c / sqrt(alpha/rho)
%
% at selected dimensionless frequencies
%
%   x = f*h / sqrt(alpha/rho).
%
% The goal is to understand the local-minimum landscape before modifying the
% tracker further.

params = struct();
params.alpha = 74e3;                % Pa, arbitrary dimensional scale
params.beta = 4 * params.alpha;     % Appendix Fig. A1 solid-line ratio beta/alpha = 4
params.gamma = 0.92 * params.alpha; % Appendix Fig. A1 solid-line ratio gamma/alpha = 0.92
params.thickness = 0.55e-3;         % m
params.rho = 1060;                  % kg/m^3
params.rhoF = 1000;                 % kg/m^3
params.fluidBulkModulus = 2.2e9;    % Pa

cShear = sqrt(params.alpha / params.rho);
yA0HighTarget = 0.955;
yS0LowFreqTarget = sqrt((2*params.beta + 2*params.gamma) / params.alpha);

xTargets = [0.05, 0.20, 0.50, 1.00, 1.50, 2.00, 2.50];
yGrid = linspace(0.02, 3.40, 2600);
cGrid = yGrid * cShear;

bands = struct();
bands.A0_low = [0.02, 0.75];
bands.A0_high = [0.75, 1.20];
bands.S0_high = [1.20, 3.40];

baseOptions = defaultLi2024AcoustoelasticOptions();
baseOptions.normalizeRows = true;
baseOptions.usePhysicalCpWindow = false; % explicit y-grid used here

variantList = ["paper", "corrected"];
landscape = struct();

for v = 1:numel(variantList)
    variant = variantList(v);
    options = baseOptions;
    options.M54_variant = variant;

    landscape.(char(variant)) = computeLandscape(params, options, xTargets, cGrid, cShear, ...
        bands, yA0HighTarget, yS0LowFreqTarget);
end

plotLandscapeComparison(landscape, xTargets, yGrid, yA0HighTarget, yS0LowFreqTarget);
printLandscapeSummary(landscape, xTargets);

assignin('base', 'Li2024ResidualLandscape', landscape);

function landscape = computeLandscape(params, options, xTargets, cGrid, cShear, bands, yA0HighTarget, yS0LowFreqTarget)
objectiveMap = nan(numel(cGrid), numel(xTargets));
localMinima = cell(numel(xTargets), 1);
bandSummary = cell(numel(xTargets), 1);

for ix = 1:numel(xTargets)
    f = xTargets(ix) * cShear / params.thickness;
    for ic = 1:numel(cGrid)
        objectiveMap(ic, ix) = objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cGrid(ic), options);
    end
    localMinima{ix} = findLocalMinima(cGrid, objectiveMap(:, ix), cShear);
    bandSummary{ix} = summarizePhysicalBands(localMinima{ix}, bands, yA0HighTarget, yS0LowFreqTarget);
end

landscape = struct();
landscape.options = options;
landscape.xTargets = xTargets;
landscape.cGrid = cGrid;
landscape.yGrid = cGrid / cShear;
landscape.objectiveMap = objectiveMap;
landscape.localMinima = localMinima;
landscape.bandSummary = bandSummary;
landscape.bands = bands;
landscape.yA0HighTarget = yA0HighTarget;
landscape.yS0LowFreqTarget = yS0LowFreqTarget;
end

function minimaTable = findLocalMinima(cGrid, objVals, cShear)
idx = [];
for i = 2:numel(objVals)-1
    if isfinite(objVals(i-1)) && isfinite(objVals(i)) && isfinite(objVals(i+1)) && ...
            objVals(i) <= objVals(i-1) && objVals(i) <= objVals(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end

if isempty(idx)
    minimaTable = table([], [], [], 'VariableNames', {'Index', 'y', 'Objective'});
    return;
end

y = cGrid(idx) / cShear;
objective = objVals(idx);
[objective, order] = sort(objective, 'ascend');
idx = idx(order);
y = y(order);

minimaTable = table(idx(:), y(:), objective(:), 'VariableNames', {'Index', 'y', 'Objective'});
end

function summary = summarizePhysicalBands(minima, bands, yA0HighTarget, yS0LowFreqTarget)
summary = struct();
summary.deepest = pickDeepest(minima);
summary.A0_low = pickDeepestInBand(minima, bands.A0_low);
summary.A0_high = pickDeepestInBand(minima, bands.A0_high);
summary.S0_high = pickDeepestInBand(minima, bands.S0_high);
summary.nearest_A0_high_target = pickNearestTarget(minima, yA0HighTarget);
summary.nearest_S0_low_freq_target = pickNearestTarget(minima, yS0LowFreqTarget);
end

function item = pickDeepest(minima)
if isempty(minima)
    item = emptyItem();
else
    item = tableRowToItem(minima(1, :));
end
end

function item = pickDeepestInBand(minima, band)
if isempty(minima)
    item = emptyItem();
    return;
end
mask = minima.y >= band(1) & minima.y <= band(2);
if ~any(mask)
    item = emptyItem();
    return;
end
subset = minima(mask, :);
[~, idx] = min(subset.Objective);
item = tableRowToItem(subset(idx, :));
end

function item = pickNearestTarget(minima, target)
if isempty(minima)
    item = emptyItem();
    return;
end
[~, idx] = min(abs(minima.y - target));
item = tableRowToItem(minima(idx, :));
item.target = target;
item.deltaTarget = abs(item.y - target);
end

function item = tableRowToItem(row)
item = struct();
item.index = row.Index(1);
item.y = row.y(1);
item.objective = row.Objective(1);
item.target = nan;
item.deltaTarget = nan;
end

function item = emptyItem()
item = struct('index', nan, 'y', nan, 'objective', nan, 'target', nan, 'deltaTarget', nan);
end

function plotLandscapeComparison(landscape, xTargets, yGrid, yA0HighTarget, yS0LowFreqTarget)
variantList = fieldnames(landscape);

for v = 1:numel(variantList)
    variant = variantList{v};
    data = landscape.(variant);

    figure('Color', 'w', 'Name', ['Li2024 residual landscape - ', variant]);
    tiledlayout(numel(xTargets), 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    for ix = 1:numel(xTargets)
        nexttile;
        obj = data.objectiveMap(:, ix);
        plot(yGrid, obj, 'LineWidth', 1.2);
        hold on; grid on;

        minima = data.localMinima{ix};
        if ~isempty(minima)
            topN = min(8, height(minima));
            scatter(minima.y(1:topN), minima.Objective(1:topN), 25, 'filled');
        end

        markSummaryItem(data.bandSummary{ix}.A0_low, 'v');
        markSummaryItem(data.bandSummary{ix}.A0_high, '^');
        markSummaryItem(data.bandSummary{ix}.S0_high, 's');

        xline(yA0HighTarget, ':', 'A0 hi-f', 'HandleVisibility', 'off');
        xline(yS0LowFreqTarget, ':', 'S0 f=0', 'HandleVisibility', 'off');
        ylabel(sprintf('x=%.2f', xTargets(ix)));
        if ix == 1
            title(sprintf('Li 2024 residual landscape: %s M54', variant), 'Interpreter', 'none');
        end
        if ix == numel(xTargets)
            xlabel('c / sqrt(alpha/rho) [-]');
        end
        hold off;
    end
end
end

function markSummaryItem(item, marker)
if isfinite(item.y) && isfinite(item.objective)
    plot(item.y, item.objective, marker, 'MarkerSize', 7, 'LineWidth', 1.3, 'HandleVisibility', 'off');
end
end

function printLandscapeSummary(landscape, xTargets)
variantList = fieldnames(landscape);
fprintf('\nLi 2024 residual landscape diagnostic\n');
fprintf('Band markers: A0_low=[0.02,0.75], A0_high=[0.75,1.20], S0_high=[1.20,3.40]\n');
for v = 1:numel(variantList)
    variant = variantList{v};
    data = landscape.(variant);
    fprintf('\nVariant: %s\n', variant);
    for ix = 1:numel(xTargets)
        minima = data.localMinima{ix};
        summary = data.bandSummary{ix};
        fprintf('  x = %.2f:', xTargets(ix));
        if isempty(minima)
            fprintf(' no local minima\n');
            continue;
        end
        topN = min(5, height(minima));
        for k = 1:topN
            fprintf(' y%d=%.4g(obj %.3g)', k, minima.y(k), minima.Objective(k));
        end
        fprintf('\n');
        fprintf('      bands: deepest %s | A0_low %s | A0_high %s | S0_high %s\n', ...
            formatItem(summary.deepest), formatItem(summary.A0_low), ...
            formatItem(summary.A0_high), formatItem(summary.S0_high));
        fprintf('      target-nearest: A0_hi %s | S0_f0 %s\n', ...
            formatTargetItem(summary.nearest_A0_high_target), ...
            formatTargetItem(summary.nearest_S0_low_freq_target));
    end
end
end

function txt = formatItem(item)
if ~isfinite(item.y)
    txt = 'none';
else
    txt = sprintf('y=%.4g(obj %.3g)', item.y, item.objective);
end
end

function txt = formatTargetItem(item)
if ~isfinite(item.y)
    txt = 'none';
else
    txt = sprintf('y=%.4g(obj %.3g, |dy| %.3g)', item.y, item.objective, item.deltaTarget);
end
end
