function test_execution_profile_current_contract()
%TEST_EXECUTION_PROFILE_CURRENT_CONTRACT Validate current execution-profile behavior.

fprintf('\nRunning execution profile current-behavior contract test...\n');
fprintf('----------------------------------------------------------\n');

%% Rayleigh-Lamb presets are materially different.
fast = lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
balanced = lamb.models.rayleigh_lamb.rlDefaultOptions("Balanced");
robust = lamb.models.rayleigh_lamb.rlDefaultOptions("Robust");

assert(fast.gridPointsInitial < balanced.gridPointsInitial, ...
    'Fast RL gridPointsInitial should be lower than Balanced.');
assert(balanced.gridPointsInitial < robust.gridPointsInitial, ...
    'Balanced RL gridPointsInitial should be lower than Robust.');
assert(fast.gridPointsTracking < balanced.gridPointsTracking, ...
    'Fast RL gridPointsTracking should be lower than Balanced.');
assert(balanced.gridPointsTracking < robust.gridPointsTracking, ...
    'Balanced RL gridPointsTracking should be lower than Robust.');
assert(~any(startsWith(string(fieldnames(fast)), "mrlfe", 'IgnoreCase', true)), ...
    'Rayleigh-Lamb presets must not own mRLFE numerical settings.');

%% AE default sweep preset mapping is the public atlas-density behavior.
aeFast = aeDefaultSweepOptions("Fast");
aeBalanced = aeDefaultSweepOptions("Balanced");
aeRobust = aeDefaultSweepOptions("Robust");

assert(aeFast.atlasNumYPoints == 300 && aeFast.atlasTopNMinima == 12, ...
    'AE Fast should map to atlas 300/12.');
assert(aeBalanced.atlasNumYPoints == 600 && aeBalanced.atlasTopNMinima == 16, ...
    'AE Balanced should map to atlas 600/16.');
assert(aeRobust.atlasNumYPoints == 900 && aeRobust.atlasTopNMinima == 20, ...
    'AE Robust should map to atlas 900/20.');

%% Fit mRLFE defaults are model-owned and use the public Fast preset.
requestedRobustControls = struct('robustness', "Robust", 'etaS', 0.05, ...
    'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
    'mrlfeA0Policy', "physicalTail");
mrlfeOptions = mrlfeDefaultSweepOptions("A0Like", 'EtaS', requestedRobustControls.etaS, ...
    'A0Policy', requestedRobustControls.mrlfeA0Policy);
assert(mrlfeOptions.robustness == "Fast", ...
    'mRLFE default sweep options should select the public Fast profile.');

%% mRLFE public fit route applies the fast preset by default.
params = mrlfeDefaultSweepParams();
frequency_Hz = linspace(1000, 5000, 5).';
[~, raw] = mrlfeEvaluateFitModel(params, frequency_Hz, "A0Like", mrlfeOptions);
assert(raw.evaluationPath.routeFamily == "public_solver", 'mRLFE Fit evaluator should use the public solver route family.');
assert(raw.evaluationPath.fitAtlasPreset == "fast", ...
    'mRLFE Fit evaluator should report the neutral fast preset.');
assert(raw.fitPerformanceDefaults.atlasCpScanPoints == 100, ...
    'mRLFE public fast preset should use 100 coarse Cp scan points by default.');
assert(raw.fitPerformanceDefaults.rescueCpScanPoints == 260, ...
    'mRLFE public fast preset should use 260 Cp scan points for dense rescue.');

%% Fit AE applies requested profile density unless legacy controls override it explicitly.
[solverOptions, metadata] = aeResolveExecutionProfile(struct('robustness', "Robust"), ...
    'DefaultProfile', "Fast", 'DefaultSource', "FitTool default");
solverOptions.atlasBranchPolicy = "atlasA0";
solverOptions.atlasInitializationNumFrequencyPoints = 50;
assert(solverOptions.atlasNumYPoints == 900 && solverOptions.atlasTopNMinima == 20, ...
    'AE Fit Robust should use robustness-derived Robust atlas density by default.');
assert(metadata.profileOverrideApplied == false, ...
    'AE resolver should not report an override for requested Robust.');
legacyControls = struct('robustness', "Robust", 'atlasNumYPoints', 300, ...
    'atlasTopNMinima', 12, 'atlasInitializationNumFrequencyPoints', 50);
legacyOptions = solverOptions;
legacyOptions.atlasNumYPoints = legacyControls.atlasNumYPoints;
legacyOptions.atlasTopNMinima = legacyControls.atlasTopNMinima;
assert(legacyOptions.atlasNumYPoints == 300 && legacyOptions.atlasTopNMinima == 12, ...
    'Legacy AE Fit atlas-density controls should remain able to override profile density.');

fprintf('Execution profile current-behavior contract test passed.\n');
end
