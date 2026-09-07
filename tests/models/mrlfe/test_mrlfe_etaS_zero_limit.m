function test_mrlfe_etaS_zero_limit()
%TEST_MRLFE_ETAS_ZERO_LIMIT Validate the elastic limit of the public mRLFE API.

params = lamb.models.mrlfe.configuration.mrlfeDefaultWorkflowParams();
frequency_Hz = linspace(500, 4000, 14).';

for branchName = ["A0Like", "S0Like"]
    options = forwardOptions(0);
    request = lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
    assert(request.numerics.preset == "fast", ...
        'Forward test setup must preserve the former fitting-default fast preset.');
    assert(request.material.etaS_Pas == 0 && request.fluid.density_kgm3 == 1000 && ...
        request.fluid.soundSpeed_mps == 1500, ...
        'Forward test setup changed effective viscosity or fluid configuration.');
    expectedTermination = "none";
    if branchName == "A0Like", expectedTermination = "physicalTail"; end
    assert(request.termination.policy == expectedTermination, ...
        'Forward test setup changed branch termination policy.');
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

function options = forwardOptions(etaS)
options = lamb.models.mrlfe.mrlfeDefaultOptions();
options.mrlfeParams = lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters();
options.mrlfeParams.etaS = etaS;
end
