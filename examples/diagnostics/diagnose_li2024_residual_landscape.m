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
xTargets = [0.05, 0.20, 0.50, 1.00, 1.50, 2.00, 2.50];
yGrid = linspace(0.02, 3.40, 2600);
cGrid = yGrid * cShear;

baseOptions = defaultLi2024AcoustoelasticOptions();
baseOptions.normalizeRows = true;
baseOptions.usePhysicalCpWindow = false; % explicit y-grid used here

variantList = ["paper", "corrected"];
landscape = struct();

for v = 1:numel(variantList)
    variant = variantList(v);
    options = baseOptions;
    options.M54_variant = variant;

    landscape.(char(variant)) = computeLandscape(params, options, xTargets, cGrid, cShear);
end

plotLandscapeComparison(landscape, xTargets, yGrid);
printLandscapeSummary(landscape, xTargets);

assignin('base', 'Li2024ResidualLandscape', landscape);

function landscape = computeLandscape(params, options, xTargets, cGrid, cShear)
objectiveMap = nan(numel(cGrid), numel(xTargets));
localMinima = cell(numel(xTargets), 1);

for ix = 1:numel(xTargets)
    f = xTargets(ix) * cShear / params.thickness;
    for ic = 1:numel(cGrid)
        objectiveMap(ic, ix) = objective_Li2024_Acoustoelastic(params.alpha, params.beta, params.gamma, ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f, cGrid(ic), options);
    end
    localMinima{ix} = findLocalMinima(cGrid, objectiveMap(:, ix), cShear);
end

landscape = struct();
landscape.options = options;
landscape.xTargets = xTargets;
landscape.cGrid = cGrid;
landscape.yGrid = cGrid / cShear;
landscape.objectiveMap = objectiveMap;
landscape.localMinima = localMinima;
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

function plotLandscapeComparison(landscape, xTargets, yGrid)
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

        xline(0.955, ':', 'A0 hi-f', 'HandleVisibility', 'off');
        xline(3.132, ':', 'S0 f=0', 'HandleVisibility', 'off');
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

function printLandscapeSummary(landscape, xTargets)
variantList = fieldnames(landscape);
fprintf('\nLi 2024 residual landscape diagnostic\n');
for v = 1:numel(variantList)
    variant = variantList{v};
    data = landscape.(variant);
    fprintf('\nVariant: %s\n', variant);
    for ix = 1:numel(xTargets)
        minima = data.localMinima{ix};
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
    end
end
end
