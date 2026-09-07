function test_execution_profile_normalization_contract()
fprintf('\nRunning execution profile normalization contract test...\n');
fprintf('------------------------------------------------\n');

repoRoot = testRepositoryRoot();
adapterFunctions = [ ...
    "aeResolveExecutionProfile"; ...
    "mrlfeResolveExecutionProfile"; ...
    "rlResolveExecutionProfile"; ...
    "mrlfeBuildSurfaceExecutionMetadata"];
for i = 1:numel(adapterFunctions)
    fileName = adapterFunctions(i) + ".m";
    expectedPath = fullfile(repoRoot, 'app', 'shared', fileName);
    oldPath = fullfile(repoRoot, 'app', 'adapters', fileName);
    assert(isfile(expectedPath), '%s must live in app/shared.', adapterFunctions(i));
    assert(~isfile(oldPath), 'The former app/adapters path must be absent for %s.', adapterFunctions(i));
    assert(strcmp(which(adapterFunctions(i)), expectedPath), ...
        '%s must resolve uniquely from app/shared.', adapterFunctions(i));
end

profiles = guiExecutionProfileValues();
assert(isequal(profiles, ["Fast", "Balanced", "Robust"]), ...
    'Canonical execution profile list changed.');

%% Shared control normalization preserves canonical and legacy fields.
controls = guiNormalizeControlExecutionProfile(struct('executionProfile', 'balanced'), ...
    'DefaultProfile', "Fast", 'DefaultSource', "test default");
assert(controls.executionProfile == "Balanced", 'executionProfile should canonicalize.');
assert(controls.robustness == "Balanced", 'robustness compatibility alias should be populated.');

controls = guiNormalizeControlExecutionProfile(struct('robustness', "ROBUST"), ...
    'DefaultProfile', "Fast", 'DefaultSource', "test default");
assert(controls.executionProfile == "Robust", 'robustness alias should canonicalize to executionProfile.');
assert(controls.robustness == "Robust", 'robustness alias should be canonicalized.');

controls = guiNormalizeControlExecutionProfile(struct(), ...
    'DefaultProfile', "Fast", 'DefaultSource', "test default");
assert(~isfield(controls, 'executionProfile'), ...
    'Controls without profile fields should not receive an implicit profile in builders.');

assertThrows(@()guiNormalizeControlExecutionProfile( ...
    struct('executionProfile', "Fast", 'robustness', "Robust")), ...
    'guiNormalizeExecutionProfile:ConflictingProfiles');

%% Builders use the shared normalization contract.
experimental = struct('frequency_Hz', [1000; 2000], 'Cp_mps', [2; 3]);
fitRequest = guiBuildFitRequest("rayleigh_lamb", ...
    'branchName', "A0", ...
    'experimental', experimental, ...
    'fixedParams', struct(), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', 1), ...
    'bounds', struct('mu', [1, 2]), ...
    'controls', struct('robustness', "fast"));
assert(fitRequest.controls.executionProfile == "Fast", ...
    'Fit builder should canonicalize legacy robustness.');
assert(fitRequest.controls.robustness == "Fast", ...
    'Fit builder should retain robustness compatibility alias.');

%% Registries expose canonical supported profile metadata.
fitRegistry = guiGetFitModelConfiguration();
assertRegistryProfiles(fitRegistry, "FitTool");

%% Resolver metadata uses stable not-applicable conventions.
[~, rlMetadata] = rlResolveExecutionProfile("Fast");
assert(rlMetadata.internalAtlasPreset == "", ...
    'RL non-applicable internalAtlasPreset should be empty string.');
assert(rlMetadata.profileOverrideApplied == false && rlMetadata.profileOverrideReason == "", ...
    'RL no-override reason should be empty string.');
assert(isequal(rlMetadata.supportedExecutionProfiles, profiles), ...
    'RL supported profiles should use canonical list.');

[~, aeMetadata] = aeResolveExecutionProfile("Balanced");
assert(aeMetadata.internalSolverPreset == "", ...
    'AE non-applicable internalSolverPreset should be empty string.');
assert(aeMetadata.profileOverrideApplied == false && aeMetadata.profileOverrideReason == "", ...
    'AE no-override reason should be empty string.');
assert(aeMetadata.surfaceDefaultExecutionProfile == "Balanced", ...
    'AE default profile metadata should be stable.');

[~, mrlfeMetadata] = mrlfeResolveExecutionProfile("A0Like", ...
    struct('executionProfile', "Balanced"), ...
    'Surface', "fit", 'EtaS', 0.05, ...
    'A0Policy', "physicalTail");
assert(mrlfeMetadata.requestedExecutionProfile == "Balanced", ...
    'mRLFE should preserve requested profile.');
assert(mrlfeMetadata.effectiveExecutionProfile == "Balanced", ...
    'mRLFE Fit should apply Balanced directly.');
assert(mrlfeMetadata.effectiveNumericalPreset == "balanced", ...
    'mRLFE Fit should resolve the Balanced numerical preset.');
assert(mrlfeMetadata.profileOverrideApplied == false && mrlfeMetadata.profileOverrideReason == "", ...
    'Direct mRLFE profile support should not report an override.');
assert(mrlfeMetadata.profileSupportMode == "direct", ...
    'mRLFE support mode should report direct profile support.');

%% Active docs describe the canonical field and compatibility alias.
assertDocContains('README.md', 'executionProfile');
assertDocContains('README.md', 'compatibility alias');
assertDocContains(fullfile('docs', 'architecture', 'execution_profiles_surface_integration.md'), ...
    'execution-profile metadata contract');
fprintf('Execution profile normalization contract test passed.\n');
end

function assertRegistryProfiles(registry, label)
profiles = guiExecutionProfileValues();
for iFamily = 1:numel(registry.modelFamilies)
    family = registry.modelFamilies(iFamily);
    if strlength(string(family.id)) == 0
        continue;
    end
    assert(isequal(string(family.executionProfiles), profiles), ...
        '%s family %s should expose canonical executionProfiles.', label, family.id);
    assert(isequal(string(family.supportedExecutionProfiles), profiles), ...
        '%s family %s should expose canonical supportedExecutionProfiles.', label, family.id);
    assert(strlength(string(family.profileSupportMode)) > 0, ...
        '%s family %s should define profileSupportMode.', label, family.id);
    assert(strlength(string(family.surfaceDefaultExecutionProfile)) > 0, ...
        '%s family %s should define surfaceDefaultExecutionProfile.', label, family.id);
end
end

function assertDocContains(pathParts, expected)
root = testRepositoryRoot();
filePath = fullfile(root, pathParts);
txt = string(fileread(filePath));
assert(contains(txt, expected), 'Expected %s to contain "%s".', filePath, expected);
end

function assertThrows(fcn, expectedId)
threw = false;
try
    fcn();
catch ME
    threw = true;
    assert(strcmp(ME.identifier, expectedId), ...
        'Expected error id %s, got %s.', expectedId, ME.identifier);
end
assert(threw, 'Expected function to throw %s.', expectedId);
end
