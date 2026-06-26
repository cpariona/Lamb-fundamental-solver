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
atlasOptions.mrlfeViscoAtlasCpScanPoints = 900;
atlasOptions.mrlfeViscoAtlasCandidates = 8;
atlasOptions.mrlfeViscoAtlasCpWindow = [0.25, 3.00];
atlasOptions.mrlfeViscoAtlasSeedWeight = 0.10;
atlasOptions.mrlfeViscoAtlasResidualWeight = 0.45;
atlasOptions.mrlfeViscoAtlasJumpWeight = 18.0;
atlasOptions.mrlfeViscoAtlasCurvatureWeight = 12.0;
atlasOptions.mrlfeViscoAtlasResidualTolerance = 1e-3;

[CpReference, rawReference] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, referenceOptions);
[CpAtlas, rawAtlas] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, atlasOptions);

valid = isfinite(CpReference(:)) & isfinite(CpAtlas(:));
assert(all(valid), 'Reference and direct atlas evaluations must be finite at all requested frequencies.');
assert(isfield(rawAtlas, 'evaluationPath'), 'Direct atlas evaluator must report evaluationPath.');
assert(rawAtlas.evaluationPath.useDirectViscoAtlas == true, 'Direct atlas evaluator did not report the atlas path.');
assert(rawAtlas.evaluationPath.path == "direct_viscous_atlas", 'Unexpected direct atlas evaluation path name.');
assert(isfield(rawAtlas.branch, 'viscoAtlas'), 'Direct atlas branch must expose viscoAtlas diagnostics.');
assert(rawAtlas.branch.viscoAtlas.usedElasticMRLFEReference == false, ...
    'Direct viscous atlas must not use an elastic mRLFE reference branch.');
assert(all(rawAtlas.branch.validCp(:)), 'Direct viscous atlas branch should be strictly valid for this baseline case.');

rmseDiff = sqrt(mean((CpAtlas(:) - CpReference(:)).^2));
maxAbsDiff = max(abs(CpAtlas(:) - CpReference(:)));
assert(rmseDiff < 0.02, 'Direct viscous atlas Cp RMSE difference is too large.');
assert(maxAbsDiff < 0.03, 'Direct viscous atlas maximum Cp difference is too large.');

fprintf('Reference path: %s\n', rawReference.evaluationPath.path);
fprintf('Atlas path:     %s\n', rawAtlas.evaluationPath.path);
fprintf('RMSE diff:      %.6g m/s\n', rmseDiff);
fprintf('Max abs diff:   %.6g m/s\n', maxAbsDiff);
fprintf('\nDirect viscous mRLFE atlas evaluator test passed.\n');
