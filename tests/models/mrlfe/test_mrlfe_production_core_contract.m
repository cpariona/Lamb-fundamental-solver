function test_mrlfe_production_core_contract()
%TEST_MRLFE_PRODUCTION_CORE_CONTRACT Validate production-core ownership and metadata.

fprintf('\nRunning mRLFE production core contract test...\n');
fprintf('---------------------------------------------\n');

request = localRequest("A0Like", 0.05, "fast", "physicalTail");
result = lamb.models.mrlfe.mrlfeSolve(request);
assert(result.execution.internalEngine == "viscoelastic_adaptive", ...
    'Effective engine name must be neutral for viscoelastic cases.');
assert(~contains(result.execution.internalEngine, "Fit") && ...
    ~contains(result.execution.internalEngine, "GUI") && ...
    ~contains(result.execution.internalEngine, "Unified"), ...
    'Effective engine must not expose historical route naming.');
assert(result.execution.requestedPreset == "fast", 'Requested preset metadata changed.');
assert(result.execution.effectivePreset == "fast", 'Effective preset metadata changed.');
assert(result.fallback.applied == false, 'Production core must not apply fallback.');

elastic = lamb.models.mrlfe.mrlfeSolve(localRequest("S0Like", 0, "fast", "none"));
assert(elastic.execution.internalEngine == "elastic_adaptive", ...
    'Effective engine name must be neutral for zero-viscosity cases.');

fprintf('mRLFE production core contract test passed.\n');
end

function request = localRequest(branch, etaS, preset, terminationPolicy)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', string(preset));
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', string(terminationPolicy));
request.fallback = struct('policy', "none");
end
