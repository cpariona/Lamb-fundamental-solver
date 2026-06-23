clear; clc;
startup

%TEST_MRLFE_ELASTIC_REFERENCE_BUFFER Contract test for mRLFE viscous buffering.
%
% For etaS > 0, the maintained mRLFERealK route must accept a compatible
% etaS = 0 reference branch as a buffer. The public normalized model remains
% mRLFERealK; reference/viscous raw fields are internal implementation details.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 14;
params.frequencySpacing = "linspace";

baseOptions = rlDefaultOptions("Fast");
baseOptions.computeA0 = true;
baseOptions.computeS0 = false;
baseOptions.computeMRLFE = false;
baseOptions.computeMRLFERealK = true;
baseOptions.computeMRLFEElasticRealK = false;
baseOptions.computeMRLFEViscoRealK = false;
baseOptions.computeMRLFEComplexK = false;
baseOptions.mrlfeComputeA0Like = true;
baseOptions.mrlfeComputeS0Like = false;
baseOptions.mrlfeParams = defaultMRLFEParams();
baseOptions.mrlfeParams.etaL = 0;
baseOptions.mrlfeParams.useComplexLambda = false;
baseOptions.mrlfeParams.solveComplexK = false;

elasticOptions = baseOptions;
elasticOptions.mrlfeParams.etaS = 0;
elasticResults = rlComputeFundamentalLambModes(params, elasticOptions);
assert(isfield(elasticResults.models, 'mRLFERealK'), 'Elastic reference must expose mRLFERealK.');
assert(isfield(elasticResults.models.mRLFERealK.branches, 'A0Like'), 'Elastic reference must include A0Like.');

viscousOptions = baseOptions;
viscousOptions.mrlfeParams.etaS = 0.05;
viscousOptions.mrlfeElasticReferenceResult = elasticResults.models.mRLFERealK;
viscousResults = rlComputeFundamentalLambModes(params, viscousOptions);

assert(isfield(viscousResults.models, 'mRLFERealK'), 'Viscous case must expose unified mRLFERealK.');
assert(isfield(viscousResults.models, 'mRLFEElasticRealK'), 'Viscous case must preserve the etaS = 0 reference internally.');
assert(isfield(viscousResults.models, 'mRLFEViscoRealK'), 'Viscous case must preserve the etaS > 0 raw branch internally.');
assert(isfield(viscousResults.models.mRLFERealK.branches, 'A0Like'), 'Viscous mRLFERealK must contain A0Like.');

referenceBranch = viscousResults.models.mRLFEElasticRealK.branches.A0Like;
providedBranch = elasticResults.models.mRLFERealK.branches.A0Like;
assert(max(abs(referenceBranch.frequency(:) - providedBranch.frequency(:))) < 1e-12, ...
    'Buffered reference frequency must match the provided etaS = 0 reference.');
assert(max(abs(referenceBranch.Cp(:) - providedBranch.Cp(:)), [], 'omitnan') < 1e-12, ...
    'Buffered reference Cp must match the provided etaS = 0 reference.');

viscousBranch = viscousResults.models.mRLFERealK.branches.A0Like;
assert(any(viscousBranch.valid), 'Viscous mRLFERealK A0Like must contain valid points.');
assert(any(isfinite(viscousBranch.Cp(viscousBranch.valid))), 'Viscous mRLFERealK A0Like must contain finite valid Cp values.');

normalized = guiNormalizeRawResult(viscousResults, "test_mrlfe_elastic_reference_buffer");
assert(hasNormalizedBranch(normalized, "mRLFERealK", "A0Like"), ...
    'Normalized viscous result must expose the unified mRLFERealK A0Like branch.');
assert(~hasNormalizedBranch(normalized, "mRLFEViscoRealK", "A0Like"), ...
    'Normalized viscous result must not expose a separate mRLFEViscoRealK branch.');

fprintf('test_mrlfe_elastic_reference_buffer passed. etaS > 0 accepts etaS = 0 buffer.\n');

function tf = hasNormalizedBranch(guiResult, modelName, branchName)
tf = false;
if ~isfield(guiResult, 'branches') || isempty(guiResult.branches)
    return;
end
for i = 1:numel(guiResult.branches)
    branch = guiResult.branches(i);
    if string(branch.modelName) == string(modelName) && string(branch.branchName) == string(branchName)
        tf = true;
        return;
    end
end
end
