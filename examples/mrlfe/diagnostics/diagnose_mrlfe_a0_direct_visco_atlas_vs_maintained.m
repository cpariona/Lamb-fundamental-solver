% Compare A0Like direct-visco atlas policies against the maintained viscous route.
%
% This diagnostic implements the Phase 3 comparison after the start-failure
% diagnostic showed that A0 direct-visco atlas has a valid branch after an
% initial low-frequency missing region.

clear; clc;
startup

fprintf('\n=== A0Like direct-visco atlas vs maintained diagnostic ===\n');

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 32e3;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";

material = rlComputeMaterial(params);
params.E = material.E;
params.K = material.K;
params.CL = material.CL;
params.CT = material.CT;
params.lambda = material.lambda;
params.nu = material.nu;
geometry = rlComputeGeometry(params);
if isfield(geometry, 'halfThickness')
    geometry = rmfield(geometry, 'halfThickness');
end
frequency = rlBuildFrequencyVector(params);

mrlfeParams = defaultMRLFEParams();
mrlfeParams.fluidDensity = 1000;
mrlfeParams.fluidSoundSpeed = 1500;
mrlfeParams.etaS = 0.05;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
mrlfeParams.solveComplexK = false;

referenceOptions = rlDefaultOptions("Fast");
referenceOptions.computeA0 = true;
referenceOptions.computeS0 = false;
referenceOptions.computeMRLFE = false;
referenceOptions.computeMRLFERealK = true;
referenceOptions.computeMRLFEElasticRealK = true;
referenceOptions.computeMRLFEViscoRealK = true;
referenceOptions.computeMRLFEComplexK = false;
referenceOptions.mrlfeComputeA0Like = true;
referenceOptions.mrlfeComputeS0Like = false;
referenceOptions.mrlfeParams = mrlfeParams;

tRef = tic;
rawReference = rlComputeFundamentalLambModes(params, referenceOptions);
referenceTime = toc(tRef);
referenceBranch = rawReference.models.mRLFERealK.branches.A0Like;
seedMode = rawReference.modes.A0;

baseOptions = referenceOptions;
baseOptions.mrlfeParams = mrlfeParams;

cases = struct([]);
cases(1).Name = "baseline_cut";
cases(1).Policy = struct( ...
    'mrlfeViscoA0StopAtFirstMissingModalMinimum', true, ...
    'mrlfeViscoA0PreviousCpMaxRelativeJump', 0.18, ...
    'mrlfeViscoA0ResidualTolerance', 1e-3, ...
    'mrlfeViscoA0ModalCpWindow', [0.35, 2.50]);
cases(1).ApplyDelayedCut = false;

cases(2).Name = "no_start_cut";
cases(2).Policy = struct( ...
    'mrlfeViscoA0StopAtFirstMissingModalMinimum', false, ...
    'mrlfeViscoA0PreviousCpMaxRelativeJump', inf, ...
    'mrlfeViscoA0ResidualTolerance', 1e-3, ...
    'mrlfeViscoA0ModalCpWindow', [0.35, 2.50]);
cases(2).ApplyDelayedCut = false;

cases(3).Name = "delayed_cut";
cases(3).Policy = struct( ...
    'mrlfeViscoA0StopAtFirstMissingModalMinimum', false, ...
    'mrlfeViscoA0PreviousCpMaxRelativeJump', inf, ...
    'mrlfeViscoA0ResidualTolerance', 1e-3, ...
    'mrlfeViscoA0ModalCpWindow', [0.35, 2.50], ...
    'mrlfeDelayedCutMinValidRun', 8, ...
    'mrlfeDelayedCutStopAtFirstMissingAfterValidRun', true, ...
    'mrlfeDelayedCutPreviousCpMaxRelativeJump', 0.18, ...
    'mrlfeDelayedCutResidualTolerance', 1e-3);
cases(3).ApplyDelayedCut = true;

summaryRows = table();
caseResults = struct([]);
for iCase = 1:numel(cases)
    policy = cases(iCase).Policy;
    policy.mrlfeViscoAtlasCpScanPoints = 900;
    policy.mrlfeA0DPCandidates = 8;
    policy.mrlfeA0DPRefineCandidates = true;

    options = mrlfeMakeDirectViscoAtlasBranchOptions(baseOptions, "A0Like", policy);
    tCase = tic;
    candidateBranch = solveMRLFEViscoBranchAtlas("A0Like", seedMode, material, geometry, mrlfeParams, options);
    if cases(iCase).ApplyDelayedCut
        [candidateBranch, delayedCutSummary] = mrlfeApplyDelayedViscoModalCut(candidateBranch, policy);
    else
        delayedCutSummary = struct();
    end
    candidateTime = toc(tCase);

    comparison = compareBranches(referenceBranch, candidateBranch);
    valid = getBranchValid(candidateBranch);
    row = table();
    row.CaseName = cases(iCase).Name;
    row.ReferenceTime_s = referenceTime;
    row.CandidateTime_s = candidateTime;
    row.Speedup = referenceTime / max(candidateTime, eps);
    row.ReferenceValidPoints = comparison.ReferenceValidPoints;
    row.CandidateValidPoints = comparison.CandidateValidPoints;
    row.OverlapPoints = comparison.OverlapPoints;
    row.FirstValid_Hz = firstFrequency(frequency, valid);
    row.LastValid_Hz = lastFrequency(frequency, valid);
    row.RMSE_mps = comparison.RMSE_mps;
    row.P95Abs_mps = comparison.P95Abs_mps;
    row.MaxAbs_mps = comparison.MaxAbs_mps;
    row.MeanAbs_mps = comparison.MeanAbs_mps;
    row.MaxCpJumpRelative = comparison.MaxCpJumpRelative;
    row.FirstModalCut_Hz = getFieldOrDefault(candidateBranch, 'firstMissingModalMinimumFrequency', nan);
    row.ModalCutReason = string(getFieldOrDefault(candidateBranch, 'modalCutReason', "none"));
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    caseResults(iCase).name = cases(iCase).Name; %#ok<SAGROW>
    caseResults(iCase).policy = policy;
    caseResults(iCase).options = options;
    caseResults(iCase).branch = candidateBranch;
    caseResults(iCase).comparison = comparison;
    caseResults(iCase).delayedCutSummary = delayedCutSummary;
end

fprintf('\nA0 direct-visco atlas vs maintained summary\n');
disp(summaryRows);

assignin('base', 'MRLFEA0DirectViscoAtlasVsMaintainedSummary', summaryRows);
assignin('base', 'MRLFEA0DirectViscoAtlasVsMaintainedCases', caseResults);
assignin('base', 'MRLFEA0DirectViscoAtlasVsMaintainedReference', referenceBranch);
assignin('base', 'MRLFEA0DirectViscoAtlasVsMaintainedFrequency', frequency);

fprintf('\nInterpretation guide:\n');
fprintf('  - baseline_cut should reproduce the start-gating failure.\n');
fprintf('  - no_start_cut tests whether the post-start branch is numerically close to the maintained route.\n');
fprintf('  - delayed_cut allows initial missing points, then applies conservative tail cutting after a stable valid run.\n');
fprintf('  - A0 is primary-ready only if delayed_cut keeps broad coverage and low RMSE/P95 error against maintained.\n');

function comparison = compareBranches(referenceBranch, candidateBranch)
referenceCp = referenceBranch.Cp(:);
candidateCp = candidateBranch.Cp(:);
referenceValid = getBranchValid(referenceBranch);
candidateValid = getBranchValid(candidateBranch);
mask = referenceValid(:) & candidateValid(:) & isfinite(referenceCp(:)) & isfinite(candidateCp(:));
err = candidateCp(:) - referenceCp(:);
absErr = abs(err);
comparison = struct();
comparison.ReferenceValidPoints = nnz(referenceValid);
comparison.CandidateValidPoints = nnz(candidateValid);
comparison.OverlapPoints = nnz(mask);
comparison.RMSE_mps = nan;
comparison.P95Abs_mps = nan;
comparison.MaxAbs_mps = nan;
comparison.MeanAbs_mps = nan;
if any(mask)
    comparison.RMSE_mps = sqrt(mean(err(mask).^2, 'omitnan'));
    comparison.P95Abs_mps = percentileValue(absErr(mask), 95);
    comparison.MaxAbs_mps = max(absErr(mask), [], 'omitnan');
    comparison.MeanAbs_mps = mean(absErr(mask), 'omitnan');
end
comparison.MaxCpJumpRelative = maxRelativeJump(candidateCp(candidateValid));
end

function valid = getBranchValid(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
end

function value = maxRelativeJump(x)
x = x(:);
x = x(isfinite(x) & x > 0);
if numel(x) < 2
    value = 0;
else
    value = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end
end

function value = percentileValue(x, percentile)
x = sort(x(isfinite(x)));
if isempty(x)
    value = nan;
else
    idx = max(1, min(numel(x), ceil(percentile / 100 * numel(x))));
    value = x(idx);
end
end

function value = firstFrequency(frequency, mask)
idx = find(mask(:), 1, 'first');
if isempty(idx)
    value = nan;
else
    value = frequency(idx);
end
end

function value = lastFrequency(frequency, mask)
idx = find(mask(:), 1, 'last');
if isempty(idx)
    value = nan;
else
    value = frequency(idx);
end
end

function value = getFieldOrDefault(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end
