clear; clc;
startup

fprintf('\nRunning model execution profile resolver tests...\n');
fprintf('------------------------------------------------\n');

profiles = ["Fast", "Balanced", "Robust"];

%% Rayleigh-Lamb resolver delegates to rlDefaultOptions without changing values.
for i = 1:numel(profiles)
    profile = profiles(i);
    [options, metadata] = rlResolveExecutionProfile(profile);
    reference = rlDefaultOptions(profile);
    assert(options.gridPointsInitial == reference.gridPointsInitial, 'RL gridPointsInitial changed.');
    assert(options.gridPointsTracking == reference.gridPointsTracking, 'RL gridPointsTracking changed.');
    assert(options.jumpTol == reference.jumpTol, 'RL jumpTol changed.');
    assert(options.mrlfeGridPoints == reference.mrlfeGridPoints, 'RL mrlfeGridPoints changed.');
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

%% mRLFE GUI/Sweep preserves fast internal atlas support as explicit metadata.
[guiOptions, guiMetadata] = mrlfeResolveExecutionProfile("A0Like", struct('robustness', "Robust"), ...
    'Surface', "sweep", 'EtaS', 0.05, 'UseUnifiedAtlasRoute', true, 'A0Policy', "adaptivePhysicalTail");
assert(guiOptions.executionProfile == "Robust", 'mRLFE GUI/Sweep should preserve requested executionProfile.');
assert(guiOptions.robustness == "Fast", 'mRLFE GUI/Sweep effective robustness should remain Fast.');
assert(guiMetadata.requestedExecutionProfile == "Robust", 'mRLFE GUI requested profile mismatch.');
assert(guiMetadata.effectiveExecutionProfile == "Fast", 'mRLFE GUI effective profile mismatch.');
assert(guiMetadata.profileOverrideApplied == true, 'mRLFE GUI resolver should report mapped-to-Fast support.');
assert(strlength(guiMetadata.profileOverrideReason) > 0, 'mRLFE GUI override reason should be stable and nonempty.');
assert(guiMetadata.routePolicy == "adaptivePhysicalTail", 'mRLFE A0 policy must remain separate metadata.');

%% mRLFE Fit preserves maintained Fast effective route and reports override.
[fitOptions, fitMetadata] = mrlfeResolveExecutionProfile("A0Like", struct('executionProfile', "Robust"), ...
    'Surface', "fit", 'EtaS', 0.05, 'UseUnifiedAtlasRoute', true, 'A0Policy', "adaptivePhysicalTail");
assert(fitOptions.robustness == "Fast", 'mRLFE Fit effective robustness should remain Fast.');
assert(fitOptions.executionProfile == "Robust", 'mRLFE Fit should preserve requested executionProfile.');
assert(fitOptions.mrlfeFitAtlasPreset == "fast_fit_atlas", 'mRLFE Fit atlas preset changed.');
assert(fitMetadata.requestedExecutionProfile == "Robust", 'mRLFE Fit requested metadata mismatch.');
assert(fitMetadata.effectiveExecutionProfile == "Fast", 'mRLFE Fit effective metadata mismatch.');
assert(fitMetadata.profileOverrideApplied == true, 'mRLFE Fit should report profile override.');
assert(fitMetadata.internalAtlasPreset == "fast_fit_atlas", 'mRLFE Fit internal atlas preset metadata mismatch.');

fprintf('Model execution profile resolver tests passed.\n');
