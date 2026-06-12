clear; clc; close all;
startup

% Li 2024 IOP/HGO grid-convergence and branch-landscape diagnostic.
%
% Purpose:
%   1. Check whether the IOP sweep result depends strongly on Cp grid density.
%   2. Inspect the local-minimum landscape at a reference frequency to see
%      which solution families are available and which branch the tracker is
%      following.
%   3. Overlay the tracker-selected Cp at the reference frequency onto the
%      local-minimum families to identify branch switches directly.
%
% This script does not replace previous strategies. It diagnoses whether the
% selected A0 global-backward branch is stable with respect to numerical grid
% density and whether the 25 mmHg case switches to another local-minimum family.

baseParams = struct();

% Geometry.
baseParams.R = 7.8e-3;                  % m
baseParams.thickness = 550e-6;          % m

% HGO parameters. Example values for pipeline testing only.
baseParams.mu = 50e3;                   % Pa
baseParams.k1 = 25e3;                   % Pa
baseParams.k2 = 100;                    % dimensionless

% Densities and fluid bulk modulus.
baseParams.rho = 1060;                  % kg/m^3
baseParams.rhoF = 1000;                 % kg/m^3
baseParams.fluidBulkModulus = 2.2e9;    % Pa

% Keep the same frequency band as the sweep, but the number of points can be
% reduced if the diagnostic becomes too slow.
baseParams.frequency = linspace(6e3, 35e3, 100);

IOP_mmHg = [5, 10, 15, 20, 25];
IOP_Pa = IOP_mmHg * 133.322;
cpGridPointsList = [900, 1800, 3600];
referenceFrequency = 20e3;

baseOptions = defaultLi2024AcoustoelasticOptions();
baseOptions.M54_variant = "corrected";
baseOptions.branch = "A0";
baseOptions.trackingDirection = "backward";
baseOptions.trackingMethod = "globalScan";
baseOptions.minDimensionlessFrequency = 0.20;

convergenceRows = [];
convergenceResults = cell(numel(IOP_mmHg), numel(cpGridPointsList));

fprintf('\nLi 2024 IOP grid-convergence diagnostic\n');
fprintf('Strategy: corrected M54 + A0 + backward + globalScan\n');
fprintf('Reference frequency: %.1f kHz\n\n', referenceFrequency/1e3);

for g = 1:numel(cpGridPointsList)
    options = baseOptions;
    options.numCpScanPoints = cpGridPointsList(g);

    for i = 1:numel(IOP_Pa)
        params = baseParams;
        params.IOP = IOP_Pa(i);

        result = solveDispersionIOPHGO_Li2024(params, options);
        convergenceResults{i, g} = result;

        row = makeConvergenceRow(result, IOP_mmHg(i), IOP_Pa(i), cpGridPointsList(g), referenceFrequency);
        convergenceRows = [convergenceRows; row]; %#ok<AGROW>

        fprintf('grid %4d | IOP %4.1f mmHg | Cp@%.1fkHz %.4f m/s | MaxRelJump %.4f\n', ...
            cpGridPointsList(g), IOP_mmHg(i), referenceFrequency/1e3, row.CpAtRef_mps, row.MaxRelJump);
    end
end

convergenceTable = struct2table(convergenceRows);

% Local-minimum landscape at the reference frequency. This shows all main
% solution families available to the tracker.
landscapeTable = computeReferenceLandscape(baseParams, baseOptions, IOP_mmHg, IOP_Pa, referenceFrequency, 5200);

% Match each tracked Cp@reference-frequency point to the nearest available
% local-minimum family at the same IOP. This is the key branch-switch table.
trackedBranchTable = matchTrackedCpToLandscape(convergenceTable, landscapeTable);

plotCpAtReferenceVsGrid(convergenceTable, IOP_mmHg, cpGridPointsList, referenceFrequency);
plotConvergenceCurves(convergenceResults, IOP_mmHg, cpGridPointsList);
plotReferenceLandscape(landscapeTable, convergenceTable, IOP_mmHg, cpGridPointsList, referenceFrequency);
plotConstitutiveCheck(convergenceResults(:, 2), IOP_mmHg); % middle grid as representative

fprintf('\nGrid convergence table\n');
disp(convergenceTable);

fprintf('\nReference-frequency local-minimum landscape table\n');
disp(landscapeTable);

fprintf('\nTracked Cp matched to nearest local-minimum family\n');
disp(trackedBranchTable);

assignin('base', 'Li2024IOPGridConvergenceResults', convergenceResults);
assignin('base', 'Li2024IOPGridConvergenceTable', convergenceTable);
assignin('base', 'Li2024IOPReferenceLandscapeTable', landscapeTable);
assignin('base', 'Li2024IOPTrackedBranchTable', trackedBranchTable);

function row = makeConvergenceRow(result, IOP_mmHg, IOP_Pa, gridPoints, fRef)
valid = result.validCp & isfinite(result.Cp) & isfinite(result.frequency);
cpAtRef = nan;
medianCp = nan;
maxRelJump = nan;
roughness = nan;

if any(valid)
    cpAtRef = interp1(result.frequency(valid), result.Cp(valid), fRef, 'linear', nan);
    medianCp = median(result.Cp(valid), 'omitnan');
    cp = result.Cp(valid);
    if numel(cp) >= 2
        maxRelJump = max(abs(diff(cp)) ./ max(abs(cp(1:end-1)), eps), [], 'omitnan');
    end
    if numel(cp) >= 3
        roughness = median(abs(diff(cp, 2)), 'omitnan') / max(median(abs(cp), 'omitnan'), eps);
    end
end

state = result.constitutiveState;
row = struct();
row.IOP_mmHg = IOP_mmHg;
row.IOP_kPa = IOP_Pa / 1e3;
row.GridPoints = gridPoints;
row.Sigma_kPa = state.sigma / 1e3;
row.Lambda = state.lambda;
row.Alpha_kPa = result.directParams.alpha / 1e3;
row.Beta_kPa = result.directParams.beta / 1e3;
row.Gamma_kPa = result.directParams.gamma / 1e3;
row.ValidPoints = nnz(valid);
row.TotalPoints = numel(result.Cp);
row.MedianCp_mps = medianCp;
row.CpAtRef_mps = cpAtRef;
row.MaxRelJump = maxRelJump;
row.Roughness = roughness;
end

function landscapeTable = computeReferenceLandscape(baseParams, baseOptions, IOP_mmHg, IOP_Pa, fRef, nScan)
rows = [];
for i = 1:numel(IOP_Pa)
    params = baseParams;
    params.IOP = IOP_Pa(i);

    [alpha, beta, gamma, state] = computeABGFromIOPHGO_Li2024( ...
        params.IOP, params.R, params.thickness, params.mu, params.k1, params.k2);

    cShear = sqrt(alpha / params.rho);
    tensileSpeed = sqrt((2*beta + 2*gamma) / params.rho);

    yGrid = linspace(0.02, 1.35, nScan);
    cGrid = yGrid * cShear;
    obj = nan(size(cGrid));
    for j = 1:numel(cGrid)
        obj(j) = objective_Li2024_Acoustoelastic(alpha, beta, gamma, params.thickness, params.rho, ...
            params.rhoF, params.fluidBulkModulus, fRef, cGrid(j), baseOptions);
    end

    minima = findTopLocalMinima(cGrid, obj, cShear, 8);
    for m = 1:height(minima)
        row = struct();
        row.IOP_mmHg = IOP_mmHg(i);
        row.IOP_kPa = IOP_Pa(i) / 1e3;
        row.Sigma_kPa = state.sigma / 1e3;
        row.Lambda = state.lambda;
        row.MinRank = m;
        row.Cp_mps = minima.Cp(m);
        row.y = minima.y(m);
        row.Objective = minima.Objective(m);
        row.DistanceToA0HighTarget = abs(minima.y(m) - baseOptions.A0HighTarget);
        row.DistanceToTensileTarget = abs(minima.Cp(m) - tensileSpeed);
        rows = [rows; row]; %#ok<AGROW>
    end
end
landscapeTable = struct2table(rows);
end

function trackedTable = matchTrackedCpToLandscape(convergenceTable, landscapeTable)
rows = [];
for r = 1:height(convergenceTable)
    iop = convergenceTable.IOP_mmHg(r);
    cpTracked = convergenceTable.CpAtRef_mps(r);
    candidates = landscapeTable(landscapeTable.IOP_mmHg == iop, :);

    row = struct();
    row.IOP_mmHg = iop;
    row.GridPoints = convergenceTable.GridPoints(r);
    row.TrackedCp_mps = cpTracked;
    row.NearestMinRank = nan;
    row.NearestMinCp_mps = nan;
    row.DistanceToNearestMin_mps = nan;
    row.RelativeDistanceToNearestMin = nan;
    row.NearestMinObjective = nan;

    if ~isempty(candidates) && isfinite(cpTracked)
        [distance, idx] = min(abs(candidates.Cp_mps - cpTracked));
        nearestCp = candidates.Cp_mps(idx);
        row.NearestMinRank = candidates.MinRank(idx);
        row.NearestMinCp_mps = nearestCp;
        row.DistanceToNearestMin_mps = distance;
        row.RelativeDistanceToNearestMin = distance / max(abs(nearestCp), eps);
        row.NearestMinObjective = candidates.Objective(idx);
    end

    rows = [rows; row]; %#ok<AGROW>
end
trackedTable = struct2table(rows);
end

function minimaTable = findTopLocalMinima(cGrid, obj, cShear, topN)
idx = [];
for k = 2:numel(obj)-1
    if isfinite(obj(k-1)) && isfinite(obj(k)) && isfinite(obj(k+1)) && obj(k) <= obj(k-1) && obj(k) <= obj(k+1)
        idx(end+1) = k; %#ok<AGROW>
    end
end
if isempty(idx)
    minimaTable = table([], [], [], 'VariableNames', {'Cp','y','Objective'});
    return;
end
cp = cGrid(idx(:));
y = cp / cShear;
objective = obj(idx(:));
[objective, order] = sort(objective, 'ascend');
cp = cp(order);
y = y(order);
keep = 1:min(topN, numel(cp));
minimaTable = table(cp(keep), y(keep), objective(keep), 'VariableNames', {'Cp','y','Objective'});
end

function plotCpAtReferenceVsGrid(T, IOP_mmHg, gridList, fRef)
figure('Color', 'w');
hold on; grid on;
for g = 1:numel(gridList)
    mask = T.GridPoints == gridList(g);
    Tg = sortrows(T(mask, :), 'IOP_mmHg');
    plot(Tg.IOP_mmHg, Tg.CpAtRef_mps, 'o-', 'LineWidth', 1.8, ...
        'DisplayName', sprintf('%d Cp points', gridList(g)));
end
xlabel('IOP [mmHg]');
ylabel(sprintf('Cp at %.1f kHz [m/s]', fRef/1e3));
title('Li 2024 A0 grid convergence at reference frequency');
legend('Location', 'best');
hold off;
end

function plotConvergenceCurves(results, IOP_mmHg, gridList)
for g = 1:numel(gridList)
    figure('Color', 'w', 'Name', sprintf('Li2024 IOP sweep grid %d', gridList(g)));
    hold on; grid on;
    for i = 1:numel(IOP_mmHg)
        r = results{i, g};
        valid = r.validCp & isfinite(r.Cp);
        plot(r.frequency(valid)/1e3, r.Cp(valid), 'LineWidth', 1.4, ...
            'DisplayName', sprintf('IOP %.0f mmHg', IOP_mmHg(i)));
    end
    xlabel('frequency [kHz]');
    ylabel('Phase velocity Cp [m/s]');
    title(sprintf('Li 2024 A0 backward globalScan, grid = %d', gridList(g)));
    legend('Location', 'best');
    hold off;
end
end

function plotReferenceLandscape(landscapeTable, convergenceTable, IOP_mmHg, gridList, fRef)
figure('Color', 'w');
hold on; grid on;

% Background: all local-minimum families. Color encodes rank.
for i = 1:numel(IOP_mmHg)
    mask = landscapeTable.IOP_mmHg == IOP_mmHg(i);
    Ti = landscapeTable(mask, :);
    scatter(repmat(IOP_mmHg(i), height(Ti), 1), Ti.Cp_mps, 55, Ti.MinRank, 'filled', ...
        'HandleVisibility', 'off');
end

% Overlay: tracker-selected Cp for each grid density.
markerList = {'o', 's', '^', 'd', 'v'};
for g = 1:numel(gridList)
    mask = convergenceTable.GridPoints == gridList(g);
    Tg = sortrows(convergenceTable(mask, :), 'IOP_mmHg');
    marker = markerList{min(g, numel(markerList))};
    plot(Tg.IOP_mmHg, Tg.CpAtRef_mps, ['-', marker], 'LineWidth', 2.2, 'MarkerSize', 8, ...
        'DisplayName', sprintf('tracked Cp, %d grid', gridList(g)));
end

xlabel('IOP [mmHg]');
ylabel(sprintf('Cp at %.1f kHz [m/s]', fRef/1e3));
title('Li 2024 local minima and tracker-selected branches at reference frequency');
cb = colorbar;
cb.Label.String = 'local-minimum rank, 1 = deepest';
legend('Location', 'best');
hold off;
end

function plotConstitutiveCheck(results, IOP_mmHg)
alphaMinusGamma = nan(numel(results), 1);
sigma = nan(numel(results), 1);
for i = 1:numel(results)
    r = results{i};
    alphaMinusGamma(i) = (r.directParams.alpha - r.directParams.gamma) / 1e3;
    sigma(i) = r.constitutiveState.sigma / 1e3;
end
figure('Color', 'w');
plot(IOP_mmHg, alphaMinusGamma, 'o-', 'LineWidth', 2, 'DisplayName', 'alpha - gamma');
hold on; grid on;
plot(IOP_mmHg, sigma, 's--', 'LineWidth', 1.6, 'DisplayName', 'sigma');
xlabel('IOP [mmHg]');
ylabel('stress [kPa]');
title('Li 2024 constitutive check during grid diagnostic');
legend('Location', 'best');
hold off;
end
