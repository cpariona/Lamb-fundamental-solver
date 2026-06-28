clear; clc; close all;
startup

fprintf('\nUnified mRLFE atlas mu-sweep diagnostic\n');
fprintf('--------------------------------------\n');

muValues = [50e3 100e3 158e3 250e3 500e3];
numCases = numel(muValues);

summary = repmat(makeEmptySummaryRow(), numCases, 1);
results = cell(numCases, 1);

for i = 1:numCases
    mu = muValues(i);
    fprintf('\nCase %d/%d: mu = %.3f kPa\n', i, numCases, mu/1e3);

    [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu);

    defaultOptions = makeAtlasOptions("delayedCut");
    adaptiveOptions = makeAtlasOptions("adaptivePhysicalTail");

    defaultResult = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, defaultOptions);
    adaptiveResult = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, adaptiveOptions);

    results{i} = struct( ...
        'params', params, ...
        'defaultResult', defaultResult, ...
        'adaptiveResult', adaptiveResult, ...
        'seedModes', seedModes);
    summary(i) = summarizeCase(mu, frequency, defaultResult, adaptiveResult);

    fprintf('  A0 default : valid %d/%d, last %.3f Hz, maxJump %.5f, policy %s\n', ...
        summary(i).A0DefaultValidPoints, summary(i).TotalPoints, summary(i).A0DefaultLastValidHz, ...
        summary(i).A0DefaultMaxJumpRelative, string(summary(i).A0DefaultPolicy));
    fprintf('  A0 adaptive: valid %d/%d, last %.3f Hz, maxJump %.5f, cut %s at %.3f Hz\n', ...
        summary(i).A0AdaptiveValidPoints, summary(i).TotalPoints, summary(i).A0AdaptiveLastValidHz, ...
        summary(i).A0AdaptiveMaxJumpRelative, string(summary(i).A0AdaptiveCutReason), summary(i).A0AdaptiveCutFrequencyHz);
    fprintf('  S0 adaptive: valid %d/%d, last %.3f Hz, maxJump %.5f, maxWindow %.2f, cut %s at %.3f Hz\n', ...
        summary(i).S0ValidPoints, summary(i).TotalPoints, summary(i).S0LastValidHz, summary(i).S0MaxJumpRelative, ...
        summary(i).S0MaxAdaptiveWindow, string(summary(i).S0CutReason), summary(i).S0CutFrequencyHz);
end

summaryTable = struct2table(summary);
disp(summaryTable);

outDir = fullfile(pwd, 'outputs', 'mrlfe');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
outFile = fullfile(outDir, 'mrlfe_unified_atlas_mu_sweep.mat');
save(outFile, 'muValues', 'summaryTable', 'summary', 'results');
fprintf('\nSaved mu-sweep diagnostic to:\n%s\n', outFile);

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

function atlasOptions = makeAtlasOptions(a0Policy)
atlasOptions = rlDefaultOptions("Fast");
atlasOptions.mrlfeUseUnifiedAtlasRoute = true;
atlasOptions.mrlfeComputeA0Like = true;
atlasOptions.mrlfeComputeS0Like = true;
atlasOptions.computeMRLFEComplexK = false;
atlasOptions.computeMRLFEViscoComplexK = false;
atlasOptions.mrlfeA0Policy = string(a0Policy);
atlasOptions.mrlfeViscoAtlasCpScanPoints = 900;
atlasOptions.mrlfeA0DPCandidates = 8;
atlasOptions.mrlfeA0DPRefineCandidates = true;
atlasOptions.mrlfeDelayedCutMinValidRun = 8;
atlasOptions.mrlfeDelayedCutPreviousCpMaxRelativeJump = 0.18;
atlasOptions.mrlfeDelayedCutResidualTolerance = 1e-3;
atlasOptions.mrlfeUseAdaptiveS0AtlasTracker = true;
atlasOptions.mrlfeAdaptiveWindows = [0.12 0.20 0.35 0.50];
atlasOptions.mrlfeAdaptiveCpScanPoints = 900;
atlasOptions.mrlfeAdaptiveEdgeGuardPoints = 4;
atlasOptions.mrlfeAdaptiveRefineCandidates = true;
atlasOptions.mrlfeAdaptiveMaxJumpRelative = 0.18;
atlasOptions.mrlfeAdaptiveMaxPredictionError = 0.18;
atlasOptions.mrlfeAdaptivePredictionWeight = 55.0;
atlasOptions.mrlfeAdaptiveResidualWeight = 0.35;
atlasOptions.mrlfeAdaptiveEstablishedMinValidRun = 8;
atlasOptions.mrlfeAdaptiveCutAfterEstablishedLoss = true;
atlasOptions.mrlfeResidualTolerance = 1e-3;
atlasOptions.mrlfeViscoS0ModalCpWindow = [0.45, 1.40];

if string(a0Policy) == "adaptivePhysicalTail"
    atlasOptions.mrlfeUseA0PhysicalTailCut = true;
    atlasOptions.mrlfeAdaptiveWindows = [0.20 0.35 0.50 0.80 1.20];
    atlasOptions.mrlfeAdaptiveMaxJumpRelative = 0.12;
    atlasOptions.mrlfeAdaptiveMaxPredictionError = 0.12;
    atlasOptions.mrlfeAdaptivePredictionWeight = 45.0;
    atlasOptions.mrlfeAdaptiveResidualWeight = 0.45;
    atlasOptions.mrlfeAdaptiveAllowValleyFallback = true;
    atlasOptions.mrlfeAdaptiveValleyFallbackRelativeWindow = 0.10;
    atlasOptions.mrlfeAdaptiveValleyFallbackPredictionWeight = 65.0;
    atlasOptions.mrlfeAdaptiveValleyFallbackResidualWeight = 0.30;
    atlasOptions.mrlfeA0PhysicalMinRatioToGuide = 0.70;
    atlasOptions.mrlfeA0PhysicalMinFrequencyHz = 1000;
    atlasOptions.mrlfeA0PhysicalMinValidRunBeforeCut = 8;
    atlasOptions.mrlfeA0PhysicalMaxLocalDropRelative = 0.05;
    atlasOptions.mrlfeA0PhysicalMaxTwoStepDropRelative = 0.10;
else
    atlasOptions.mrlfeUseA0PhysicalTailCut = false;
end
end

function row = makeEmptySummaryRow()
row = struct();
row.mu_kPa = nan;
row.TotalPoints = nan;
row.A0DefaultPolicy = "none";
row.A0DefaultValidPoints = nan;
row.A0DefaultValidFraction = nan;
row.A0DefaultFirstValidHz = nan;
row.A0DefaultLastValidHz = nan;
row.A0DefaultMaxJumpRelative = nan;
row.A0DefaultResidualMax = nan;
row.A0DefaultResidualP95 = nan;
row.A0AdaptivePolicy = "none";
row.A0AdaptiveValidPoints = nan;
row.A0AdaptiveValidFraction = nan;
row.A0AdaptiveFirstValidHz = nan;
row.A0AdaptiveLastValidHz = nan;
row.A0AdaptiveMaxJumpRelative = nan;
row.A0AdaptiveResidualMax = nan;
row.A0AdaptiveResidualP95 = nan;
row.A0AdaptiveMinRatio = nan;
row.A0AdaptiveMedianRatio = nan;
row.A0AdaptiveValleyFallbackCount = nan;
row.A0AdaptiveCutIndex = nan;
row.A0AdaptiveCutFrequencyHz = nan;
row.A0AdaptiveCutReason = "none";
row.S0ValidPoints = nan;
row.S0ValidFraction = nan;
row.S0FirstValidHz = nan;
row.S0LastValidHz = nan;
row.S0MaxJumpRelative = nan;
row.S0ResidualMax = nan;
row.S0ResidualP95 = nan;
row.S0MinAdaptiveWindow = nan;
row.S0MedianAdaptiveWindow = nan;
row.S0MaxAdaptiveWindow = nan;
row.S0Window012Count = nan;
row.S0Window020Count = nan;
row.S0Window035Count = nan;
row.S0Window050Count = nan;
row.S0CutIndex = nan;
row.S0CutFrequencyHz = nan;
row.S0CutReason = "none";
end

function row = summarizeCase(mu, frequency, defaultResult, adaptiveResult)
row = makeEmptySummaryRow();
row.mu_kPa = mu / 1e3;
freq = frequency(:);
row.TotalPoints = numel(freq);

if isfield(defaultResult.branches, 'A0Like')
    a0 = defaultResult.branches.A0Like;
    row.A0DefaultPolicy = getBranchPolicy(a0);
    row = summarizeBranch(row, 'A0Default', a0, freq);
end
if isfield(adaptiveResult.branches, 'A0Like')
    a0 = adaptiveResult.branches.A0Like;
    row.A0AdaptivePolicy = getBranchPolicy(a0);
    row = summarizeBranch(row, 'A0Adaptive', a0, freq);
    if isfield(a0, 'guideRatio')
        r = a0.guideRatio(:);
        valid = isfinite(a0.Cp(:)) & a0.Cp(:) > 0 & isfinite(r);
        if isfield(a0, 'validCp')
            valid = valid & logical(a0.validCp(:));
        end
        if any(valid)
            row.A0AdaptiveMinRatio = min(r(valid));
            row.A0AdaptiveMedianRatio = median(r(valid));
        end
    end
    if isfield(a0, 'candidateType')
        row.A0AdaptiveValleyFallbackCount = nnz(string(a0.candidateType(:)) == "valleyFallback");
    end
    if isfield(a0, 'physicalCorridor')
        row.A0AdaptiveCutIndex = a0.physicalCorridor.FirstCutIndex;
        row.A0AdaptiveCutFrequencyHz = a0.physicalCorridor.FirstCutFrequency;
        row.A0AdaptiveCutReason = a0.physicalCorridor.CutReason;
    end
end
if isfield(adaptiveResult.branches, 'S0Like')
    s0 = adaptiveResult.branches.S0Like;
    row = summarizeBranch(row, 'S0', s0, freq);
    if isfield(s0, 'adaptiveWindowUsed')
        w = s0.adaptiveWindowUsed(:);
        validW = w(isfinite(w));
        if ~isempty(validW)
            row.S0MinAdaptiveWindow = min(validW);
            row.S0MedianAdaptiveWindow = median(validW);
            row.S0MaxAdaptiveWindow = max(validW);
            row.S0Window012Count = nnz(abs(validW - 0.12) < 1e-12);
            row.S0Window020Count = nnz(abs(validW - 0.20) < 1e-12);
            row.S0Window035Count = nnz(abs(validW - 0.35) < 1e-12);
            row.S0Window050Count = nnz(abs(validW - 0.50) < 1e-12);
        end
    end
    if isfield(s0, 'adaptiveCut')
        row.S0CutIndex = s0.adaptiveCut.FirstCutIndex;
        row.S0CutFrequencyHz = s0.adaptiveCut.FirstCutFrequency;
        row.S0CutReason = s0.adaptiveCut.CutReason;
    end
end
end

function policy = getBranchPolicy(branch)
if isfield(branch, 'atlasUnifiedPolicy')
    policy = branch.atlasUnifiedPolicy;
else
    policy = "none";
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
