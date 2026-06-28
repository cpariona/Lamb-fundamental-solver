function [summaryRows, caseResults] = compareMRLFEAtlasPolicy(params, policyOptions)
%COMPAREMRLFEATLASPOLICY Compare maintained mRLFE real-k branches against atlas routes.
%
% This helper is diagnostic infrastructure only. It does not change the
% maintained mRLFE execution path used by rlComputeFundamentalLambModes or the
% GUI adapters.
%
% Default matrix:
%   A0Like/S0Like, etaS = 0      maintained vs modal-atlas continuous/cut
%   A0Like/S0Like, etaS > 0      maintained vs direct viscous atlas

if nargin < 1 || isempty(params)
    params = rlDefaultParams();
end
if nargin < 2 || isempty(policyOptions)
    policyOptions = struct();
end

params = completeMaterialParams(params);
material = rlComputeMaterial(params);
geometryFull = rlComputeGeometry(params);
geometry = geometryFull;
if isfield(geometry, 'halfThickness')
    geometry = rmfield(geometry, 'halfThickness');
end
frequency = rlBuildFrequencyVector(params);

branchNames = string(getOption(policyOptions, 'branchNames', ["A0Like", "S0Like"]));
etaSValues = getOption(policyOptions, 'etaSValues', [0, 0.05]);

summaryRows = table();
caseResults = repmat(emptyCaseResult(), 0, 1);
caseIndex = 0;

for iBranch = 1:numel(branchNames)
    branchName = branchNames(iBranch);
    for iEta = 1:numel(etaSValues)
        etaS = etaSValues(iEta);
        referenceOptions = makeReferenceOptions(policyOptions, branchName, etaS);

        tReference = tic;
        rawReference = rlComputeFundamentalLambModes(params, referenceOptions);
        referenceTime = toc(tReference);
        referenceBranch = getMRLFEBranch(rawReference, branchName);
        seedMode = getSeedMode(rawReference, branchName);

        if etaS == 0
            atlasCases = ["modalAtlasContinuous", "modalAtlasCut"];
            applyCuts = [false, true];
            for iAtlas = 1:numel(atlasCases)
                atlasOptions = makeModalAtlasOptions(referenceOptions, policyOptions, applyCuts(iAtlas));
                tCandidate = tic;
                candidateBranch = solveMRLFEBranchModalAtlas(branchName, seedMode, material, geometry, referenceOptions.mrlfeParams, atlasOptions);
                candidateTime = toc(tCandidate);

                caseIndex = caseIndex + 1;
                [summaryRows, caseResults] = appendComparison(summaryRows, caseResults, caseIndex, ...
                    branchName, etaS, atlasCases(iAtlas), applyCuts(iAtlas), rawReference, referenceBranch, ...
                    candidateBranch, referenceTime, candidateTime, frequency);
            end
        else
            atlasOptions = makeDirectViscoAtlasOptions(referenceOptions, policyOptions, branchName);
            tCandidate = tic;
            candidateBranch = solveMRLFEViscoBranchAtlas(branchName, seedMode, material, geometry, referenceOptions.mrlfeParams, atlasOptions);
            candidateTime = toc(tCandidate);

            caseIndex = caseIndex + 1;
            [summaryRows, caseResults] = appendComparison(summaryRows, caseResults, caseIndex, ...
                branchName, etaS, "directViscoAtlas", false, rawReference, referenceBranch, ...
                candidateBranch, referenceTime, candidateTime, frequency);
        end
    end
end
end

function params = completeMaterialParams(params)
material = rlComputeMaterial(params);
params.E = material.E;
params.K = material.K;
params.CL = material.CL;
params.CT = material.CT;
params.lambda = material.lambda;
params.nu = material.nu;
end

function options = makeReferenceOptions(policyOptions, branchName, etaS)
robustness = string(getOption(policyOptions, 'robustness', "Fast"));
options = rlDefaultOptions(robustness);
if isfield(policyOptions, 'baseOptions') && isstruct(policyOptions.baseOptions)
    options = mergeStructs(options, policyOptions.baseOptions);
end

computeA0 = branchName == "A0Like";
computeS0 = branchName == "S0Like";
options.computeA0 = computeA0;
options.computeS0 = computeS0;
options.computeMRLFE = false;
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = true;
options.computeMRLFEViscoRealK = etaS > 0;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = computeA0;
options.mrlfeComputeS0Like = computeS0;

mrlfeParams = defaultMRLFEParams();
if isfield(policyOptions, 'mrlfeParams') && isstruct(policyOptions.mrlfeParams)
    mrlfeParams = mergeStructs(mrlfeParams, policyOptions.mrlfeParams);
end
mrlfeParams.fluidDensity = getOption(mrlfeParams, 'fluidDensity', 1000);
mrlfeParams.fluidSoundSpeed = getOption(mrlfeParams, 'fluidSoundSpeed', 1500);
mrlfeParams.etaS = etaS;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
options.mrlfeParams = mrlfeParams;
end

function options = makeModalAtlasOptions(referenceOptions, policyOptions, applyCut)
options = referenceOptions;
options.mrlfeModalAtlasCpScanPoints = getOption(policyOptions, 'mrlfeModalAtlasCpScanPoints', 1200);
options.mrlfeModalAtlasTopNMinima = getOption(policyOptions, 'mrlfeModalAtlasTopNMinima', 24);
options.mrlfeModalAtlasMaxLogCpJump = getOption(policyOptions, 'mrlfeModalAtlasMaxLogCpJump', 0.075);
options.mrlfeModalAtlasCpMinFactor = getOption(policyOptions, 'mrlfeModalAtlasCpMinFactor', 0.20);
options.mrlfeModalAtlasCpMaxFactor = getOption(policyOptions, 'mrlfeModalAtlasCpMaxFactor', 2.80);
options.mrlfeModalAtlasCpMaxCeiling = getOption(policyOptions, 'mrlfeModalAtlasCpMaxCeiling', 120);
options.mrlfeModalAtlasMinBranchPoints = getOption(policyOptions, 'mrlfeModalAtlasMinBranchPoints', 8);
options.mrlfeModalAtlasRefineMinima = getOption(policyOptions, 'mrlfeModalAtlasRefineMinima', false);
options.mrlfeModalAtlasRequireLowStartRank = getOption(policyOptions, 'mrlfeModalAtlasRequireLowStartRank', false);
options.mrlfeModalAtlasRequireResidualValidity = getOption(policyOptions, 'mrlfeModalAtlasRequireResidualValidity', false);
options.mrlfeModalAtlasApplyAmbiguityCut = logical(applyCut);
options.mrlfeModalAtlasAmbiguityResidualRatio = getOption(policyOptions, 'mrlfeModalAtlasAmbiguityResidualRatio', 4.0);
options.mrlfeModalAtlasAmbiguityMinCpSeparation = getOption(policyOptions, 'mrlfeModalAtlasAmbiguityMinCpSeparation', 0.16);
options.mrlfeModalAtlasAmbiguityMaxGapPoints = getOption(policyOptions, 'mrlfeModalAtlasAmbiguityMaxGapPoints', 6);
options.mrlfeModalAtlasAmbiguityPaddingPoints = getOption(policyOptions, 'mrlfeModalAtlasAmbiguityPaddingPoints', 1);
options.mrlfeModalAtlasAmbiguityMinClusterTriggers = getOption(policyOptions, 'mrlfeModalAtlasAmbiguityMinClusterTriggers', 2);
end

function options = makeDirectViscoAtlasOptions(referenceOptions, policyOptions, branchName)
options = referenceOptions;
options.mrlfeA0DPCandidates = getOption(policyOptions, 'mrlfeA0DPCandidates', 8);
options.mrlfeA0DPCpScanPoints = getOption(policyOptions, 'mrlfeViscoAtlasCpScanPoints', 900);
options.mrlfeA0DPEdgeGuardPoints = getOption(policyOptions, 'mrlfeA0DPEdgeGuardPoints', 6);
options.mrlfeA0DPRefineCandidates = getOption(policyOptions, 'mrlfeA0DPRefineCandidates', true);
options.mrlfeA0DPAllowMissing = getOption(policyOptions, 'mrlfeA0DPAllowMissing', true);
options.mrlfeRealKStopAtFirstMissingModalMinimum = getOption(policyOptions, 'mrlfeRealKStopAtFirstMissingModalMinimum', true);
options.mrlfeViscoPreviousCpMaxRelativeJump = getOption(policyOptions, 'mrlfeViscoPreviousCpMaxRelativeJump', 0.18);
if branchName == "S0Like"
    options.mrlfeViscoS0ModalCpWindow = getOption(policyOptions, 'mrlfeViscoS0ModalCpWindow', [0.70, 1.40]);
else
    options.mrlfeViscoA0ModalCpWindow = getOption(policyOptions, 'mrlfeViscoA0ModalCpWindow', [0.35, 2.50]);
end
end

function [summaryRows, caseResults] = appendComparison(summaryRows, caseResults, caseIndex, branchName, etaS, candidateSolver, applyCut, rawReference, referenceBranch, candidateBranch, referenceTime, candidateTime, frequency)
comparison = compareBranches(referenceBranch, candidateBranch);
ambiguity = summarizeAmbiguity(candidateBranch, frequency);

row = table();
row.BranchName = branchName;
row.EtaS_Pa_s = etaS;
row.CandidateSolver = candidateSolver;
row.AmbiguityCut = logical(applyCut);
row.ReferenceTime_s = referenceTime;
row.CandidateTime_s = candidateTime;
row.Speedup = referenceTime / max(candidateTime, eps);
row.ReferenceValidPoints = comparison.ReferenceValidPoints;
row.CandidateValidPoints = comparison.CandidateValidPoints;
row.OverlapPoints = comparison.OverlapPoints;
row.RMSE_mps = comparison.RMSE_mps;
row.P95Abs_mps = comparison.P95Abs_mps;
row.MaxAbs_mps = comparison.MaxAbs_mps;
row.MeanAbs_mps = comparison.MeanAbs_mps;
row.MaxCpJumpRelative = comparison.MaxCpJumpRelative;
row.AmbiguityPoints = ambiguity.Points;
row.AmbiguityClusters = ambiguity.Clusters;
row.FirstAmbiguity_Hz = ambiguity.FirstFrequency_Hz;
row.LastAmbiguity_Hz = ambiguity.LastFrequency_Hz;
row.FirstModalCut_Hz = getFieldOrDefault(candidateBranch, 'firstMissingModalMinimumFrequency', nan);
summaryRows = [summaryRows; row]; %#ok<AGROW>

caseResult = emptyCaseResult();
caseResult.branchName = branchName;
caseResult.etaS = etaS;
caseResult.candidateSolver = candidateSolver;
caseResult.rawReference = rawReference;
caseResult.referenceBranch = referenceBranch;
caseResult.candidateBranch = candidateBranch;
caseResult.comparison = comparison;
caseResult.ambiguity = ambiguity;
caseResults(caseIndex, 1) = caseResult;
end

function comparison = compareBranches(referenceBranch, candidateBranch)
referenceCp = referenceBranch.Cp(:);
candidateCp = candidateBranch.Cp(:);
referenceValid = branchValid(referenceBranch);
candidateValid = branchValid(candidateBranch);
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

function ambiguity = summarizeAmbiguity(branch, frequency)
ambiguity = struct('Points', 0, 'Clusters', 0, 'FirstFrequency_Hz', nan, 'LastFrequency_Hz', nan);
if ~isfield(branch, 'modalAmbiguityMask')
    return;
end
mask = logical(branch.modalAmbiguityMask(:));
ambiguity.Points = nnz(mask);
if isfield(branch, 'modalAmbiguityClusters') && istable(branch.modalAmbiguityClusters)
    ambiguity.Clusters = height(branch.modalAmbiguityClusters);
end
idx = find(mask);
if ~isempty(idx)
    frequency = frequency(:);
    ambiguity.FirstFrequency_Hz = frequency(idx(1));
    ambiguity.LastFrequency_Hz = frequency(idx(end));
end
end

function branch = getMRLFEBranch(raw, branchName)
if ~isfield(raw, 'models') || ~isfield(raw.models, 'mRLFERealK') || ...
        ~isfield(raw.models.mRLFERealK, 'branches') || ...
        ~isfield(raw.models.mRLFERealK.branches, char(branchName))
    error('Missing maintained mRLFERealK branch: %s.', branchName);
end
branch = raw.models.mRLFERealK.branches.(char(branchName));
end

function seedMode = getSeedMode(raw, branchName)
if branchName == "S0Like"
    seedName = 'S0';
else
    seedName = 'A0';
end
if ~isfield(raw, 'modes') || ~isfield(raw.modes, seedName)
    error('Missing Rayleigh-Lamb seed mode: %s.', seedName);
end
seedMode = raw.modes.(seedName);
end

function valid = branchValid(branch)
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

function caseResult = emptyCaseResult()
caseResult = struct();
caseResult.branchName = "";
caseResult.etaS = nan;
caseResult.candidateSolver = "";
caseResult.rawReference = struct();
caseResult.referenceBranch = struct();
caseResult.candidateBranch = struct();
caseResult.comparison = struct();
caseResult.ambiguity = struct();
end

function value = getFieldOrDefault(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

function base = mergeStructs(base, overlay)
if ~isstruct(overlay)
    return;
end
names = fieldnames(overlay);
for i = 1:numel(names)
    base.(names{i}) = overlay.(names{i});
end
end
