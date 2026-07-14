clear; clc;
startup

fprintf('\nRunning mRLFE fast fitting option quality test...\n');
fprintf('------------------------------------------------\n');

branchName = "A0Like";
etaS = 0.0;
params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.thickness = 0.50e-3;
params.rho = 1070;
params.nu = 0.4999;
params.etaS = etaS;
frequency_Hz = linspace(1000, 8000, 10).';

referenceOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
referenceOptions.mrlfeUseFitPerformanceDefaults = false;
referenceOptions.mrlfeUseInternalTrackingGrid = true;
referenceOptions.mrlfeInternalTrackingMinPoints = 30;
referenceOptions.mrlfeInternalTrackingPointFactor = 2;
referenceOptions.mrlfeInternalTrackingMaxPoints = 80;
referenceOptions.mrlfeA0DPCpScanPoints = 2200;
referenceOptions.mrlfeA0DPCandidates = 8;

fastOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);

[CpFast_mps, rawFast] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, fastOptions);
request = mrlfeBuildFitSolveRequest(params, frequency_Hz, branchName, fastOptions);
direct = mrlfeSolve(request);

valid = rawFast.validMask(:) & direct.validMask(:) & isfinite(CpFast_mps(:)) & isfinite(direct.phaseVelocity_mps(:));
assert(any(valid), 'Public fast mRLFE fitting evaluations must have valid requested frequencies.');

diff_mps = CpFast_mps(valid) - direct.phaseVelocity_mps(valid);
rmseDiff_mps = sqrt(mean(diff_mps.^2));
maxAbsDiff_mps = max(abs(diff_mps));
maxRelDiff = max(abs(diff_mps) ./ max(abs(direct.phaseVelocity_mps(valid)), eps));

assert(isfield(rawFast, 'fitPerformanceDefaults'), 'Fast mRLFE fitting evaluation must report fit performance defaults.');
assert(rawFast.evaluationPath.usedPublicSolver == true, ...
    'mRLFE fitting evaluation should use the public solver route.');
assert(rawFast.modelResult.execution.requestedPreset == "fast", ...
    'mRLFE fitting evaluation should request the public fast preset.');
assert(rawFast.modelResult.execution.effectivePreset == "fast", ...
    'mRLFE fitting evaluation should use the public fast preset.');
assert(rawFast.fitPerformanceDefaults.preset == "fast", ...
    'Fast mRLFE fitting should report the public fast preset.');
assert(rawFast.fitPerformanceDefaults.internalFitAtlasPreset == "fast", ...
    'Fast mRLFE fitting should report the neutral internal preset.');
assert(rawFast.fitPerformanceDefaults.atlasCpScanPoints == 260, ...
    'Public fast mRLFE fitting should use 260 Cp scan points.');
assert(rawFast.fitPerformanceDefaults.a0DpCandidates == 5, ...
    'Public fast mRLFE fitting should use five candidates.');
assert(rmseDiff_mps == 0, 'Public fast fitting Cp RMSE differs from direct solver.');
assert(maxAbsDiff_mps == 0, 'Public fast fitting maximum Cp difference differs from direct solver.');
assert(maxRelDiff == 0, 'Public fast fitting maximum relative Cp difference differs from direct solver.');

% The automatic fast preset is intentionally elastic-only. Viscous real-k fitting
% keeps the maintained external defaults until a separate viscous
% option-sensitivity diagnostic validates a faster configuration. The actual
% viscous internal grid is enabled deeper in rlComputeFundamentalLambModes;
% rawVisco.fitPerformanceDefaults intentionally reports the external fitting
% options, not the internal viscoOptions object.
viscoParams = params;
viscoParams.etaS = 0.12;
viscoOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', viscoParams.etaS);
[CpVisco_mps, rawVisco] = mrlfeEvaluateFitModel(viscoParams, frequency_Hz, branchName, viscoOptions);
assert(any(isfinite(CpVisco_mps)), 'Viscous mRLFE fitting evaluation produced no finite Cp points.');
assert(rawVisco.evaluationPath.usedPublicSolver == true, ...
    'Viscous mRLFE fitting evaluation should use the public solver route.');
assert(rawVisco.modelResult.execution.effectivePreset == "fast", ...
    'Viscous mRLFE fitting should use the public fast preset.');
assert(rawVisco.fitPerformanceDefaults.atlasCpScanPoints == 260, ...
    'Viscous public fast fitting should use the fast production scan count.');
assert(rawVisco.modelResult.fallback.applied == false, ...
    'Viscous public fast fitting must not apply fallback.');

fprintf('Fast preset:      public=%s | internal=%s | cpScanPoints=%g\n', ...
    rawFast.fitPerformanceDefaults.preset, ...
    rawFast.fitPerformanceDefaults.internalFitAtlasPreset, ...
    rawFast.fitPerformanceDefaults.atlasCpScanPoints);
fprintf('Viscous preset:   public=%s | engine=%s | cpScanPoints=%g\n', ...
    rawVisco.fitPerformanceDefaults.preset, ...
    rawVisco.modelResult.execution.internalEngine, ...
    rawVisco.fitPerformanceDefaults.atlasCpScanPoints);
fprintf('RMSE difference: %.6g m/s\n', rmseDiff_mps);
fprintf('Max abs diff:    %.6g m/s\n', maxAbsDiff_mps);
fprintf('Max rel diff:    %.6g\n', maxRelDiff);
fprintf('\nmRLFE fast fitting option quality test passed.\n');
