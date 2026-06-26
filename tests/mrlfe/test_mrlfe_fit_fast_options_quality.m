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

[CpReference_mps, rawReference] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, referenceOptions);
[CpFast_mps, rawFast] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, fastOptions);

valid = isfinite(CpReference_mps(:)) & isfinite(CpFast_mps(:));
assert(all(valid), 'Reference and fast mRLFE fitting evaluations must both be valid at all requested frequencies.');

diff_mps = CpFast_mps(:) - CpReference_mps(:);
rmseDiff_mps = sqrt(mean(diff_mps.^2));
maxAbsDiff_mps = max(abs(diff_mps));
maxRelDiff = max(abs(diff_mps) ./ max(abs(CpReference_mps(:)), eps));

assert(isfield(rawFast, 'fitPerformanceDefaults'), 'Fast mRLFE fitting evaluation must report fit performance defaults.');
assert(rawFast.fitPerformanceDefaults.useFitPerformanceDefaults == true, ...
    'mRLFE fitting performance defaults should be enabled by default.');
assert(rawFast.fitPerformanceDefaults.useInternalTrackingGrid == true, ...
    'mRLFE fitting performance defaults should enable internal tracking grid.');
assert(rawFast.fitPerformanceDefaults.internalTrackingMinPoints == 10, ...
    'Unexpected mRLFE fast fitting internal tracking min points.');
assert(rawFast.fitPerformanceDefaults.internalTrackingPointFactor == 1, ...
    'Unexpected mRLFE fast fitting internal tracking point factor.');
assert(rawFast.fitPerformanceDefaults.a0DpCpScanPoints == 500, ...
    'Unexpected mRLFE fast fitting A0 DP Cp scan points.');
assert(rmseDiff_mps < 0.05, 'Fast mRLFE fitting Cp RMSE difference is too large relative to reference.');
assert(maxAbsDiff_mps < 0.05, 'Fast mRLFE fitting maximum Cp difference is too large relative to reference.');
assert(maxRelDiff < 0.01, 'Fast mRLFE fitting maximum relative Cp difference is too large relative to reference.');

fprintf('Reference preset: trackingMinPoints=%g | pointFactor=%g | cpScanPoints=%g\n', ...
    rawReference.fitPerformanceDefaults.internalTrackingMinPoints, ...
    rawReference.fitPerformanceDefaults.internalTrackingPointFactor, ...
    rawReference.fitPerformanceDefaults.a0DpCpScanPoints);
fprintf('Fast preset:      trackingMinPoints=%g | pointFactor=%g | cpScanPoints=%g\n', ...
    rawFast.fitPerformanceDefaults.internalTrackingMinPoints, ...
    rawFast.fitPerformanceDefaults.internalTrackingPointFactor, ...
    rawFast.fitPerformanceDefaults.a0DpCpScanPoints);
fprintf('RMSE difference: %.6g m/s\n', rmseDiff_mps);
fprintf('Max abs diff:    %.6g m/s\n', maxAbsDiff_mps);
fprintf('Max rel diff:    %.6g\n', maxRelDiff);
fprintf('\nmRLFE fast fitting option quality test passed.\n');
