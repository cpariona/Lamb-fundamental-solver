clear; clc;
if isempty(which('mrlfeSolve'))
    configureTestPath;
end

fprintf('\nRunning model execution profile resolver tests...\n');
fprintf('------------------------------------------------\n');

profiles = ["Fast", "Balanced", "Robust"];
presets = ["fast", "balanced", "robust"];

%% Rayleigh-Lamb resolver delegates to rlDefaultOptions without changing values.
for i = 1:numel(profiles)
    profile = profiles(i);
    [options, metadata] = rlResolveExecutionProfile(profile);
    reference = rlDefaultOptions(profile);
    assert(options.gridPointsInitial == reference.gridPointsInitial, 'RL gridPointsInitial changed.');
    assert(options.gridPointsTracking == reference.gridPointsTracking, 'RL gridPointsTracking changed.');
    assert(options.jumpTol == reference.jumpTol, 'RL jumpTol changed.');
    assert(~any(startsWith(string(fieldnames(options)), "mrlfe", 'IgnoreCase', true)), ...
        'RL options must not contain mRLFE configuration.');
    assert(metadata.requestedExecutionProfile == profile, 'RL metadata requested profile mismatch.');
    assert(metadata.effectiveExecutionProfile == profile, 'RL metadata effective profile mismatch.');
    assert(metadata.profileOverrideApplied == false, 'RL resolver should not report overrides.');
end

%% AE resolver preserves atlas density mapping.
expectedY = [300, 600, 900];
expectedTopN = [12, 16, 20];
for i = 1:numel(profiles)
    [options, metadata] = aeResolveExecutionProfile(profiles(i));
    assert(options.atlasNumYPoints == expectedY(i), 'AE atlasNumYPoints mapping changed.');
    assert(options.atlasTopNMinima == expectedTopN(i), 'AE atlasTopNMinima mapping changed.');
    assert(options.atlasBranchPolicy == "atlasA0", 'AE route policy changed.');
    assert(metadata.requestedExecutionProfile == profiles(i), 'AE requested profile metadata mismatch.');
    assert(metadata.effectiveExecutionProfile == profiles(i), 'AE effective profile metadata mismatch.');
end

%% mRLFE GUI/Sweep applies each requested public numerical preset directly.
for i = 1:numel(profiles)
    [guiOptions, guiMetadata] = mrlfeResolveExecutionProfile("A0Like", ...
        struct('robustness', profiles(i)), 'Surface', "sweep", ...
        'EtaS', 0.05, 'A0Policy', "physicalTail");
    assert(guiOptions.executionProfile == profiles(i), 'mRLFE GUI/Sweep requested profile mismatch.');
    assert(guiOptions.effectiveExecutionProfile == profiles(i), 'mRLFE GUI/Sweep effective profile mismatch.');
    assert(guiOptions.mrlfeNumericalPreset == presets(i), 'mRLFE GUI/Sweep numerical preset mismatch.');
    assert(guiMetadata.requestedExecutionProfile == profiles(i), 'mRLFE GUI requested profile mismatch.');
    assert(guiMetadata.effectiveExecutionProfile == profiles(i), 'mRLFE GUI effective profile mismatch.');
    assert(guiMetadata.effectiveNumericalPreset == presets(i), 'mRLFE GUI numerical preset metadata mismatch.');
    assert(guiMetadata.profileOverrideApplied == false, 'mRLFE GUI resolver should not report overrides.');
    assert(guiMetadata.profileSupportMode == "direct", 'mRLFE GUI support mode should be direct.');
    assert(guiMetadata.routePolicy == "physicalTail", 'mRLFE A0 policy must remain separate metadata.');
end

%% mRLFE Fit applies each requested public numerical preset directly.
for i = 1:numel(profiles)
    [fitOptions, fitMetadata] = mrlfeResolveExecutionProfile("A0Like", ...
        struct('executionProfile', profiles(i)), 'Surface', "fit", ...
        'EtaS', 0.05, 'A0Policy', "physicalTail");
    assert(fitOptions.executionProfile == profiles(i), 'mRLFE Fit requested profile mismatch.');
    assert(fitOptions.effectiveExecutionProfile == profiles(i), 'mRLFE Fit effective profile mismatch.');
    assert(fitOptions.mrlfeNumericalPreset == presets(i), 'mRLFE Fit numerical preset mismatch.');
    assert(fitMetadata.requestedExecutionProfile == profiles(i), 'mRLFE Fit requested metadata mismatch.');
    assert(fitMetadata.effectiveExecutionProfile == profiles(i), 'mRLFE Fit effective metadata mismatch.');
    assert(fitMetadata.effectiveNumericalPreset == presets(i), 'mRLFE Fit numerical preset metadata mismatch.');
    assert(fitMetadata.profileOverrideApplied == false, 'mRLFE Fit should not report a profile override.');
    assert(fitMetadata.internalAtlasPreset == presets(i), 'mRLFE Fit internal preset metadata mismatch.');
end

fprintf('Model execution profile resolver tests passed.\n');
