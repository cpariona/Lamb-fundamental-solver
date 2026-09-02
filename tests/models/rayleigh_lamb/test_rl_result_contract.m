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
assert(isfield(result.configuration, 'requested') && isfield(result.configuration, 'effective'));
assert(isequaln(result.configuration.requested.parameters, params));
assert(isequaln(result.configuration.requested.options, options));

for name = ["A0", "S0"]
    branch = result.modes.(char(name));
    required = {'frequency_Hz', 'phaseVelocity_mps', 'wavenumber_radpm', ...
        'validMask', 'angularFrequency_radps', 'wavenumberThickness', 'diagnostics'};
    assert(all(isfield(branch, required)));
    assert(~any(isfield(branch, {'frequency', 'Cp', 'k', 'valid'})));
    assert(isequal(branch.frequency_Hz, result.configuration.effective.frequency_Hz));
    assert(isequal(size(branch.frequency_Hz), size(branch.phaseVelocity_mps)));
    assert(isequal(size(branch.frequency_Hz), size(branch.validMask)));
    assert(result.quality.(char(name)).validCount == nnz(branch.validMask));
end

fprintf('Rayleigh-Lamb result contract passed.\n');
end
