clear; clc; close all;
startup

fprintf('\nA0 mRLFE physical-corridor diagnostic\n');
fprintf('-------------------------------------\n');

muValues = [50e3 100e3 158e3 250e3 500e3];
numCases = numel(muValues);
summary = repmat(makeEmptySummaryRow(), numCases, 1);
results = cell(numCases, 1);

for i = 1:numCases
    mu = muValues(i);
    fprintf('\nCase %d/%d: mu = %.3f kPa\n', i, numCases, mu/1e3);
    [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu);

    directResult = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, makeDirectOptions());
    seedA0 = buildNeutralSeed("A0Like", frequency, material, geometry, seedModes);
    adaptiveA0 = trackNeutralBranch("A0Like", seedA0, material, geometry, mrlfeParams, makeAdaptiveA0Options());

    corridorOptions = struct();
    corridorOptions.minRatioToGuide = 0.70;
    corridorOptions.maxRatioToGuide = inf;
    corridorOptions.minFrequencyHz = 1000;
    corridorOptions.minValidRunBeforeCut = 8;
    corridorOptions.maxLocalDropRelative = 0.05;
    corridorOptions.maxTwoStepDropRelative = 0.10;
    guidedA0 = mrlfeEvaluatePhysicalTail(adaptiveA0, seedModes.A0.Cp, frequency, corridorOptions);

    results{i} = struct('params', params, 'direct', directResult, ...
        'adaptiveA0', adaptiveA0, 'guidedA0', guidedA0, 'seedA0', seedModes.A0);
    summary(i) = summarizeCase(mu, frequency, directResult.branches.A0Like, adaptiveA0, guidedA0);

    fprintf('  Direct A0   : valid %d/%d, last %.3f Hz, maxJump %.5f\n', ...
        summary(i).DirectValidPoints, summary(i).TotalPoints, summary(i).DirectLastValidHz, summary(i).DirectMaxJumpRelative);
    fprintf('  Adaptive A0 : valid %d/%d, last %.3f Hz, maxJump %.5f\n', ...
        summary(i).AdaptiveValidPoints, summary(i).TotalPoints, summary(i).AdaptiveLastValidHz, summary(i).AdaptiveMaxJumpRelative);
    fprintf('  Guided A0   : valid %d/%d, last %.3f Hz, maxJump %.5f, cut %s at %.3f Hz\n', ...
        summary(i).GuidedValidPoints, summary(i).TotalPoints, summary(i).GuidedLastValidHz, summary(i).GuidedMaxJumpRelative, ...
        string(summary(i).GuidedCutReason), summary(i).GuidedCutFrequencyHz);
end

summaryTable = struct2table(summary);
disp(summaryTable);

outDir = fullfile(pwd, 'outputs', 'mrlfe');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
outFile = fullfile(outDir, 'mrlfe_a0_physical_corridor_mu_sweep.mat');
save(outFile, 'muValues', 'summaryTable', 'summary', 'results');
fprintf('\nSaved A0 physical-corridor diagnostic to:\n%s\n', outFile);

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

function options = makeAdaptiveA0Options()
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
options.mrlfeAdaptiveAllowValleyFallback = true;
options.mrlfeAdaptiveValleyFallbackRelativeWindow = 0.10;
options.mrlfeAdaptiveValleyFallbackPredictionWeight = 65.0;
options.mrlfeAdaptiveValleyFallbackResidualWeight = 0.30;
options.mrlfeResidualTolerance = 1e-3;
end

function seed = buildNeutralSeed(branchName, frequency, material, geometry, seedModes)
problem = struct('frequencySolve_Hz', frequency(:), ...
    'material', material, 'geometry', geometry, 'seedModes', seedModes);
configuration = struct('branch', string(branchName));
seed = mrlfeBuildSeed(problem, configuration);
end

function branch = trackNeutralBranch(branchName, seedMode, material, geometry, mrlfeParams, options)
problem = struct('material', material, 'geometry', geometry);
configuration = struct('branch', string(branchName));
branch = mrlfeTrackBranchAdaptive(problem, seedMode, configuration, mrlfeParams, options);
end

function row = makeEmptySummaryRow()
row = struct();
row.mu_kPa = nan;
row.TotalPoints = nan;
row.DirectValidPoints = nan;
row.DirectLastValidHz = nan;
row.DirectMaxJumpRelative = nan;
row.AdaptiveValidPoints = nan;
row.AdaptiveLastValidHz = nan;
row.AdaptiveMaxJumpRelative = nan;
row.GuidedValidPoints = nan;
row.GuidedLastValidHz = nan;
row.GuidedMaxJumpRelative = nan;
row.GuidedMinRatio = nan;
row.GuidedMedianRatio = nan;
row.GuidedMaxLocalDrop = nan;
row.GuidedMaxTwoStepDrop = nan;
row.GuidedCutFrequencyHz = nan;
row.GuidedCutReason = "none";
end

function row = summarizeCase(mu, frequency, directA0, adaptiveA0, guidedA0)
row = makeEmptySummaryRow();
row.mu_kPa = mu/1e3;
row.TotalPoints = numel(frequency);
[row.DirectValidPoints, row.DirectLastValidHz, row.DirectMaxJumpRelative] = branchStats(frequency, directA0);
[row.AdaptiveValidPoints, row.AdaptiveLastValidHz, row.AdaptiveMaxJumpRelative] = branchStats(frequency, adaptiveA0);
[row.GuidedValidPoints, row.GuidedLastValidHz, row.GuidedMaxJumpRelative] = branchStats(frequency, guidedA0);
validGuided = isfinite(guidedA0.Cp(:)) & guidedA0.Cp(:) > 0;
if isfield(guidedA0, 'guideRatio')
    r = guidedA0.guideRatio(:);
    valid = validGuided & isfinite(r);
    if any(valid)
        row.GuidedMinRatio = min(r(valid));
        row.GuidedMedianRatio = median(r(valid));
    end
end
if isfield(guidedA0, 'localDropRelative')
    d = guidedA0.localDropRelative(:);
    valid = validGuided & isfinite(d);
    if any(valid)
        row.GuidedMaxLocalDrop = max(d(valid));
    end
end
if isfield(guidedA0, 'twoStepDropRelative')
    d = guidedA0.twoStepDropRelative(:);
    valid = validGuided & isfinite(d);
    if any(valid)
        row.GuidedMaxTwoStepDrop = max(d(valid));
    end
end
if isfield(guidedA0, 'physicalCorridor')
    row.GuidedCutFrequencyHz = guidedA0.physicalCorridor.FirstCutFrequency;
    row.GuidedCutReason = guidedA0.physicalCorridor.CutReason;
end
end

function [nValid, lastValidHz, maxJump] = branchStats(frequency, branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
nValid = nnz(valid);
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
