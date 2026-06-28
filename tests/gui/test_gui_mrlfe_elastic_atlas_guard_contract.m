clear; clc;
startup

fprintf('\nRunning GUI mRLFE guarded elastic atlas contract test...\n');
fprintf('------------------------------------------------------\n');

params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
params.mu = 100e3;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.499;

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = true;
options.computeMRLFEViscoRealK = false;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeUseElasticAtlasGuiRoute = true;
options.mrlfeUseUnifiedAtlasRoute = false;
options.mrlfeA0Policy = "adaptivePhysicalTail";
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;

request = struct();
request.params = params;
request.options = options;
request.mrlfeParams = options.mrlfeParams;
request.computeElastic = true;
request.computeVisco = false;

out = guiRunMRLFEModel(request);
assert(isfield(out.metadata, 'mrlfeUseElasticAtlasGuiRoute') && out.metadata.mrlfeUseElasticAtlasGuiRoute, ...
    'GUI elastic atlas request metadata must be preserved.');
assert(isfield(out.metadata, 'mrlfeGuiActualRoute'), ...
    'GUI elastic atlas contract must report the actual route.');
assert(any(out.metadata.mrlfeGuiActualRoute == ["elastic_modal_atlas", "elastic_reference_fallback"]), ...
    'Unexpected elastic atlas actual route: %s.', out.metadata.mrlfeGuiActualRoute);
assert(hasNormalizedBranch(out, "mRLFERealK", "A0Like"), ...
    'Guarded elastic atlas GUI route must expose an mRLFERealK A0Like branch.');

plotData = guiGetNormalizedBranchPlotData(out.branches(1));
assert(any(isfinite(plotData.y(:))), ...
    'Guarded elastic atlas GUI route must produce finite normalized Cp values.');

if out.metadata.mrlfeGuiActualRoute == "elastic_reference_fallback"
    assert(out.metadata.mrlfeElasticAtlasFallback == true, ...
        'Fallback metadata must be true when actual route is elastic_reference_fallback.');
else
    assert(out.metadata.mrlfeElasticAtlasFallback == false, ...
        'Fallback metadata must be false when actual route is elastic_modal_atlas.');
end

fprintf('GUI mRLFE guarded elastic atlas contract test passed. Route: %s.\n', out.metadata.mrlfeGuiActualRoute);

function tf = hasNormalizedBranch(guiResult, modelName, branchName)
tf = false;
if ~isfield(guiResult, 'branches') || isempty(guiResult.branches)
    return;
end
for i = 1:numel(guiResult.branches)
    branch = guiResult.branches(i);
    if string(branch.modelName) == string(modelName) && string(branch.branchName) == string(branchName)
        tf = true;
        return;
    end
end
end
