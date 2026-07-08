clear; clc;
startup

fprintf('\nRunning GUI mRLFE zero-eta adaptive contract test...\n');
fprintf('------------------------------------------------\n');

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
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeUseZeroViscosityAdaptiveGuiRoute = true;
options.mrlfeA0Policy = "adaptivePhysicalTail";
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0;
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;

request = struct();
request.params = params;
request.options = options;
request.mrlfeParams = options.mrlfeParams;
request.computeElastic = true;
request.computeVisco = false;

out = guiRunMRLFEModel(request);
assert(out.metadata.executionProfile.routePolicy == "mrlfeSolve", ...
    'Main GUI mRLFE should use public solver route.');
assert(out.metadata.modelResult.execution.internalEngine == "elastic_adaptive", ...
    'Zero-eta Main GUI mRLFE should report elastic_adaptive engine.');
assert(out.metadata.modelResult.fallback.policy == "none" && ...
    out.metadata.modelResult.fallback.applied == false, ...
    'Zero-eta Main GUI mRLFE must not apply fallback.');
assert(isfield(out.metadata, 'quality') && isfield(out.metadata.quality, 'A0Like'), ...
    'Missing public quality metadata.');
assert(isfield(out.metadata.quality.A0Like, 'validFraction'), ...
    'Missing validFraction metadata.');
assert(isfield(out.metadata.quality.A0Like, 'maxRelativeJump'), ...
    'Missing maxRelativeJump metadata.');
assert(~isempty(out.branches), 'Expected at least one normalized mRLFE branch.');

plotData = guiGetNormalizedBranchPlotData(out.branches(1));
assert(any(isfinite(plotData.y(:))), 'Expected finite normalized Cp values.');

fprintf('GUI mRLFE zero-eta adaptive contract passed. Engine: %s. validFraction: %.3f. maxJump: %.3f.\n', ...
    string(out.metadata.modelResult.execution.internalEngine), ...
    out.metadata.quality.A0Like.validFraction, ...
    out.metadata.quality.A0Like.maxRelativeJump);
