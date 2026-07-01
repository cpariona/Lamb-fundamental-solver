clear; clc; close all;
startup

fprintf('\nA0 mRLFE low-residual basin diagnostic\n');
fprintf('---------------------------------------\n');

muValues = [50e3 75e3 100e3 158e3];
probeFrequenciesHz = [8e3 12e3 14997 15412 15495 15578 15661 15993 19974 21632 26028 27272];
cpRange = [0.5 30.0];
cpScanPoints = 6000;
relativeThresholds = [10 100 1000];

outDir = fullfile(pwd, 'outputs', 'mrlfe', 'a0_low_residual_basins');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

basinRows = [];
caseSummary = repmat(makeEmptyCaseSummary(), numel(muValues), 1);
caseResults = cell(numel(muValues), 1);

for iMu = 1:numel(muValues)
    mu = muValues(iMu);
    fprintf('\nCase %d/%d: mu = %.3f kPa\n', iMu, numel(muValues), mu/1e3);
    [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu);

    directResult = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, makeDirectOptions());
    adaptiveA0 = solveMRLFEBranchAdaptiveAtlas("A0Like", ...
        mrlfeMakePhysicalSeedMode("A0Like", frequency, material, geometry, seedModes), ...
        material, geometry, mrlfeParams, makeA0AdaptiveOptions());

    selectedFreq = selectProbeFrequencies(frequency, directResult.branches.A0Like, adaptiveA0, probeFrequenciesHz);
    caseResults{iMu} = struct('params', params, 'frequency', frequency, ...
        'seedA0', seedModes.A0, 'directA0', directResult.branches.A0Like, ...
        'adaptiveA0', adaptiveA0, 'selectedFreq', selectedFreq);

    caseSummary(iMu) = summarizeCase(mu, frequency, directResult.branches.A0Like, adaptiveA0);
    fprintf('  Direct valid   : %d/%d, last %.3f Hz, maxJump %.5f\n', ...
        caseSummary(iMu).DirectValidPoints, caseSummary(iMu).TotalPoints, ...
        caseSummary(iMu).DirectLastValidHz, caseSummary(iMu).DirectMaxJumpRelative);
    fprintf('  Adaptive valid : %d/%d, last %.3f Hz, maxJump %.5f, cut %s at %.3f Hz\n', ...
        caseSummary(iMu).AdaptiveValidPoints, caseSummary(iMu).TotalPoints, ...
        caseSummary(iMu).AdaptiveLastValidHz, caseSummary(iMu).AdaptiveMaxJumpRelative, ...
        string(caseSummary(iMu).AdaptiveCutReason), caseSummary(iMu).AdaptiveCutFrequencyHz);

    for iF = 1:numel(selectedFreq)
        f = selectedFreq(iF);
        omega = 2*pi*f;
        CpScan = linspace(cpRange(1), cpRange(2), cpScanPoints);
        residual = computeResidualVsCp(CpScan, omega, material, geometry, mrlfeParams);

        seedCp = interpolateBranchCp(frequency, seedModes.A0.Cp, f);
        directCp = interpolateBranchCp(frequency, directResult.branches.A0Like.Cp, f);
        adaptiveCp = interpolateBranchCp(frequency, adaptiveA0.Cp, f);
        previousAdaptiveCp = previousValidCpBeforeFrequency(frequency, adaptiveA0.Cp, f);

        rows = summarizeBasins(mu, f, CpScan, residual, relativeThresholds, ...
            seedCp, directCp, adaptiveCp, previousAdaptiveCp);
        basinRows = [basinRows; rows]; %#ok<AGROW>

        saveBasinFigure(outDir, mu, f, CpScan, residual, rows, seedCp, directCp, adaptiveCp, previousAdaptiveCp);
    end
end

basinTable = struct2table(basinRows);
caseSummaryTable = struct2table(caseSummary);

disp(caseSummaryTable);
disp(basinTable);

outFile = fullfile(outDir, 'mrlfe_a0_low_residual_basins_mu_sweep.mat');
save(outFile, 'muValues', 'probeFrequenciesHz', 'cpRange', 'relativeThresholds', ...
    'caseSummaryTable', 'caseSummary', 'basinTable', 'basinRows', 'caseResults');
fprintf('\nSaved low-residual basin diagnostic to:\n%s\n', outFile);
fprintf('Saved figures to:\n%s\n', outDir);

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
selectedFreq = unique([selectedFreq findCutNeighborFrequencies(freq, directA0.Cp) findCutNeighborFrequencies(freq, adaptiveA0.Cp)]);
selectedFreq = selectedFreq(isfinite(selectedFreq));
end

function critical = findCutNeighborFrequencies(freq, cp)
cp = cp(:);
valid = isfinite(cp) & cp > 0;
critical = [];
for i = 2:numel(cp)-1
    if valid(i-1) && ~valid(i)
        critical = [critical freq(max(i-3,1)) freq(max(i-2,1)) freq(i-1) freq(i) freq(i+1) freq(min(i+2,numel(freq)))]; %#ok<AGROW>
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

function rows = summarizeBasins(mu, f, CpScan, residual, relativeThresholds, seedCp, directCp, adaptiveCp, previousAdaptiveCp)
rows = [];
validResidual = isfinite(residual) & residual > 0;
if ~any(validResidual)
    rows = makeEmptyBasinRow();
    rows.mu_kPa = mu/1e3;
    rows.frequencyHz = f;
    return;
end
[minResidual, minIdx] = min(residual(validResidual));
validIdx = find(validResidual);
globalIdx = validIdx(minIdx);

for t = 1:numel(relativeThresholds)
    thresholdFactor = relativeThresholds(t);
    threshold = minResidual * thresholdFactor;
    mask = validResidual & residual <= threshold;
    components = maskComponents(mask);
    if isempty(components)
        continue;
    end
    localRows = repmat(makeEmptyBasinRow(), numel(components), 1);
    for c = 1:numel(components)
        idx = components(c).idx;
        [basinMinResidual, relMinIdx] = min(residual(idx));
        basinMinIdx = idx(relMinIdx);
        localRows(c).mu_kPa = mu/1e3;
        localRows(c).frequencyHz = f;
        localRows(c).thresholdFactor = thresholdFactor;
        localRows(c).globalMinCp = CpScan(globalIdx);
        localRows(c).globalMinResidual = minResidual;
        localRows(c).basinRankByCp = c;
        localRows(c).basinCpMin = CpScan(idx(1));
        localRows(c).basinCpMax = CpScan(idx(end));
        localRows(c).basinWidth = CpScan(idx(end)) - CpScan(idx(1));
        localRows(c).basinMinCp = CpScan(basinMinIdx);
        localRows(c).basinMinResidual = basinMinResidual;
        localRows(c).seedCp = seedCp;
        localRows(c).directCp = directCp;
        localRows(c).adaptiveCp = adaptiveCp;
        localRows(c).previousAdaptiveCp = previousAdaptiveCp;
        localRows(c).seedInside = isInside(seedCp, localRows(c).basinCpMin, localRows(c).basinCpMax);
        localRows(c).directInside = isInside(directCp, localRows(c).basinCpMin, localRows(c).basinCpMax);
        localRows(c).adaptiveInside = isInside(adaptiveCp, localRows(c).basinCpMin, localRows(c).basinCpMax);
        localRows(c).previousAdaptiveInside = isInside(previousAdaptiveCp, localRows(c).basinCpMin, localRows(c).basinCpMax);
        localRows(c).distanceToPreviousAdaptive = abs(localRows(c).basinMinCp - previousAdaptiveCp) / max(abs(previousAdaptiveCp), eps);
    end
    rows = [rows; localRows]; %#ok<AGROW>
end
if isempty(rows)
    rows = makeEmptyBasinRow();
    rows.mu_kPa = mu/1e3;
    rows.frequencyHz = f;
    rows.globalMinCp = CpScan(globalIdx);
    rows.globalMinResidual = minResidual;
end
end

function components = maskComponents(mask)
idx = find(mask(:));
components = struct('idx', {});
if isempty(idx)
    return;
end
breaks = [0; find(diff(idx) > 1); numel(idx)];
for i = 1:numel(breaks)-1
    componentIdx = idx((breaks(i)+1):breaks(i+1));
    components(end+1).idx = componentIdx; %#ok<AGROW>
end
end

function tf = isInside(cp, lo, hi)
tf = isfinite(cp) && cp >= lo && cp <= hi;
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

function cp = previousValidCpBeforeFrequency(frequency, branchCp, f)
frequency = frequency(:);
branchCp = branchCp(:);
idx = find(frequency < f & isfinite(branchCp) & branchCp > 0, 1, 'last');
if isempty(idx)
    cp = nan;
else
    cp = branchCp(idx);
end
end

function row = makeEmptyBasinRow()
row = struct();
row.mu_kPa = nan;
row.frequencyHz = nan;
row.thresholdFactor = nan;
row.globalMinCp = nan;
row.globalMinResidual = nan;
row.basinRankByCp = nan;
row.basinCpMin = nan;
row.basinCpMax = nan;
row.basinWidth = nan;
row.basinMinCp = nan;
row.basinMinResidual = nan;
row.seedCp = nan;
row.directCp = nan;
row.adaptiveCp = nan;
row.previousAdaptiveCp = nan;
row.seedInside = false;
row.directInside = false;
row.adaptiveInside = false;
row.previousAdaptiveInside = false;
row.distanceToPreviousAdaptive = nan;
end

function saveBasinFigure(outDir, mu, f, CpScan, residual, rows, seedCp, directCp, adaptiveCp, previousAdaptiveCp)
fig = figure('Visible', 'off');
h = [];
labels = {};
h(end+1) = semilogy(CpScan, residual, 'LineWidth', 1.2); %#ok<AGROW>
labels{end+1} = 'residual'; %#ok<AGROW>
hold on;
mask100 = [rows.thresholdFactor] == 100;
if any(mask100)
    r = rows(mask100);
    yl = ylim;
    for i = 1:numel(r)
        patch([r(i).basinCpMin r(i).basinCpMax r(i).basinCpMax r(i).basinCpMin], ...
            [yl(1) yl(1) yl(2) yl(2)], [0.8 0.8 0.8], ...
            'FaceAlpha', 0.18, 'EdgeColor', 'none');
    end
    uistack(h(1), 'top');
end
[h, labels] = addCpLine(h, labels, seedCp, 'seed Cp', '--');
[h, labels] = addCpLine(h, labels, directCp, 'direct A0 Cp', '-.');
[h, labels] = addCpLine(h, labels, adaptiveCp, 'adaptive A0 Cp', ':');
[h, labels] = addCpLine(h, labels, previousAdaptiveCp, 'previous adaptive Cp', '--');
grid on;
xlabel('Cp [m/s]');
ylabel('mRLFE residual');
title(sprintf('A0 low-residual basins: mu = %.0f kPa, f = %.1f Hz', mu/1e3, f));
if ~isempty(h)
    legend(h, labels, 'Location', 'best');
end
figFile = fullfile(outDir, sprintf('a0_basins_mu_%06.1f_kPa_f_%08.1f_Hz.png', mu/1e3, f));
saveas(fig, figFile);
close(fig);
end

function [h, labels] = addCpLine(h, labels, cp, labelText, lineStyle)
if isfinite(cp) && cp > 0
    yl = ylim;
    h(end+1) = plot([cp cp], yl, lineStyle, 'LineWidth', 1.0); %#ok<AGROW>
    labels{end+1} = labelText; %#ok<AGROW>
end
end

function row = makeEmptyCaseSummary()
row = struct();
row.mu_kPa = nan;
row.TotalPoints = nan;
row.DirectValidPoints = nan;
row.DirectValidFraction = nan;
row.DirectLastValidHz = nan;
row.DirectMaxJumpRelative = nan;
row.AdaptiveValidPoints = nan;
row.AdaptiveValidFraction = nan;
row.AdaptiveLastValidHz = nan;
row.AdaptiveMaxJumpRelative = nan;
row.AdaptiveCutFrequencyHz = nan;
row.AdaptiveCutReason = "none";
end

function row = summarizeCase(mu, frequency, directA0, adaptiveA0)
row = makeEmptyCaseSummary();
row.mu_kPa = mu/1e3;
row.TotalPoints = numel(frequency);
[row.DirectValidPoints, row.DirectValidFraction, row.DirectLastValidHz, row.DirectMaxJumpRelative] = branchStats(frequency, directA0);
[row.AdaptiveValidPoints, row.AdaptiveValidFraction, row.AdaptiveLastValidHz, row.AdaptiveMaxJumpRelative] = branchStats(frequency, adaptiveA0);
if isfield(adaptiveA0, 'adaptiveCut')
    row.AdaptiveCutFrequencyHz = adaptiveA0.adaptiveCut.FirstCutFrequency;
    row.AdaptiveCutReason = adaptiveA0.adaptiveCut.CutReason;
end
end

function [nValid, validFraction, lastValidHz, maxJump] = branchStats(frequency, branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
nValid = nnz(valid);
validFraction = nValid / numel(cp);
if any(valid)
    lastValidHz = frequency(find(valid, 1, 'last'));
else
    lastValidHz = nan;
end
cpValid = cp(valid);
if numel(cpValid) >= 2
    maxJump = max(abs(diff(cpValid)) ./ max(abs(cpValid(1:end-1)), eps));
else
    maxJump = 0;
end
end
