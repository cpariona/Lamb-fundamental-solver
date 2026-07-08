clear; clc; close all;
startup

fprintf('\nA0 mRLFE atlas policy mu-sweep diagnostic\n');
fprintf('----------------------------------------\n');

muValues = [50e3 100e3 158e3 250e3 500e3];
numCases = numel(muValues);
summary = repmat(makeEmptySummaryRow(), numCases, 1);
results = cell(numCases, 1);

for i = 1:numCases
    mu = muValues(i);
    fprintf('\nCase %d/%d: mu = %.3f kPa\n', i, numCases, mu/1e3);
    [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu);

    directOptions = makeAtlasOptions(false);
    directResult = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, directOptions);

    seedA0 = buildNeutralSeed("A0Like", frequency, material, geometry, seedModes);
    adaptiveA0 = trackNeutralBranch("A0Like", seedA0, material, geometry, mrlfeParams, makeA0AdaptiveOptions());
    adaptiveA0.solverRoute = "a0AdaptiveDiagnostic";
    adaptiveA0.atlasUnifiedPolicy = "viscousA0AdaptiveContinuationDiagnostic";

    results{i} = struct('params', params, 'direct', directResult, 'adaptiveA0', adaptiveA0);
    summary(i) = summarizeCase(mu, frequency, directResult.branches.A0Like, adaptiveA0);

    fprintf('  Direct A0   : valid %d/%d, maxJump %.5f, last %.3f Hz\n', ...
        summary(i).DirectValidPoints, summary(i).TotalPoints, summary(i).DirectMaxJumpRelative, summary(i).DirectLastValidHz);
    fprintf('  Adaptive A0 : valid %d/%d, maxJump %.5f, last %.3f Hz, maxWindow %.2f, cut %s at %.3f Hz, valleyFallback %d\n', ...
        summary(i).AdaptiveValidPoints, summary(i).TotalPoints, summary(i).AdaptiveMaxJumpRelative, ...
        summary(i).AdaptiveLastValidHz, summary(i).AdaptiveMaxWindow, string(summary(i).AdaptiveCutReason), ...
        summary(i).AdaptiveCutFrequencyHz, summary(i).AdaptiveValleyFallbackCount);
end

summaryTable = struct2table(summary);
disp(summaryTable);

outDir = fullfile(pwd, 'outputs', 'mrlfe');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
outFile = fullfile(outDir, 'mrlfe_a0_adaptive_policy_mu_sweep.mat');
save(outFile, 'muValues', 'summaryTable', 'summary', 'results');
fprintf('\nSaved A0 policy diagnostic to:\n%s\n', outFile);

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

function options = makeAtlasOptions(useAdaptiveA0)
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
options.mrlfeUseAdaptiveA0AtlasTracker = useAdaptiveA0;
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
row.DirectValidFraction = nan;
row.DirectFirstValidHz = nan;
row.DirectLastValidHz = nan;
row.DirectMaxJumpRelative = nan;
row.DirectResidualMax = nan;
row.DirectResidualP95 = nan;
row.AdaptiveValidPoints = nan;
row.AdaptiveValidFraction = nan;
row.AdaptiveFirstValidHz = nan;
row.AdaptiveLastValidHz = nan;
row.AdaptiveMaxJumpRelative = nan;
row.AdaptiveResidualMax = nan;
row.AdaptiveResidualP95 = nan;
row.AdaptiveMinWindow = nan;
row.AdaptiveMedianWindow = nan;
row.AdaptiveMaxWindow = nan;
row.AdaptiveValleyFallbackCount = nan;
row.AdaptiveCutIndex = nan;
row.AdaptiveCutFrequencyHz = nan;
row.AdaptiveCutReason = "none";
end

function row = summarizeCase(mu, frequency, directA0, adaptiveA0)
row = makeEmptySummaryRow();
row.mu_kPa = mu / 1e3;
row.TotalPoints = numel(frequency);
row = summarizeBranch(row, 'Direct', directA0, frequency);
row = summarizeBranch(row, 'Adaptive', adaptiveA0, frequency);
if isfield(adaptiveA0, 'adaptiveWindowUsed')
    w = adaptiveA0.adaptiveWindowUsed(:);
    validW = w(isfinite(w));
    if ~isempty(validW)
        row.AdaptiveMinWindow = min(validW);
        row.AdaptiveMedianWindow = median(validW);
        row.AdaptiveMaxWindow = max(validW);
    end
end
if isfield(adaptiveA0, 'candidateType')
    row.AdaptiveValleyFallbackCount = nnz(string(adaptiveA0.candidateType(:)) == "valleyFallback");
end
if isfield(adaptiveA0, 'adaptiveCut')
    row.AdaptiveCutIndex = adaptiveA0.adaptiveCut.FirstCutIndex;
    row.AdaptiveCutFrequencyHz = adaptiveA0.adaptiveCut.FirstCutFrequency;
    row.AdaptiveCutReason = adaptiveA0.adaptiveCut.CutReason;
end
end

function row = summarizeBranch(row, prefix, branch, freq)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
res = nan(size(cp));
if isfield(branch, 'residual')
    res = branch.residual(:);
end
validCp = cp(valid);
validRes = res(valid & isfinite(res));

row.([prefix 'ValidPoints']) = nnz(valid);
row.([prefix 'ValidFraction']) = nnz(valid) / numel(cp);
if any(valid)
    row.([prefix 'FirstValidHz']) = freq(find(valid, 1, 'first'));
    row.([prefix 'LastValidHz']) = freq(find(valid, 1, 'last'));
end
if numel(validCp) >= 2
    row.([prefix 'MaxJumpRelative']) = max(abs(diff(validCp)) ./ max(abs(validCp(1:end-1)), eps));
else
    row.([prefix 'MaxJumpRelative']) = 0;
end
if ~isempty(validRes)
    row.([prefix 'ResidualMax']) = max(validRes);
    row.([prefix 'ResidualP95']) = percentile(validRes, 95);
end
end

function p = percentile(x, q)
x = sort(x(:));
x = x(isfinite(x));
if isempty(x)
    p = nan;
    return;
end
idx = 1 + (numel(x)-1) * q / 100;
lo = floor(idx);
hi = ceil(idx);
if lo == hi
    p = x(lo);
else
    p = x(lo) + (idx-lo) * (x(hi)-x(lo));
end
end
