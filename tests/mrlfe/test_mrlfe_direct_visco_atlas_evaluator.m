clear; clc;
startup

fprintf('\nRunning direct viscous mRLFE atlas evaluator test...\n');
fprintf('---------------------------------------------------\n');

branchName = "A0Like";
etaS = 0.12;
frequency_Hz = linspace(1000, 8000, 10).';

params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.thickness = 0.50e-3;
params.rho = 1070;
params.nu = 0.4999;
params.etaS = etaS;

referenceOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
referenceOptions.mrlfeDisableForwardCache = true;

atlasOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
atlasOptions.mrlfeUseDirectViscoAtlas = true;
atlasOptions.mrlfeA0DPCpScanPoints = 900;
atlasOptions.mrlfeA0DPCandidates = 8;
atlasOptions.mrlfeViscoA0ModalCpWindow = [0.25, 3.00];
atlasOptions.mrlfeA0DPSeedWeight = 0.10;
atlasOptions.mrlfeA0DPResidualWeight = 0.45;
atlasOptions.mrlfeA0DPJumpWeight = 18.0;
atlasOptions.mrlfeA0DPCurvatureWeight = 12.0;
atlasOptions.mrlfeResidualTolerance = 1e-3;

[CpReference, rawReference] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, referenceOptions);
[CpAtlas, rawAtlas] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, atlasOptions);

valid = isfinite(CpReference(:)) & isfinite(CpAtlas(:));
assert(all(valid), 'Reference and direct atlas evaluations must be finite at all requested frequencies.');
assert(isfield(rawAtlas, 'evaluationPath'), 'Direct atlas evaluator must report evaluationPath.');
assert(rawAtlas.evaluationPath.requestedDirectViscoAtlas == true, 'Direct atlas evaluator must report the requested atlas option.');
assert(rawAtlas.evaluationPath.useDirectViscoAtlas == true, 'Direct atlas evaluator must report the atlas path as actually used.');
assert(rawAtlas.evaluationPath.usedDirectViscoAtlas == true, 'Direct atlas evaluator must report the atlas path as actually used.');
assert(rawAtlas.evaluationPath.path == "direct_viscous_atlas", 'Unexpected direct atlas evaluation path name.');
assert(isfield(rawAtlas.branch, 'viscoAtlas'), 'Direct atlas branch must expose viscoAtlas diagnostics.');
assert(rawAtlas.branch.viscoAtlas.usedElasticMRLFEReference == false, ...
    'Direct viscous atlas must not use an elastic mRLFE reference branch.');
assert(rawAtlas.branch.viscoAtlas.options.refineCandidates == true, ...
    'Direct viscous atlas should refine DP candidates by default.');
assert(all(rawAtlas.branch.validCp(:)), 'Direct viscous atlas branch should be strictly valid for this baseline case.');

rmseDiff = sqrt(mean((CpAtlas(:) - CpReference(:)).^2));
maxAbsDiff = max(abs(CpAtlas(:) - CpReference(:)));
assert(rmseDiff < 0.005, 'Direct viscous atlas Cp RMSE difference is too large.');
assert(maxAbsDiff < 0.015, 'Direct viscous atlas maximum Cp difference is too large.');

% Requesting the direct atlas for S0Like must not silently relabel the maintained
% path. S0Like direct-atlas tracking has not been validated yet.
s0Options = mrlfeDefaultSweepOptions("S0Like", 'EtaS', etaS);
s0Options.mrlfeUseDirectViscoAtlas = true;
[~, rawS0] = mrlfeEvaluateFitModel(params, frequency_Hz, "S0Like", s0Options);
assert(rawS0.evaluationPath.requestedDirectViscoAtlas == true, 'S0 diagnostic should record the requested atlas option.');
assert(rawS0.evaluationPath.usedDirectViscoAtlas == false, 'S0Like must not use direct atlas until validated.');
assert(rawS0.evaluationPath.path == "maintained_rl_mrlfe_workflow", 'S0Like should report the maintained path.');
assert(~isfield(rawS0.branch, 'viscoAtlas'), 'S0Like maintained branch should not expose direct-atlas diagnostics.');

fprintf('Reference path: %s\n', rawReference.evaluationPath.path);
fprintf('Atlas path:     %s\n', rawAtlas.evaluationPath.path);
fprintf('S0 path:        %s\n', rawS0.evaluationPath.path);
fprintf('RMSE diff:      %.6g m/s\n', rmseDiff);
fprintf('Max abs diff:   %.6g m/s\n', maxAbsDiff);
fprintf('\nDirect viscous mRLFE atlas evaluator test passed.\n');
