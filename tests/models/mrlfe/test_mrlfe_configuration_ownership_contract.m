function test_mrlfe_configuration_ownership_contract()
%TEST_MRLFE_CONFIGURATION_OWNERSHIP_CONTRACT Guard model-owned request/configuration translation.

fprintf('\nRunning mRLFE configuration ownership contract...\n');
fprintf('-----------------------------------------------\n');

root = testRepositoryRoot(mfilename('fullpath'));
requestOwner = fullfile(root, 'src', '+lamb', '+models', '+mrlfe', '+configuration', 'mrlfeBuildSolveRequest.m');
assert(isfile(requestOwner), 'mRLFE solve-request construction must be model-owned under configuration/.');
assert(strcmp(which('lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest'), requestOwner), ...
    'lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest must resolve to the model configuration owner.');
assertOwner(root, 'mrlfeResolveConfiguration', 'configuration');
assertOwner(root, 'mrlfeGetNumericalPreset', 'configuration');
assertOwner(root, 'mrlfeDefaultOptions', '');
assert(~isfile(fullfile(root, 'analysis', 'requests', 'mrlfe', 'mrlfeBuildSolveRequest.m')), ...
    'The old analysis-owned mRLFE request builder must be absent.');

removedRequestBuilders = string({ ...
    'mrlfeBuildPublicSolveRequest.m', ...
    'mrlfeBuildGuiSolveRequest.m', ...
    'mrlfeBuildFitSolveRequest.m', ...
    'mrlfeBuildSweepSolveRequest.m'});
for i = 1:numel(removedRequestBuilders)
    assert(~isfile(fullfile(root, 'analysis', 'mrlfe', removedRequestBuilders(i))), ...
        'Removed request-builder alias is present: %s.', removedRequestBuilders(i));
end

configuration = lamb.models.mrlfe.configuration.mrlfeResolveConfiguration(fastRequest());
assert(configuration.numericalPreset.scanPoints == 100, ...
    'Fast numerical preset coarse scan density changed.');
assert(configuration.numericalPreset.rescueScanPoints == 260, ...
    'Fast numerical preset rescue scan density changed.');
assert(configuration.internalOptions.trackerCpScanPoints == 100, ...
    'Fast coarse scan density did not propagate to the tracker configuration.');
assert(configuration.internalOptions.trackerRescueCpScanPoints == 260, ...
    'Fast rescue scan density did not propagate to the tracker configuration.');
assert(configuration.internalOptions.trackerEdgeGuardPoints == 4, ...
    'The maintained tracker edge guard must resolve to four points.');

fprintf('mRLFE configuration ownership contract passed.\n');
end

function assertOwner(root, functionName, ownerFolder)
qualifiedName = "lamb.models.mrlfe.";
expected = fullfile(root, 'src', '+lamb', '+models', '+mrlfe');
if strlength(string(ownerFolder)) > 0
    qualifiedName = qualifiedName + string(ownerFolder) + ".";
    expected = fullfile(expected, '+' + string(ownerFolder));
end
qualifiedName = qualifiedName + string(functionName);
expected = fullfile(expected, string(functionName) + ".m");
assert(strcmp(which(char(qualifiedName)), expected), ...
    '%s must resolve to its canonical scientific owner.', qualifiedName);
end

function request = fastRequest()
request = struct();
request.branch = "A0Like";
request.frequency_Hz = linspace(1000, 3000, 4).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', 0.05, ...
    'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");
end
