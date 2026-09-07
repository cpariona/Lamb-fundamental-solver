function test_mrlfe_etaS_zero_limit()
%TEST_MRLFE_ETAS_ZERO_LIMIT Validate the elastic limit of the public mRLFE API.

params = lamb.models.mrlfe.configuration.mrlfeDefaultWorkflowParams();
frequency_Hz = linspace(500, 4000, 14).';

for branchName = ["A0Like", "S0Like"]
    options = lamb.fitting.mrlfe.mrlfeDefaultFitOptions(branchName, 'EtaS', 0);
    request = lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
    result = lamb.models.mrlfe.mrlfeSolve(request);

    assert(result.model == "mrlfe" && result.branch == branchName, ...
        'etaS = 0 must remain on the canonical public mRLFE branch contract.');
    assert(result.execution.internalEngine == "elastic_adaptive", ...
        'etaS = 0 must select the elastic mRLFE engine.');
    assert(result.configuration.effective.options.materialRegime == "elasticZeroViscosity", ...
        'etaS = 0 material regime metadata changed.');
    assert(result.configuration.effective.parameters.etaS_Pas == 0, ...
        'etaS = 0 must remain explicit in public configuration.');
    assert(result.fallback.policy == "none" && ~result.fallback.applied, ...
        'etaS = 0 public solve must not use fallback.');
end

fprintf('test_mrlfe_etaS_zero_limit passed. etaS = 0 uses the public elastic engine.\n');
end
