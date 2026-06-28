clear; clc; close all;
startup

fprintf('\nA0 mRLFE residual landscape diagnostic\n');
fprintf('-------------------------------------\n');

muValues = [50e3 75e3 100e3 158e3];
probeFrequenciesHz = [1e3 2e3 4e3 8e3 12e3 15e3 16e3 20e3 26e3 28e3];
cpScanPoints = 3500;
cpRange = [0.5 30.0];
maxMinimaToKeep = 12;

outDir = fullfile(pwd, 'outputs', 'mrlfe', 'a0_residual_landscape');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

landscapeRows = [];
caseResults = cell(numel(muValues), 1);

for iMu = 1:numel(muValues)
    mu = muValues(iMu);
    fprintf('\nCase %d/%d: mu = %.3f kPa\n', iMu, numel(muValues), mu/1e3);
    [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu);

    directOptions = makeDirectOptions();
    directResult = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, directOptions);

    adaptiveA0 = solveMRLFEBranchAdaptiveAtlas("A0Like", ...
        mrlfeMakePhysicalSeedMode("A0Like", frequency, material, geometry, seedModes), ...
        material, geometry, mrlfeParams, makeA0AdaptiveOptions());

    selectedFreq = selectProbeFrequencies(frequency, directResult.branches.A0Like, adaptiveA0, probeFrequenciesHz);
    caseResults{iMu} = struct('params', params, 'frequency', frequency, ...
        'direct', directResult.branches.A0Like, 'adaptive', adaptiveA0, ...
        'selectedFreq', selectedFreq);

    for iF = 1:numel(selectedFreq)
        f = selectedFreq(iF);
        omega = 2*pi*f;
        CpScan = linspace(cpRange(1), cpRange(2), cpScanPoints);
        residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams);
        minima = extractMinima(CpScan, residual, maxMinimaToKeep);

        directCp = interpolateBranchCp(frequency, directResult.branches.A0Like.Cp, f);
        adaptiveCp = interpolateBranchCp(frequency, adaptiveA0.Cp, f);
        seedCp = interpolateBranchCp(frequency, seedModes.A0.Cp, f);

        rows = makeRows(mu, f, minima, directCp, adaptiveCp, seedCp);
        landscapeRows = [landscapeRows; rows]; %#ok<AGROW>

        fig = figure('Visible', 'off');
        semilogy(CpScan, residual, 'LineWidth', 1.2);
        hold on;
        markCp(seedCp, 'seed');
        markCp(directCp, 'direct');
        markCp(adaptiveCp, 'adaptive');
        if ~isempty(minima)
            plot([minima.cp], [minima.residual], 'o', 'MarkerSize', 5);
        end
        grid on;
        xlabel('Cp [m/s]');
        ylabel('mRLFE residual');
        title(sprintf('A0 residual landscape: mu = %.0f kPa, f = %.1f Hz', mu/1e3, f));
        legend('residual', 'seed Cp', 'direct A0 Cp', 'adaptive A0 Cp', 'local minima', 'Location', 'best');
        figFile = fullfile(outDir, sprintf('a0_landscape_mu_%06.1f_kPa_f_%08.1f_Hz.png', mu/1e3, f));
        saveas(fig, figFile);
        close(fig);
    end
end

landscapeTable = struct2table(landscapeRows);
disp(landscapeTable);

outFile = fullfile(outDir, 'mrlfe_a0_residual_landscape_mu_sweep.mat');
save(outFile, 'muValues', 'probeFrequenciesHz', 'cpRange', 'landscapeTable', 'landscapeRows', 'caseResults');
fprintf('\nSaved residual landscape diagnostic to:\n%s\n', outFile);
fprintf('Saved residual landscape figures to:\n%s\n', outDir);

function [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu)
params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = mu;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 32e3;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";

material = rlComputeMaterial(params);
geometryFull = rlComputeGeometry(params);
geometry = geometryFull;
if isfield(geometry, 'halfThickness')
    geometry = rmfield(geometry, 'halfThickness');
end
frequency = rlBuildFrequencyVector(params);

rlOptions = rlDefaultOptions("Fast");
rlOptions.computeA0 = true;
rlOptions.computeS0 = true;
rlOptions.computeMRLFE = false;
rlOptions.computeMRLFERealK = false;
rlOptions.computeMRLFEElasticRealK = false;
rlOptions.computeMRLFEViscoRealK = false;
rlOptions.computeMRLFEComplexK = false;
rlOptions.computeMRLFEViscoComplexK = false;
rlOptions.mrlfeUseUnifiedAtlasRoute = false;
rlResult = rlComputeFundamentalLambModes(params, rlOptions);

seedModes = struct();
seedModes.A0 = rlResult.modes.A0;
seedModes.S0 = rlResult.modes.S0;

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = 0.05;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;
end

function options = makeDirectOptions()
options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.computeMRLFEComplexK = false;
options.computeMRLFEViscoComplexK = false;
options.mrlfeViscoAtlasCpScanPoints = 900;
options.mrlfeA0DPCandidates = 8;
options.mrlfeA0DPRefineCandidates = true;
options.mrlfeDelayedCutMinValidRun = 8;
options.mrlfeDelayedCutPreviousCpMaxRelativeJump = 0.18;
options.mrlfeDelayedCutResidualTolerance = 1e-3;
end

function options = makeA0AdaptiveOptions()
options = rlDefaultOptions("Fast");
options.mrlfeAdaptiveCpScanPoints = 900;
options.mrlfeAdaptiveWindows = [0.20 0.35 0.50 0.80 1.20];
options.mrlfeAdaptiveEdgeGuardPoints = 4;
options.mrlfeAdaptiveRefineCandidates = true;
options.mrlfeAdaptiveMaxJumpRelative = 0.12;
options.mrlfeAdaptiveMaxPredictionError = 0.12;
options.mrlfeAdaptivePredictionWeight = 45.0;
options.mrlfeAdaptiveResidualWeight = 0.45;
options.mrlfeAdaptiveEstablishedMinValidRun = 8;
options.mrlfeAdaptiveCutAfterEstablishedLoss = true;
options.mrlfeResidualTolerance = 1e-3;
end

function selectedFreq = selectProbeFrequencies(frequency, directA0, adaptiveA0, probeFrequenciesHz)
freq = frequency(:);
selectedFreq = [];
for i = 1:numel(probeFrequenciesHz)
    [~, idx] = min(abs(freq - probeFrequenciesHz(i)));
    selectedFreq(end+1) = freq(idx); %#ok<AGROW>
end
selectedFreq = unique(selectedFreq(:).');

critical = [];
critical = [critical findLargeJumpFrequencies(freq, directA0.Cp, 0.15)]; %#ok<AGROW>
critical = [critical findLargeJumpFrequencies(freq, adaptiveA0.Cp, 0.10)]; %#ok<AGROW>
critical = [critical findCutNeighborFrequencies(freq, directA0.Cp)]; %#ok<AGROW>
critical = [critical findCutNeighborFrequencies(freq, adaptiveA0.Cp)]; %#ok<AGROW>
selectedFreq = unique([selectedFreq critical]);
selectedFreq = selectedFreq(isfinite(selectedFreq) & selectedFreq >= min(freq) & selectedFreq <= max(freq));
end

function critical = findLargeJumpFrequencies(freq, cp, threshold)
cp = cp(:);
valid = isfinite(cp) & cp > 0;
critical = [];
for i = 2:numel(cp)
    if valid(i) && valid(i-1)
        jump = abs(cp(i)-cp(i-1)) / max(abs(cp(i-1)), eps);
        if jump > threshold
            critical = [critical freq(max(i-2,1)) freq(i-1) freq(i) freq(min(i+1,numel(freq)))]; %#ok<AGROW>
        end
    end
end
end

function critical = findCutNeighborFrequencies(freq, cp)
cp = cp(:);
valid = isfinite(cp) & cp > 0;
critical = [];
for i = 2:numel(cp)-1
    if valid(i-1) && ~valid(i)
        critical = [critical freq(max(i-2,1)) freq(i-1) freq(i) freq(i+1)]; %#ok<AGROW>
    end
end
end

function residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams)
residual = nan(size(CpScan));
for i = 1:numel(CpScan)
    cp = CpScan(i);
    if isfinite(cp) && cp > 0
        residual(i) = mrlfeResidual(omega / cp, omega, material, geometry, mrlfeParams);
    end
end
end

function minima = extractMinima(CpScan, residual, maxMinimaToKeep)
idx = [];
for i = 2:numel(residual)-1
    if isfinite(residual(i)) && residual(i) < residual(i-1) && residual(i) < residual(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    minima = struct('rank', {}, 'cp', {}, 'residual', {});
    return;
end
[~, order] = sort(residual(idx), 'ascend');
idx = idx(order);
idx = idx(1:min(numel(idx), maxMinimaToKeep));
minima = repmat(struct('rank', nan, 'cp', nan, 'residual', nan), numel(idx), 1);
for n = 1:numel(idx)
    minima(n).rank = n;
    minima(n).cp = CpScan(idx(n));
    minima(n).residual = residual(idx(n));
end
end

function cp = interpolateBranchCp(frequency, branchCp, f)
frequency = frequency(:);
branchCp = branchCp(:);
valid = isfinite(branchCp) & branchCp > 0;
if nnz(valid) < 2 || f < min(frequency(valid)) || f > max(frequency(valid))
    cp = nan;
else
    cp = interp1(frequency(valid), branchCp(valid), f, 'linear', nan);
end
end

function rows = makeRows(mu, f, minima, directCp, adaptiveCp, seedCp)
if isempty(minima)
    rows = makeEmptyRow();
    rows.mu_kPa = mu/1e3;
    rows.frequencyHz = f;
    rows.minimumRank = nan;
    rows.minimumCp = nan;
    rows.minimumResidual = nan;
    rows.seedCp = seedCp;
    rows.directCp = directCp;
    rows.adaptiveCp = adaptiveCp;
    return;
end
rows = repmat(makeEmptyRow(), numel(minima), 1);
for i = 1:numel(minima)
    rows(i).mu_kPa = mu/1e3;
    rows(i).frequencyHz = f;
    rows(i).minimumRank = minima(i).rank;
    rows(i).minimumCp = minima(i).cp;
    rows(i).minimumResidual = minima(i).residual;
    rows(i).seedCp = seedCp;
    rows(i).directCp = directCp;
    rows(i).adaptiveCp = adaptiveCp;
    rows(i).distanceToSeed = abs(minima(i).cp - seedCp) / max(abs(seedCp), eps);
    rows(i).distanceToDirect = abs(minima(i).cp - directCp) / max(abs(directCp), eps);
    rows(i).distanceToAdaptive = abs(minima(i).cp - adaptiveCp) / max(abs(adaptiveCp), eps);
end
end

function row = makeEmptyRow()
row = struct();
row.mu_kPa = nan;
row.frequencyHz = nan;
row.minimumRank = nan;
row.minimumCp = nan;
row.minimumResidual = nan;
row.seedCp = nan;
row.directCp = nan;
row.adaptiveCp = nan;
row.distanceToSeed = nan;
row.distanceToDirect = nan;
row.distanceToAdaptive = nan;
end

function markCp(cp, labelText)
if isfinite(cp) && cp > 0
    yl = ylim;
    plot([cp cp], yl, '--', 'LineWidth', 1.0, 'DisplayName', labelText);
end
end
