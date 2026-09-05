function test_rl_result_contract()
%TEST_RL_RESULT_CONTRACT Protect canonical Rayleigh-Lamb result semantics.

params = rlDefaultParams();
params.fmin = 50;
params.fmax = 500;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = true;

result = rlComputeFundamentalLambModes(params, options);
assert(result.model == "rayleigh_lamb");
assert(isfield(result, 'modes') && all(isfield(result.modes, {'A0', 'S0'})));
assert(isfield(result, 'approximations'));
assert(~isfield(result, 'models') && ~isfield(result, 'grid'));
assertConfigurationEnvelope(result.configuration, params, options);
assert(isfield(result.execution, 'engine') && result.execution.engine == "independent_continuation");
assert(isfield(result.execution, 'elapsedSeconds') && isfinite(result.execution.elapsedSeconds));

frequency_Hz = result.configuration.effective.parameters.frequency_Hz;
for name = ["A0", "S0"]
    branch = result.modes.(char(name));
    required = {'frequency_Hz', 'phaseVelocity_mps', 'wavenumber_radpm', ...
        'validMask', 'angularFrequency_radps', 'wavenumberThickness', 'diagnostics'};
    assert(all(isfield(branch, required)));
    assert(~any(isfield(branch, {'frequency', 'Cp', 'k', 'valid'})));
    assert(isequal(branch.frequency_Hz, frequency_Hz));
    assert(iscolumn(branch.frequency_Hz) && iscolumn(branch.phaseVelocity_mps) && ...
        iscolumn(branch.wavenumber_radpm) && iscolumn(branch.validMask));
    assert(isequal(size(branch.frequency_Hz), size(branch.phaseVelocity_mps)));
    assert(isequal(size(branch.frequency_Hz), size(branch.validMask)));
    assert(isfield(branch.diagnostics, 'residual') && ~isfield(branch, 'residual'));
    assert(isequal(size(branch.frequency_Hz), size(branch.diagnostics.residual)));
    quality = result.quality.(char(name));
    assert(all(isfield(quality, {'pointCount','validCount','validFraction','accepted','reason'})));
    assert(quality.validCount == nnz(branch.validMask));
end

repoRoot = testRepositoryRoot();
assert(strcmp(which('rlComputeFundamentalLambModes'), fullfile(repoRoot, 'models', ...
    'rayleigh_lamb', 'api', 'rlComputeFundamentalLambModes.m')));
assert(strcmp(which('rlSolveFundamentalModes'), fullfile(repoRoot, 'models', ...
    'rayleigh_lamb', 'solvers', 'rlSolveFundamentalModes.m')));
assert(strcmp(which('rlEvaluateModeQuality'), fullfile(repoRoot, 'models', ...
    'rayleigh_lamb', 'quality', 'rlEvaluateModeQuality.m')));

exampleSource = fileread(fullfile(repoRoot, 'examples', 'rayleigh_lamb', ...
    'basic', 'run_default_A0_S0.m'));
assert(contains(exampleSource, 'mode.diagnostics.residual'));
assert(~contains(exampleSource, 'mode.residual'), 'Example uses a retired residual field.');
approximations = rlComputeAnalyticalApproximations(frequency_Hz, result.material, result.geometry);
assert(isequaln(approximations, result.approximations));

fprintf('Rayleigh-Lamb result contract passed.\n');
end

function assertConfigurationEnvelope(configuration, params, options)
assert(isfield(configuration, 'requested') && isfield(configuration, 'effective'));
assert(all(isfield(configuration.requested, {'parameters','options'})));
assert(all(isfield(configuration.effective, {'parameters','options'})));
assert(isequaln(configuration.requested.parameters, params));
assert(isequaln(configuration.requested.options, options));
assert(configuration.effective.parameters.thickness == params.thickness);
assert(iscolumn(configuration.effective.parameters.frequency_Hz));
assert(isequaln(configuration.effective.options, options));
assert(~any(isfield(configuration.effective, {'material','geometry','frequency_Hz'})), ...
    'Effective configuration must use only the parameters/options envelope.');
end
