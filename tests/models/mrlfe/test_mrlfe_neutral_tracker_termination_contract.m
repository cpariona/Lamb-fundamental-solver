function test_mrlfe_neutral_tracker_termination_contract()
%TEST_MRLFE_NEUTRAL_TRACKER_TERMINATION_CONTRACT Validate neutral engine and termination metadata.

fprintf('\nRunning mRLFE neutral tracker/termination contract test...\n');
fprintf('---------------------------------------------------------\n');

cases = [ ...
    struct('branch', "A0Like", 'etaS', 0, 'preset', "fast"); ...
    struct('branch', "A0Like", 'etaS', 0.05, 'preset', "fast"); ...
    struct('branch', "S0Like", 'etaS', 0, 'preset', "fast"); ...
    struct('branch', "S0Like", 'etaS', 0.05, 'preset', "fast"); ...
    struct('branch', "A0Like", 'etaS', 0.05, 'preset', "dense"); ...
    struct('branch', "S0Like", 'etaS', 0.05, 'preset', "dense")];

for i = 1:numel(cases)
    request = localRequest(cases(i).branch, cases(i).etaS, cases(i).preset);
    result = lamb.models.mrlfe.mrlfeSolve(request);

    assert(numel(result.phaseVelocity_mps) == numel(request.frequency_Hz), ...
        'Result Cp vector length changed.');
    assert(isequal(result.frequency_Hz, request.frequency_Hz), ...
        'Requested frequency grid changed.');
    assert(result.execution.effectivePreset == cases(i).preset, ...
        'Effective preset changed.');
    assert(result.fallback.policy == "none", 'Fallback policy changed.');
    assert(result.fallback.applied == false, 'Fallback must not be applied.');

    if cases(i).etaS == 0
        assert(result.execution.internalEngine == "elastic_adaptive", ...
            'Elastic engine metadata changed.');
    else
        assert(result.execution.internalEngine == "viscoelastic_adaptive", ...
            'Viscoelastic engine metadata changed.');
    end

    if cases(i).branch == "A0Like"
        assert(result.termination.policy == "physicalTail", ...
            'A0Like termination policy changed.');
    else
        assert(result.termination.policy == "none", ...
            'S0Like termination policy changed.');
    end
end

fprintf('mRLFE neutral tracker/termination contract test passed.\n');
end

function request = localRequest(branch, etaS, preset)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 12000, 20).';
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
