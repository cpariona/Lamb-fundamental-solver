function test_mrlfe_public_contract_result_schema()
%TEST_MRLFE_PUBLIC_CONTRACT_RESULT_SCHEMA Validate canonical mRLFE result schema.

fprintf('\nRunning mRLFE public result schema contract test...\n');
fprintf('--------------------------------------------------\n');

for branch = ["A0Like", "S0Like"]
    request = localRequest(branch, 0.05, "fast");
    result = mrlfeSolve(request);
    assertResultSchema(result, request);
end

fprintf('mRLFE public result schema contract test passed.\n');
end

function request = localRequest(branch, etaS, preset)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', string(preset));
request.selection = struct('strategy', "adaptive");
if branch == "A0Like"
    request.termination = struct('policy', "physicalTail");
else
    request.termination = struct('policy', "none");
end
request.fallback = struct('policy', "none");
end

function assertResultSchema(result, request)
required = ["model", "branch", "frequency_Hz", "phaseVelocity_mps", "wavenumber_radpm", ...
    "validMask", "quality", "termination", "fallback", "execution", "configuration"];
for i = 1:numel(required)
    assert(isfield(result, char(required(i))), 'Missing result field: %s', required(i));
end
assert(result.model == "mrlfe", 'Unexpected result model.');
assert(result.branch == request.branch, 'Unexpected result branch.');
assert(iscolumn(result.frequency_Hz), 'frequency_Hz must be a column vector.');
assert(iscolumn(result.phaseVelocity_mps), 'phaseVelocity_mps must be a column vector.');
assert(iscolumn(result.wavenumber_radpm), 'wavenumber_radpm must be a column vector.');
assert(iscolumn(result.validMask), 'validMask must be a column vector.');
assert(isequal(result.frequency_Hz, request.frequency_Hz(:)), 'Requested frequency grid was not preserved.');
assert(numel(result.phaseVelocity_mps) == numel(result.frequency_Hz), 'Phase velocity length mismatch.');
assert(numel(result.wavenumber_radpm) == numel(result.frequency_Hz), 'Wavenumber length mismatch.');
assert(numel(result.validMask) == numel(result.frequency_Hz), 'Valid mask length mismatch.');
assert(all(isnan(result.phaseVelocity_mps(~result.validMask))), 'Invalid Cp points must be NaN.');
assert(result.execution.requestedPreset == request.numerics.preset, 'Requested preset metadata mismatch.');
assert(result.execution.effectivePreset == request.numerics.preset, 'Effective preset metadata mismatch.');
assert(result.fallback.policy == "none", 'Fallback policy must be none.');
assert(result.fallback.applied == false, 'Fallback must not be silently applied.');
assert(isfield(result.quality, 'validCount'), 'Missing quality.validCount.');
assert(isfield(result.quality, 'pointCount'), 'Missing quality.pointCount.');
assert(isfield(result.quality, 'validFraction'), 'Missing quality.validFraction.');
assert(isfield(result.quality, 'lastValidFrequency_Hz'), 'Missing quality.lastValidFrequency_Hz.');
assert(isfield(result.quality, 'maxRelativeJump'), 'Missing quality.maxRelativeJump.');
assert(isfield(result.quality, 'accepted'), 'Missing quality.accepted.');
assert(isfield(result.quality, 'reason'), 'Missing quality.reason.');
assert(isfield(result, 'debug') && isfield(result.debug, 'solverResult'), ...
    'Explicit debug boundary must expose the internal solver result.');
assert(isfield(result, 'diagnostics') && isfield(result.diagnostics, 'solvePointCount'), ...
    'Public diagnostics must expose a stable summary.');
assert(result.diagnostics.solvePointCount == numel(result.debug.solverResult.frequencySolve_Hz), ...
    'Stable solve-point summary must match debug evidence.');
assert(~isfield(result.diagnostics, 'rawInternalResult'), ...
    'Internal solver evidence must not be duplicated under diagnostics.');
assertConfigurationEnvelope(result.configuration, request);
end

function assertConfigurationEnvelope(configuration, request)
assert(isfield(configuration, 'requested') && isfield(configuration, 'effective'), ...
    'Configuration must distinguish requested and effective values.');
assert(all(isfield(configuration.requested, {'parameters','options'})), ...
    'Requested configuration must use parameters/options envelope.');
assert(all(isfield(configuration.effective, {'parameters','options'})), ...
    'Effective configuration must use parameters/options envelope.');
assert(configuration.requested.parameters.mu_Pa == request.material.mu_Pa);
assert(configuration.requested.parameters.etaS_Pas == request.material.etaS_Pas);
assert(configuration.requested.parameters.thickness_m == request.geometry.thickness_m);
assert(configuration.requested.options.branch == request.branch);
assert(isequal(configuration.requested.options.frequency_Hz, request.frequency_Hz));
assert(configuration.effective.parameters.etaS_Pas == request.material.etaS_Pas);
assert(configuration.effective.options.branch == request.branch);
assert(configuration.effective.options.materialRegime == "viscoelastic");
assert(configuration.effective.options.numericalPreset.name == request.numerics.preset);
end
