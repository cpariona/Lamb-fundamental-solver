% Compare mRLFE tracker with a brute-force residual/condition scan.
% Diagnostic only: does not change solver internals.

startup();

branchName = "A0Like";              % "A0Like" or "S0Like"
modelName  = "mRLFEElasticRealK";   % "mRLFEElasticRealK" or "mRLFEHanViscoRealK"

params = defaultParams();
params.E = 100e3;
params.nu = 0.4999;
params.CL = 1500;
params.rho = 1050;
params.thickness = 0.5e-3;
params.fmin = 500;
params.fmax = 16000;
params.numFrequencyPoints = 120;
params.frequencySpacing = "hybrid";

options = defaultOptions("Balanced");
options.computeA0 = branchName == "A0Like";
options.computeS0 = branchName == "S0Like";
options.computeMRLFERealK = true;
options.computeMRLFEHanViscoRealK = modelName == "mRLFEHanViscoRealK";
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = branchName == "A0Like";
options.mrlfeComputeS0Like = branchName == "S0Like";
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = 0.1;

CpMin = 0.25;
CpMax = 80;
CpScanPoints = 6000;
numPeaksToShow = 5;

fprintf('\n=== mRLFE tracker vs brute-force residual/condition scan ===\n');
fprintf('Model: %s | Branch: %s\n', modelName, branchName);
fprintf('E = %.3g kPa | thickness = %.3g mm | nu = %.5f\n', params.E/1e3, params.thickness*1e3, params.nu);

tic;
results = computeFundamentalLambModes(params, options);
solverTime = toc;

branch = results.models.(modelName).branches.(branchName);
validMask = getValidMask(branch);
validIndex = find(validMask & isfinite(branch.Cp));

% Use a small set of representative frequencies. This keeps the brute-force
% diagnostic fast enough for review while still showing agreement across band.
if numel(validIndex) >= 7
    sampleIndex = round(linspace(validIndex(1), validIndex(end), 7));
else
    sampleIndex = validIndex(:).';
end

material = results.material;
geometry = results.geometry;
mrlfeParams = results.models.(modelName).parameters;
CpScan = linspace(CpMin, CpMax, CpScanPoints);

solverCp = nan(numel(sampleIndex),1);
scanBestCp = nan(numel(sampleIndex),1);
scanBestResidual = nan(numel(sampleIndex),1);
nearestPeakCp = nan(numel(sampleIndex),1);
nearestPeakResidual = nan(numel(sampleIndex),1);
numLocalMinima = nan(numel(sampleIndex),1);
freq = nan(numel(sampleIndex),1);
scanSeconds = nan(numel(sampleIndex),1);

figure('Name','mRLFE tracker vs condition/residual scan','Color','w');
tiledlayout(numel(sampleIndex),1,'TileSpacing','compact','Padding','compact');

for ii = 1:numel(sampleIndex)
    idx = sampleIndex(ii);
    freq(ii) = branch.frequency(idx);
    omega = branch.omega(idx);
    solverCp(ii) = branch.Cp(idx);

    tLocal = tic;
    residual = nan(size(CpScan));
    for jj = 1:numel(CpScan)
        k = omega / CpScan(jj);
        residual(jj) = mrlfeResidual(k, omega, material, geometry, mrlfeParams);
    end
    scanSeconds(ii) = toc(tLocal);

    localIdx = find(isLocalMinimum(residual));
    localIdx = localIdx(isfinite(residual(localIdx)));
    numLocalMinima(ii) = numel(localIdx);

    [scanBestResidual(ii), bestIdx] = min(residual);
    scanBestCp(ii) = CpScan(bestIdx);

    if ~isempty(localIdx)
        [~, nearPos] = min(abs(CpScan(localIdx) - solverCp(ii)));
        nearIdx = localIdx(nearPos);
        nearestPeakCp(ii) = CpScan(nearIdx);
        nearestPeakResidual(ii) = residual(nearIdx);
    end

    nexttile;
    semilogy(CpScan, residual, 'k-', 'LineWidth', 1.1); hold on;
    if ~isempty(localIdx)
        [~, order] = sort(residual(localIdx), 'ascend');
        shown = localIdx(order(1:min(numPeaksToShow,numel(order))));
        semilogy(CpScan(shown), residual(shown), 'bo', 'MarkerSize', 4);
    end
    xline(solverCp(ii), 'r-', 'LineWidth', 1.5);
    if isfinite(nearestPeakCp(ii))
        xline(nearestPeakCp(ii), 'g--', 'LineWidth', 1.2);
    end
    grid on;
    ylabel(sprintf('%.0f Hz', freq(ii)));
    if ii == 1
        title('black: residual scan | blue: local minima | red: solver Cp | green: nearest local minimum');
    end
    if ii == numel(sampleIndex)
        xlabel('Cp [m/s]');
    end
end

totalBruteTime = sum(scanSeconds);
comparison = table(freq, solverCp, nearestPeakCp, abs(nearestPeakCp-solverCp), ...
    scanBestCp, scanBestResidual, nearestPeakResidual, numLocalMinima, scanSeconds, ...
    'VariableNames', {'Frequency_Hz','SolverCp','NearestLocalMinCp','AbsCpDifference', ...
    'GlobalMinCp','GlobalMinResidual','NearestLocalMinResidual','NumLocalMinima','BruteForceSeconds'});

disp(comparison);
fprintf('\nTiming summary\n');
fprintf('  Current solver, full branch: %.3f s\n', solverTime);
fprintf('  Brute-force scan, %d selected frequencies only: %.3f s\n', numel(sampleIndex), totalBruteTime);
fprintf('  Estimated brute-force time for all %d branch points: %.3f s\n', numel(branch.frequency), mean(scanSeconds)*numel(branch.frequency));
fprintf('\nInterpretation:\n');
fprintf('  - If red and green lines coincide, the tracker is on a true local singular/residual minimum.\n');
fprintf('  - A global minimum far from red indicates why global-minimum tracking is unsafe.\n');
fprintf('  - Brute-force scanning is useful diagnostically, but much slower when extended to all frequencies.\n');

assignin('base','MRLFETrackerComparison',comparison);

function mask = getValidMask(branch)
if isfield(branch,'validCp')
    mask = branch.validCp;
elseif isfield(branch,'valid')
    mask = branch.valid;
else
    mask = isfinite(branch.Cp);
end
mask = mask & isfinite(branch.Cp);
end

function tf = isLocalMinimum(x)
tf = false(size(x));
for i = 2:numel(x)-1
    tf(i) = isfinite(x(i)) && x(i) < x(i-1) && x(i) < x(i+1);
end
end
