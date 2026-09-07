function test_mrlfe_main_gui_uses_public_solver()
%TEST_MRLFE_MAIN_GUI_USES_PUBLIC_SOLVER Guard the maintained Main GUI mRLFE route.

fprintf('\nRunning mRLFE Main GUI public-solver route guard test...\n');
fprintf('-------------------------------------------------------\n');

adapterPath = which('guiRunMRLFEModel');
adapterText = string(fileread(adapterPath));

assert(contains(adapterText, "lamb.models.mrlfe.mrlfeSolve"), ...
    'Main GUI mRLFE adapter must call lamb.models.mrlfe.mrlfeSolve.');
assert(contains(adapterText, "lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest"), ...
    'Main GUI mRLFE adapter must use the reusable request translator.');
forbidden = ["computeMRLFE", "solveMRLFEAtlasUnified", ...
    "solveMRLFEBranchAdaptiveAtlas", "mrlfeApplyPhysicalCorridorCut", ...
    "lamb.models.mrlfe.tracking.mrlfeTrackBranchAdaptive"];
for i = 1:numel(forbidden)
    assert(~contains(adapterText, forbidden(i)), ...
        'Main GUI mRLFE adapter must not contain %s.', forbidden(i));
end

cases = [ ...
    struct('branch', "A0Like", 'etaS', 0); ...
    struct('branch', "A0Like", 'etaS', 0.05); ...
    struct('branch', "S0Like", 'etaS', 0); ...
    struct('branch', "S0Like", 'etaS', 0.05)];

for i = 1:numel(cases)
    out = runMainCase(cases(i).branch, cases(i).etaS, 75e3, 1000, 6000, 10);
    modelResult = out.metadata.modelResults.(char(cases(i).branch));
    assert(modelResult.fallback.policy == "none", 'Fallback policy must be none.');
    assert(modelResult.fallback.applied == false, 'Fallback must not be applied.');
    assert(modelResult.execution.effectivePreset == "fast", 'Effective preset must be fast.');
    if cases(i).etaS == 0
        assert(modelResult.execution.internalEngine == "elastic_adaptive", ...
            'Zero-viscosity engine must be elastic_adaptive.');
    else
        assert(modelResult.execution.internalEngine == "viscoelastic_adaptive", ...
            'Positive-viscosity engine must be viscoelastic_adaptive.');
    end
end

fprintf('\nmRLFE Main GUI public-solver route guard test passed.\n');
end

function out = runMainCase(branchName, etaS, mu, fmin, fmax, nPoints)
params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.fmin = fmin;
params.fmax = fmax;
params.numFrequencyPoints = nPoints;
params.frequencySpacing = "linspace";
params.mu = mu;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.4999;

options = lamb.fitting.mrlfe.mrlfeDefaultFitOptions(branchName);
options.branchNames = branchName;
options.mrlfeA0Policy = "physicalTail";
options.mrlfeParams = lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters();
options.mrlfeParams.etaS = etaS;
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;

out = guiRunMRLFEModel(struct('params', params, 'options', options, ...
    'mrlfeParams', options.mrlfeParams, 'computeVisco', etaS > 0));
end
