clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

% etaS = 0 is the elastic material regime of the same public mRLFE API.
params = rlDefaultParams();
frequency_Hz = linspace(500, 4000, 14).';

for branchName = ["A0Like", "S0Like"]
    options = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0);
    request = mrlfeBuildPublicSolveRequest(params, frequency_Hz, branchName, ...
        struct('parameterOptions', options));
    result = mrlfeSolve(request);

    assert(result.model == "mrlfe" && result.branch == branchName, ...
        'etaS = 0 must remain on the canonical public mRLFE branch contract.');
    assert(result.execution.internalEngine == "elastic_adaptive", ...
        'etaS = 0 must select the elastic mRLFE engine.');
    assert(result.configuration.materialRegime == "elasticZeroViscosity", ...
        'etaS = 0 material regime metadata changed.');
    assert(result.configuration.parameters.etaS_Pas == 0, ...
        'etaS = 0 must remain explicit in public configuration.');
    assert(result.fallback.policy == "none" && ~result.fallback.applied, ...
        'etaS = 0 public solve must not use fallback.');
end

fprintf('test_mrlfe_etaS_zero_limit passed. etaS = 0 uses the public elastic engine.\n');
