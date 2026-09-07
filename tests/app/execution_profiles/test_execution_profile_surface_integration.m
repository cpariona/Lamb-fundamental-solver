function test_execution_profile_surface_integration()
%TEST_EXECUTION_PROFILE_SURFACE_INTEGRATION Validate execution-profile surfaces.

fprintf('\nRunning execution profile surface integration tests...\n');
fprintf('----------------------------------------------------\n');

profiles = ["Fast", "Balanced", "Robust"];
presets = ["fast", "balanced", "robust"];

%% Surface defaults are explicit.
mainOptions = lamb.models.rayleigh_lamb.rlDefaultOptions("Balanced");
[~, mainMetadata] = rlResolveExecutionProfile("Balanced", ...
    'DefaultProfile', "Balanced", 'DefaultSource', "Main GUI default");
assert(mainOptions.robustness == "Balanced", 'Main GUI visible default should remain Balanced.');
assert(mainMetadata.surfaceDefaultExecutionProfile == "Balanced", ...
    'Main GUI metadata should record Balanced surface default.');

fitRegistry = guiGetFitModelConfiguration();
for i = 1:numel(fitRegistry.modelFamilies)
    family = fitRegistry.modelFamilies(i);
    assert(string(family.defaultExecutionProfile) == "Fast", ...
        'FitTool family %s defaultExecutionProfile should be Fast.', family.id);
    assert(string(family.surfaceDefaultExecutionProfile) == "Fast", ...
        'FitTool family %s surface default should be Fast.', family.id);
end
mrlfeFitFamily = fitRegistry.modelFamilies(string({fitRegistry.modelFamilies.id}) == "mrlfe");
assert(mrlfeFitFamily.profileSupportMode == "direct", ...
    'mRLFE FitTool should advertise direct profile support.');

%% RL resolver uses the requested profile exactly.
params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.fmin = 1000;
params.fmax = 3000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
for i = 1:numel(profiles)
    profile = profiles(i);
    [options, metadata] = rlResolveExecutionProfile(profile);
    reference = lamb.models.rayleigh_lamb.rlDefaultOptions(profile);
    assert(options.gridPointsInitial == reference.gridPointsInitial, ...
        'RL resolver changed gridPointsInitial for %s.', profile);
    assert(metadata.requestedExecutionProfile == profile && metadata.effectiveExecutionProfile == profile, ...
        'RL resolver should report requested/effective %s.', profile);
end

%% AE profiles map to maintained atlas densities in Main/Fit paths.
expectedY = [300, 600, 900];
expectedTopN = [12, 16, 20];
for i = 1:numel(profiles)
    profile = profiles(i);
    [aeOptions, aeMetadata] = aeResolveExecutionProfile(profile, ...
        'DefaultProfile', "Fast", 'DefaultSource', "surface test");
    assert(aeOptions.atlasNumYPoints == expectedY(i), 'AE %s atlasNumYPoints mismatch.', profile);
    assert(aeOptions.atlasTopNMinima == expectedTopN(i), 'AE %s atlasTopNMinima mismatch.', profile);
    assert(aeOptions.atlasBranchPolicy == "atlasA0", 'AE %s branch policy changed.', profile);
    assert(aeMetadata.effectiveExecutionProfile == profile, 'AE %s metadata effective mismatch.', profile);
end

%% mRLFE applies Fast/Balanced/Robust directly and keeps route policy separate.
for i = 1:numel(profiles)
    [mrlfeOptions, mrlfeMetadata] = mrlfeResolveExecutionProfile("A0Like", ...
        struct('executionProfile', profiles(i)), ...
        'Surface', "main", ...
        'EtaS', 0, ...
        'A0Policy', "physicalTail");
    assert(mrlfeOptions.executionProfile == profiles(i), ...
        'mRLFE should preserve requested profile.');
    assert(mrlfeMetadata.effectiveExecutionProfile == profiles(i), ...
        'mRLFE requested profile should be effective.');
    assert(mrlfeMetadata.effectiveNumericalPreset == presets(i), ...
        'mRLFE numerical preset mapping mismatch.');
    assert(mrlfeMetadata.profileOverrideApplied == false, ...
        'mRLFE direct profile support should not report an override.');
    assert(mrlfeMetadata.routePolicy == "physicalTail", ...
        'mRLFE route policy should remain separate from execution profile.');
    assert(mrlfeMetadata.profileSupportMode == "direct", ...
        'mRLFE support mode should document direct behavior.');
end

fprintf('Execution profile surface integration tests passed.\n');
end
