function test_ae_sensitivity_study_contract()
%TEST_AE_SENSITIVITY_STUDY_CONTRACT Validate the maintained AE sweep behavior.

timerStart = tic;
repoRoot = testRepositoryRoot();
studyOwner = fullfile(repoRoot, 'studies', 'sensitivity', ...
    'acoustoelastic_iop_hgo', 'aeRunSensitivity.m');
assert(strcmp(which('aeRunSensitivity'), studyOwner), ...
    'AE sensitivity orchestration must resolve from its opt-in study owner.');

baseParams = representativeParams();
options = fastTestOptions();
iopValues_mmHg = [10, 20];
iopValues_Pa = iopValues_mmHg * 133.322;
sweepConfig = struct('Name', "tiny_iop", 'Label', "IOP", ...
    'Unit', "mmHg", 'ValueScale', 133.322, 'ValueFormatter', "%.0f");

sweep = aeRunSensitivity(baseParams, "IOP", iopValues_Pa, options, sweepConfig);

assert(sweep.spec.parameter == "IOP" && sweep.parameter == "IOP");
assert(sweep.spec.parameterPath == "params.IOP");
assert(sweep.spec.units == "mmHg" && sweep.spec.displayScale == 133.322);
assert(isequal(sweep.values, iopValues_Pa));
assert(isequal(sweep.displayValues, iopValues_mmHg));
assert(numel(sweep.results) == numel(iopValues_Pa) && ...
    numel(sweep.requests) == numel(iopValues_Pa), ...
    'The sweep must create one result and request per IOP value.');

for i = 1:numel(iopValues_Pa)
    expectedParams = baseParams;
    expectedParams.IOP = iopValues_Pa(i);
    assert(isequaln(sweep.params{i}, expectedParams), ...
        'The sweep must vary only IOP in the physical request.');
    assert(isequaln(sweep.options{i}, options), ...
        'The sweep must not vary numerical options between IOP points.');

    result = sweep.results{i};
    assertCanonicalAtlasA0(result, baseParams.frequency);
    assert(sweep.points{i}.status == "ok");
    assert(isequaln(sweep.requests{i}, result.configuration.requested), ...
        'Stored sweep request must preserve canonical requested configuration.');
    assert(result.configuration.requested.parameters.IOP == iopValues_Pa(i));

    direct = lamb.models.acoustoelastic_iop_hgo.aeSolveBranch( ...
        expectedParams, options);
    assert(isequaln(result.phaseVelocity_mps, direct.phaseVelocity_mps));
    assert(isequal(result.validMask, direct.validMask));
    assert(isequaln(result.wavenumber_radpm, direct.wavenumber_radpm));
    assert(isequaln(result.quality, direct.quality));
    assert(isequaln(result.configuration, direct.configuration));
end

fprintf('AE tiny sensitivity behavior passed in %.3f s.\n', toc(timerStart));
end

function params = representativeParams()
params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.IOP = 15 * 133.322;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(1000), log10(5000), 5);
end

function options = fastTestOptions()
[options, ~] = aeResolveExecutionProfile("Fast");
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 120;
options.atlasTopNMinima = 6;
options.useInternalAtlasTrackingGrid = false;
end

function assertCanonicalAtlasA0(result, frequency)
required = {'model', 'branch', 'frequency_Hz', 'phaseVelocity_mps', ...
    'wavenumber_radpm', 'validMask', 'quality', 'diagnostics', ...
    'configuration', 'execution'};
assert(all(isfield(result, required)), 'Canonical AE result schema is incomplete.');
assert(result.model == "acoustoelastic_iop_hgo" && result.branch == "atlasA0");
assert(isequal(result.frequency_Hz, frequency(:)));
assert(isa(result.validMask, 'logical'));
assert(all(isnan(result.phaseVelocity_mps(~result.validMask))));
end
