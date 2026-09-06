function test_ae_result_ownership()
%TEST_AE_RESULT_OWNERSHIP Enforce canonical AE result/quality ownership.

repositoryRoot = testRepositoryRoot();
modelRoot = fullfile(repositoryRoot, 'models', 'acoustoelastic_iop_hgo');

assertPath(which('aeBuildResult'), ...
    fullfile(modelRoot, 'results', 'aeBuildResult.m'), 'canonical AE result builder');
assertPath(which('aeEvaluateAtlasA0Quality'), ...
    fullfile(modelRoot, 'quality', 'aeEvaluateAtlasA0Quality.m'), ...
    'canonical AE quality evaluator');
assertPath(which('aeBuildIdentityA0DiagnosticBranch'), ...
    fullfile(modelRoot, 'diagnostics', 'aeBuildIdentityA0DiagnosticBranch.m'), ...
    'diagnostic identity extension');
assertPath(which('aeScoreBranchIdentityCandidates'), ...
    fullfile(modelRoot, 'diagnostics', 'aeScoreBranchIdentityCandidates.m'), ...
    'diagnostic identity scorer');
assertPath(which('solveAcoustoelasticIOPHGOBranch'), ...
    fullfile(modelRoot, 'api', 'solveAcoustoelasticIOPHGOBranch.m'), ...
    'public AE solver entrypoint');

assert(~isfile(fullfile(repositoryRoot, 'analysis', 'acoustoelastic_iop_hgo', ...
    'aeBuildIdentityA0DiagnosticBranch.m')), ...
    'The model must not resolve identity diagnostics through analysis/.');
assert(~isfile(fullfile(repositoryRoot, 'analysis', 'acoustoelastic_iop_hgo', ...
    'aeScoreBranchIdentityCandidates.m')), ...
    'The model must not resolve identity scoring through analysis/.');
resultFiles = dir(fullfile(modelRoot, 'results', '*.m'));
assert(isequal(string({resultFiles.name}), "aeBuildResult.m"), ...
    'AE results/ must contain result construction only.');

ownerFiles = [ ...
    string(fullfile(modelRoot, 'api', 'solveAcoustoelasticIOPHGOBranch.m')); ...
    string(fullfile(modelRoot, 'solvers', 'solveAcoustoelasticAtlasBranch.m'))];
ownerText = "";
for i = 1:numel(ownerFiles)
    ownerText = ownerText + newline + string(fileread(ownerFiles(i)));
end
removedBuilders = ["summarizeReliability", "summarizeRequestedFrequencyReliability", ...
    "summarizeRequestedFrequencyDiagnostics"];
for name = removedBuilders
    assert(~contains(ownerText, name), ...
        'Obsolete local result/quality builder remains active: %s.', name);
end
assert(~contains(ownerText, "result.quality ="), ...
    'Solver/API owners must not assemble quality outside aeBuildResult.');

params = representativeDirectParams();
options = defaultAcoustoelasticIOPHGOOptions();
options.atlasNumYPoints = 120;
options.atlasTopNMinima = 6;
options.useInternalAtlasTrackingGrid = false;
result = solveAcoustoelasticAtlasBranch(params, options);
fields = rmfield(result, {'quality', 'diagnostics', 'model', 'branch', ...
    'configuration', 'execution', 'wavenumber_radpm'});
rebuilt = aeBuildResult(struct('fields', fields));
assert(isequaln(rebuilt.phaseVelocity_mps, result.phaseVelocity_mps) && ...
    isequal(rebuilt.validMask, result.validMask) && ...
    isequaln(rebuilt.quality, result.quality), ...
    'Canonical builder must reproduce official output and quality semantics.');

fprintf('AE result and quality ownership contract passed.\n');
end

function assertPath(actualPath, expectedPath, label)
assert(~isempty(actualPath), '%s does not resolve.', label);
assert(strcmpi(char(actualPath), char(expectedPath)), ...
    '%s resolves outside its canonical model owner.', label);
end

function params = representativeDirectParams()
params = struct();
params.alpha = 1.5e5;
params.beta = 7.5e4;
params.gamma = 5e4;
params.thickness = 550e-6;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(300), log10(8e3), 8);
end
