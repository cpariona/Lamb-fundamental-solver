function test_ae_configuration_ownership()
profiles = ["Fast", "Balanced", "Robust"];
expectedY = [300, 600, 900];
expectedTopN = [12, 16, 20];
for i = 1:numel(profiles)
    [preset, name] = lamb.models.acoustoelastic_iop_hgo.configuration.aeGetNumericalPreset(profiles(i));
    assert(name == profiles(i));
    assert(preset.atlasNumYPoints == expectedY(i));
    assert(preset.atlasTopNMinima == expectedTopN(i));
end

[production, productionMetadata] = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(struct());
assert(production.atlasNumYPoints == 1000);
assert(production.atlasTopNMinima == 18);
assert(~isfield(production, 'trackingMethod'));
assert(~isfield(productionMetadata, 'surface'));

overrides = struct('atlasNumYPoints', 777, 'atlasTopNMinima', 9, ...
    'atlasBranchPolicy', "ATLASA0");
[effective, metadata] = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(overrides, 'NumericalPreset', "Fast");
assert(effective.atlasNumYPoints == 777);
assert(effective.atlasTopNMinima == 9);
assert(effective.atlasBranchPolicy == "atlasA0");
assert(metadata.profileOverrideApplied == true);

diagnostic = lamb.models.acoustoelastic_iop_hgo.configuration.aeDefaultDiagnosticOptions(struct('numCpScanPoints', 555));
assert(diagnostic.numCpScanPoints == 555);
assert(diagnostic.trackingMethod == "globalScan");

accepted = struct('IOP', [], 'R', [], 'thickness', [], 'mu', [], 'k1', [], ...
    'k2', [], 'rho', [], 'rhoF', [], 'fluidBulkModulus', [], 'frequency', []);
lamb.models.acoustoelastic_iop_hgo.configuration.aeValidateRequest(accepted, 'Context', "iopSolver");
assertErrorContains(@()lamb.models.acoustoelastic_iop_hgo.configuration.aeValidateRequest(rmfield(accepted, 'R'), ...
    'Context', "iopSolver"), 'Missing required acoustoelastic IOP/HGO atlas parameter: R');
assertErrorContains(@()lamb.models.acoustoelastic_iop_hgo.configuration.aeValidateRequest(rmfield(accepted, 'frequency'), ...
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
assert(isempty(lamb.models.acoustoelastic_iop_hgo.configuration.aeBuildInternalTrackingGrid([NaN, -1, 0], gridOptions)));

fprintf('test_ae_configuration_ownership passed.\n');
end

function assertGrid(requested, options, expected)
actual = lamb.models.acoustoelastic_iop_hgo.configuration.aeBuildInternalTrackingGrid(requested, options);
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
