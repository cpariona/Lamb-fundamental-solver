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
route = string(out.metadata.mrlfeGuiActualRoute);
assert(any(route == ["zero_viscosity_adaptive_atlas", "zero_viscosity_adaptive_fallback"]), ...
    'Unexpected GUI route: %s.', route);
assert(isfield(out.metadata, 'mrlfeZeroViscosityAdaptiveQuality'), ...
    'Missing zero-eta adaptive quality metadata.');
assert(isfield(out.metadata.mrlfeZeroViscosityAdaptiveQuality, 'validFraction'), ...
    'Missing validFraction metadata.');
assert(isfield(out.metadata.mrlfeZeroViscosityAdaptiveQuality, 'maxJumpRelative'), ...
    'Missing maxJumpRelative metadata.');
assert(~isempty(out.branches), 'Expected at least one normalized mRLFE branch.');

plotData = guiGetNormalizedBranchPlotData(out.branches(1));
assert(any(isfinite(plotData.y(:))), 'Expected finite normalized Cp values.');

if route == "zero_viscosity_adaptive_atlas"
    assert(out.metadata.mrlfeZeroViscosityAdaptiveQuality.validFraction >= 0.85, ...
        'Zero-eta adaptive route did not meet valid-fraction threshold.');
    assert(out.metadata.mrlfeZeroViscosityAdaptiveQuality.maxJumpRelative <= 0.25, ...
        'Zero-eta adaptive route did not meet jump threshold.');
end

fprintf('GUI mRLFE zero-eta adaptive contract passed. Route: %s. validFraction: %.3f. maxJump: %.3f.\n', ...
    route, ...
    out.metadata.mrlfeZeroViscosityAdaptiveQuality.validFraction, ...
    out.metadata.mrlfeZeroViscosityAdaptiveQuality.maxJumpRelative);
