function test_rl_fit_evaluator_branch_consistency()
%TEST_RL_FIT_EVALUATOR_BRANCH_CONSISTENCY Validate branch-coherent fitting evaluation.

fprintf('\nRunning Rayleigh-Lamb fitting evaluator branch-consistency test...\n');
fprintf('---------------------------------------------------------------\n');

params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.mu = 90e3;
params.thickness = 0.50e-3;
params.rho = 1070;
params.nu = 0.4999;

frequency_Hz = [9000; 10000; 11000; 12000];
options = lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");

[CpFit_mps, rawFit] = rlEvaluateFitModel(params, frequency_Hz, "A0", options);
assert(all(isfinite(CpFit_mps) & CpFit_mps > 0), 'Branch-coherent fit evaluator returned invalid requested Cp values.');
assert(rawFit.trackingMode == "branch_coherent_internal_grid", 'Unexpected RL fitting tracking mode.');
assert(isfield(rawFit, 'internalFrequency_Hz') && numel(rawFit.internalFrequency_Hz) >= numel(frequency_Hz), ...
    'Fit evaluator must expose its internal tracking grid.');
assert(isfield(rawFit, 'reliability') && rawFit.reliability.SelectionFallbackUsed == false, ...
    'Fit evaluator must not report prediction fallback as official fitting output.');
assert(isfield(rawFit, 'diagnostics') && isinf(rawFit.diagnostics.maxPredictionRelativeError), ...
    'Fit evaluator should not use prediction error as a hard fitting rejection gate by default.');
assert(rawFit.diagnostics.jumpTol >= 0.80, ...
    'Fit evaluator should use a permissive internal jump tolerance by default.');

referenceParams = params;
referenceParams.fmin = min(rawFit.internalFrequency_Hz);
referenceParams.fmax = max(rawFit.internalFrequency_Hz);
referenceParams.numFrequencyPoints = 220;
referenceParams.frequencySpacing = "linspace";
referenceOptions = options;
referenceOptions.computeA0 = true;
referenceOptions.computeS0 = false;

reference = lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(referenceParams, referenceOptions);
CpReference_mps = interp1(reference.modes.A0.frequency_Hz, reference.modes.A0.phaseVelocity_mps, frequency_Hz, 'linear', NaN);

relativeDifference = abs(CpFit_mps - CpReference_mps) ./ max(CpReference_mps, eps);
assert(all(isfinite(relativeDifference)), 'Reference comparison produced invalid relative differences.');
assert(max(relativeDifference) < 0.05, ...
    'Branch-coherent fit evaluator differs from the maintained A0 solver by more than 5%%.');

internalValid = rawFit.internalValidMask(:);
internalCp = rawFit.internalCp_mps(internalValid);
relativeJump = abs(diff(internalCp)) ./ max(internalCp(1:end-1), eps);
assert(isempty(relativeJump) || max(relativeJump) < rawFit.diagnostics.jumpTol, ...
    'Internal branch contains a jump larger than the configured fitting continuation tolerance.');

fprintf('Max relative difference to maintained A0 solver: %.6g\n', max(relativeDifference));
if isempty(relativeJump)
    fprintf('Internal branch max relative jump: NaN\n');
else
    fprintf('Internal branch max relative jump: %.6g\n', max(relativeJump));
end
fprintf('\nRayleigh-Lamb fitting evaluator branch-consistency test passed.\n');
end
