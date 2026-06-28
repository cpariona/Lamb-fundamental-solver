clear; clc; close all;
startup

fprintf('\nA0 mRLFE policy parametric sweep diagnostic\n');
fprintf('--------------------------------------------\n');

muValues = [30e3 50e3 75e3 100e3 158e3 250e3 500e3];
etaSValues = [0.01 0.03 0.05 0.10];
thicknessValues = [0.3e-3 0.5e-3 1.0e-3];

numCases = numel(muValues) * numel(etaSValues) * numel(thicknessValues);
summary = repmat(makeEmptySummaryRow(), numCases, 1);
results = cell(numCases, 1);
caseIndex = 0;

for ih = 1:numel(thicknessValues)
    thickness = thicknessValues(ih);
    for ie = 1:numel(etaSValues)
        etaS = etaSValues(ie);
        for im = 1:numel(muValues)
            mu = muValues(im);
            caseIndex = caseIndex + 1;
            fprintf('\nCase %d/%d: h = %.3f mm, etaS = %.3f, mu = %.3f kPa\n', ...
                caseIndex, numCases, thickness*1e3, etaS, mu/1e3);

            [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu, etaS, thickness);
            delayedResult = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, makeOptions("delayedCut"));
            adaptiveResult = computeMRLFE(frequency, material, geometry, seedModes, mrlfeParams, makeOptions("adaptivePhysicalTail"));

            results{caseIndex} = struct( ...
                'params', params, ...
                'delayedResult', delayedResult, ...
                'adaptiveResult', adaptiveResult, ...
                'seedModes', seedModes);
            summary(caseIndex) = summarizeCase(mu, etaS, thickness, frequency, delayedResult, adaptiveResult);

            fprintf('  delayed : valid %d/%d, last %.3f Hz, maxJump %.5f\n', ...
                summary(caseIndex).DelayedValidPoints, summary(caseIndex).TotalPoints, ...
                summary(caseIndex).DelayedLastValidHz, summary(caseIndex).DelayedMaxJumpRelative);
            fprintf('  adaptive: valid %d/%d, last %.3f Hz, maxJump %.5f, cut %s at %.3f Hz\n', ...
                summary(caseIndex).AdaptiveValidPoints, summary(caseIndex).TotalPoints, ...
                summary(caseIndex).AdaptiveLastValidHz, summary(caseIndex).AdaptiveMaxJumpRelative, ...
                string(summary(caseIndex).AdaptiveCutReason), summary(caseIndex).AdaptiveCutFrequencyHz);
        end
    end
end

summaryTable = struct2table(summary);
aggregate = summarizeAggregate(summaryTable);
aggregateTable = struct2table(aggregate);
disp(summaryTable);
fprintf('\nAggregate A0 policy comparison:\n');
disp(aggregateTable);

outDir = fullfile(pwd, 'outputs', 'mrlfe');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
outFile = fullfile(outDir, 'mrlfe_a0_policy_parametric_sweep.mat');
save(outFile, 'muValues', 'etaSValues', 'thicknessValues', 'summaryTable', 'aggregateTable', 'summary', 'aggregate', 'results');
fprintf('\nSaved A0 policy parametric sweep diagnostic to:\n%s\n', outFile);

function [params, material, geometry, frequency, seedModes, mrlfeParams] = buildCase(mu, etaS, thickness)
params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = mu;
params.nu = 0.4999;
params.thickness = thickness;
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
mrlfeParams.etaS = etaS;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;
end

function options = makeOptions(a0Policy)
options = rlDefaultOptions("Fast");
options.mrlfeUseUnifiedAtlasRoute = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.computeMRLFEComplexK = false;
options.computeMRLFEViscoComplexK = false;
options.mrlfeA0Policy = string(a0Policy);
options.mrlfeViscoAtlasCpScanPoints = 900;
options.mrlfeA0DPCandidates = 8;
options.mrlfeA0DPRefineCandidates = true;
options.mrlfeDelayedCutMinValidRun = 8;
options.mrlfeDelayedCutPreviousCpMaxRelativeJump = 0.18;
options.mrlfeDelayedCutResidualTolerance = 1e-3;
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
options.mrlfeA0PhysicalMinRatioToGuide = 0.70;
options.mrlfeA0PhysicalMinFrequencyHz = 1000;
options.mrlfeA0PhysicalMinValidRunBeforeCut = 8;
options.mrlfeA0PhysicalMaxLocalDropRelative = 0.05;
options.mrlfeA0PhysicalMaxTwoStepDropRelative = 0.10;
options.mrlfeResidualTolerance = 1e-3;
end

function row = makeEmptySummaryRow()
row = struct();
row.mu_kPa = nan;
row.etaS = nan;
row.thickness_mm = nan;
row.TotalPoints = nan;
row.DelayedPolicy = "none";
row.DelayedValidPoints = nan;
row.DelayedValidFraction = nan;
row.DelayedLastValidHz = nan;
row.DelayedMaxJumpRelative = nan;
row.DelayedResidualP95 = nan;
row.AdaptivePolicy = "none";
row.AdaptiveValidPoints = nan;
row.AdaptiveValidFraction = nan;
row.AdaptiveLastValidHz = nan;
row.AdaptiveMaxJumpRelative = nan;
row.AdaptiveResidualP95 = nan;
row.AdaptiveMinRatio = nan;
row.AdaptiveMedianRatio = nan;
row.AdaptiveValleyFallbackCount = nan;
row.AdaptiveCutFrequencyHz = nan;
row.AdaptiveCutReason = "none";
row.ValidPointGain = nan;
row.LastValidGainHz = nan;
row.MaxJumpReduction = nan;
end

function row = summarizeCase(mu, etaS, thickness, frequency, delayedResult, adaptiveResult)
row = makeEmptySummaryRow();
row.mu_kPa = mu / 1e3;
row.etaS = etaS;
row.thickness_mm = thickness * 1e3;
row.TotalPoints = numel(frequency);

if isfield(delayedResult.branches, 'A0Like')
    a0 = delayedResult.branches.A0Like;
    row.DelayedPolicy = getBranchPolicy(a0);
    s = branchStats(frequency, a0);
    row.DelayedValidPoints = s.validPoints;
    row.DelayedValidFraction = s.validFraction;
    row.DelayedLastValidHz = s.lastValidHz;
    row.DelayedMaxJumpRelative = s.maxJumpRelative;
    row.DelayedResidualP95 = s.residualP95;
end

if isfield(adaptiveResult.branches, 'A0Like')
    a0 = adaptiveResult.branches.A0Like;
    row.AdaptivePolicy = getBranchPolicy(a0);
    s = branchStats(frequency, a0);
    row.AdaptiveValidPoints = s.validPoints;
    row.AdaptiveValidFraction = s.validFraction;
    row.AdaptiveLastValidHz = s.lastValidHz;
    row.AdaptiveMaxJumpRelative = s.maxJumpRelative;
    row.AdaptiveResidualP95 = s.residualP95;
    if isfield(a0, 'guideRatio')
        r = a0.guideRatio(:);
        valid = isfinite(a0.Cp(:)) & a0.Cp(:) > 0 & isfinite(r);
        if isfield(a0, 'validCp')
            valid = valid & logical(a0.validCp(:));
        end
        if any(valid)
            row.AdaptiveMinRatio = min(r(valid));
            row.AdaptiveMedianRatio = median(r(valid));
        end
    end
    if isfield(a0, 'candidateType')
        row.AdaptiveValleyFallbackCount = nnz(string(a0.candidateType(:)) == "valleyFallback");
    end
    if isfield(a0, 'physicalCorridor')
        row.AdaptiveCutFrequencyHz = a0.physicalCorridor.FirstCutFrequency;
        row.AdaptiveCutReason = a0.physicalCorridor.CutReason;
    end
end

row.ValidPointGain = row.AdaptiveValidPoints - row.DelayedValidPoints;
row.LastValidGainHz = row.AdaptiveLastValidHz - row.DelayedLastValidHz;
row.MaxJumpReduction = row.DelayedMaxJumpRelative - row.AdaptiveMaxJumpRelative;
end

function aggregate = summarizeAggregate(summaryTable)
aggregate = struct();
aggregate.TotalCases = height(summaryTable);
aggregate.AdaptiveBetterValidPoints = nnz(summaryTable.ValidPointGain > 0);
aggregate.AdaptiveEqualValidPoints = nnz(summaryTable.ValidPointGain == 0);
aggregate.AdaptiveWorseValidPoints = nnz(summaryTable.ValidPointGain < 0);
aggregate.MedianValidPointGain = median(summaryTable.ValidPointGain, 'omitnan');
aggregate.MedianLastValidGainHz = median(summaryTable.LastValidGainHz, 'omitnan');
aggregate.MedianMaxJumpReduction = median(summaryTable.MaxJumpReduction, 'omitnan');
aggregate.CutCases = nnz(~isnan(summaryTable.AdaptiveCutFrequencyHz));
aggregate.ValleyFallbackCases = nnz(summaryTable.AdaptiveValleyFallbackCount > 0);
aggregate.MedianValleyFallbackCount = median(summaryTable.AdaptiveValleyFallbackCount, 'omitnan');
end

function policy = getBranchPolicy(branch)
if isfield(branch, 'atlasUnifiedPolicy')
    policy = branch.atlasUnifiedPolicy;
else
    policy = "none";
end
end

function s = branchStats(frequency, branch)
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
cpValid = cp(valid);
resValid = res(valid & isfinite(res));
s = struct();
s.validPoints = nnz(valid);
s.validFraction = nnz(valid) / numel(cp);
if any(valid)
    s.lastValidHz = frequency(find(valid, 1, 'last'));
else
    s.lastValidHz = nan;
end
if numel(cpValid) >= 2
    s.maxJumpRelative = max(abs(diff(cpValid)) ./ max(abs(cpValid(1:end-1)), eps));
else
    s.maxJumpRelative = 0;
end
if ~isempty(resValid)
    s.residualP95 = percentile(resValid, 95);
else
    s.residualP95 = nan;
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
