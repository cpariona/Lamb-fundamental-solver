clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

profiles = ["Fast", "Balanced", "Robust"];
expectedY = [300, 600, 900];
expectedTopN = [12, 16, 20];
for i = 1:numel(profiles)
    [preset, name] = aeGetNumericalPreset(profiles(i));
    assert(name == profiles(i));
    assert(preset.atlasNumYPoints == expectedY(i));
    assert(preset.atlasTopNMinima == expectedTopN(i));
end

[mainGuiPreset, mainGuiName] = aeGetNumericalPreset("MainGUI");
assert(mainGuiName == "MainGUI");
assert(mainGuiPreset.numCpScanPoints == 420);
assert(mainGuiPreset.maxLocalCandidates == 8);
assert(mainGuiPreset.refineLocalMinima == false);
assert(mainGuiPreset.atlasInitializationNumFrequencyPoints == 25);
assert(mainGuiPreset.trackingMethod == "predictiveContinuation");
assert(mainGuiPreset.localContinuationFallback == "globalScan");
assert(mainGuiPreset.predictiveWindow == 0.22);
assert(mainGuiPreset.predictionWeight == 8.0);
assert(mainGuiPreset.curvatureWeight == 4.0);

[direct, directMetadata] = aeResolveConfiguration(struct());
assert(direct.atlasNumYPoints == 1000);
assert(direct.atlasTopNMinima == 18);
assert(directMetadata.surface == "direct");

[mainGui, mainGuiMetadata] = aeResolveConfiguration(struct(), 'Surface', "MainGUI");
assert(mainGui.numCpScanPoints == 420);
assert(mainGui.maxLocalCandidates == 8);
assert(mainGui.refineLocalMinima == false);
assert(mainGui.atlasInitializationNumFrequencyPoints == 25);
assert(mainGui.trackingMethod == "predictiveContinuation");
assert(mainGuiMetadata.aeGuiInteractivePreset == "fast");

overrides = struct( ...
    'atlasNumYPoints', 777, ...
    'atlasTopNMinima', 9, ...
    'numCpScanPoints', 555, ...
    'trackingMethod', "globalScan", ...
    'atlasBranchPolicy', "ATLASA0");
[effective, metadata] = aeResolveConfiguration(overrides, ...
    'NumericalPreset', "Fast", 'Surface', "MainGUI");
assert(effective.atlasNumYPoints == 777);
assert(effective.atlasTopNMinima == 9);
assert(effective.numCpScanPoints == 555);
assert(effective.trackingMethod == "globalScan");
assert(effective.atlasBranchPolicy == "atlasA0");
assert(metadata.profileOverrideApplied == true);

[disabledGui, disabledMetadata] = aeResolveConfiguration( ...
    struct('aeUseGuiFastAtlasPreset', false), 'Surface', "MainGUI");
assert(disabledGui.numCpScanPoints == 1400);
assert(disabledGui.atlasInitializationNumFrequencyPoints == 50);
assert(disabledMetadata.aeGuiInteractivePreset == "off");

accepted = struct('IOP', [], 'R', [], 'thickness', [], 'mu', [], 'k1', [], ...
    'k2', [], 'rho', [], 'rhoF', [], 'fluidBulkModulus', [], 'frequency', []);
aeValidateRequest(accepted, 'Context', "iopSolver");

assertErrorContains(@()aeValidateRequest(rmfield(accepted, 'R'), ...
    'Context', "iopSolver"), ...
    'Missing required acoustoelastic IOP/HGO atlas parameter: R');
assertErrorContains(@()aeValidateRequest(rmfield(accepted, 'frequency'), ...
    'Context', "fitting", 'Frequency', [1000, NaN]), ...
    'frequency_Hz must contain positive finite values.');

gridOptions = struct('atlasInitializationMinFrequency_Hz', 300, ...
    'atlasInitializationNumFrequencyPoints', 4);
assertGrid([1000, 2000, 4000], gridOptions, ...
    unique([logspace(log10(300), log10(4000), 4), 1000, 2000, 4000], 'sorted'));
assertGrid([100, 300, 500], gridOptions, ...
    unique([logspace(log10(300), log10(500), 4), 100, 300, 500], 'sorted'));
assertGrid([3000, 1000, 2000], gridOptions, ...
    unique([logspace(log10(300), log10(3000), 4), 1000, 2000, 3000], 'sorted'));
assertGrid([1000, 1000, 2750, 1600], gridOptions, ...
    unique([logspace(log10(300), log10(2750), 4), 1000, 1600, 2750], 'sorted'));

boundaryOptions = struct('atlasInitializationMinFrequency_Hz', -5, ...
    'atlasInitializationNumFrequencyPoints', 1);
assertGrid([200, 75, 200, NaN, -10], boundaryOptions, ...
    unique([logspace(log10(eps), log10(200), 2), 75, 200], 'sorted'));
assert(isempty(aeBuildInternalTrackingGrid([NaN, -1, 0], gridOptions)));

fprintf('test_ae_configuration_ownership passed.\n');

function assertGrid(requested, options, expected)
actual = aeBuildInternalTrackingGrid(requested, options);
assert(isequal(actual, expected), 'Internal tracking grid changed.');
end

function assertErrorContains(fcn, expectedText)
didReject = false;
try
    fcn();
catch ME
    didReject = contains(ME.message, expectedText);
end
assert(didReject, 'Expected rejection containing: %s', expectedText);
end
