function test_ae_result_ownership()
%TEST_AE_RESULT_OWNERSHIP Enforce canonical AE result/quality ownership.

repositoryRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
modelRoot = fullfile(repositoryRoot, 'models', 'acoustoelastic_iop_hgo');
solverRoot = fullfile(modelRoot, 'solvers');

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

assert(~isfile(fullfile(repositoryRoot, 'analysis', 'acoustoelastic_iop_hgo', ...
    'aeBuildIdentityA0DiagnosticBranch.m')), ...
    'The model must not resolve identity diagnostics through analysis/.');
assert(~isfile(fullfile(repositoryRoot, 'analysis', 'acoustoelastic_iop_hgo', ...
    'aeScoreBranchIdentityCandidates.m')), ...
    'The model must not resolve identity scoring through analysis/.');
resultFiles = dir(fullfile(modelRoot, 'results', '*.m'));
assert(isequal(string({resultFiles.name}), "aeBuildResult.m"), ...
    'AE results/ must contain result construction only.');

solverFiles = [ ...
    dir(fullfile(solverRoot, 'solveAcoustoelasticAtlasBranch.m')); ...
    dir(fullfile(solverRoot, 'solveAcoustoelasticIOPHGOBranch.m'))];
solverText = "";
for i = 1:numel(solverFiles)
    solverText = solverText + newline + string(fileread(fullfile(solverFiles(i).folder, solverFiles(i).name)));
end
removedBuilders = ["summarizeReliability", "summarizeRequestedFrequencyReliability", ...
    "summarizeRequestedFrequencyDiagnostics"];
for name = removedBuilders
    assert(~contains(solverText, name), ...
        'Obsolete local result/quality builder remains active: %s.', name);
end
assert(~contains(solverText, "result.reliability ="), ...
    'Solver wrappers must not assemble reliability outside aeBuildResult.');

params = representativeDirectParams();
options = defaultAcoustoelasticIOPHGOOptions();
options.atlasNumYPoints = 120;
options.atlasTopNMinima = 6;
options.useInternalAtlasTrackingGrid = false;
result = solveAcoustoelasticAtlasBranch(params, options);
fields = rmfield(result, {'reliability', 'diagnostics'});
rebuilt = aeBuildResult(struct('fields', fields));
assert(isequaln(rebuilt, result), ...
    'Canonical builder must reproduce the characterized direct result exactly.');

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
