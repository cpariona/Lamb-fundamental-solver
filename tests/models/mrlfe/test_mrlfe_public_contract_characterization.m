clear; clc;
startup

fprintf('\nRunning mRLFE public route characterization test...\n');
fprintf('--------------------------------------------------\n');

cases = [ ...
    struct('branch', "A0Like", 'etaS', 0.00), ...
    struct('branch', "A0Like", 'etaS', 0.05), ...
    struct('branch', "A0Like", 'etaS', 0.10), ...
    struct('branch', "S0Like", 'etaS', 0.00), ...
    struct('branch', "S0Like", 'etaS', 0.05)];

for i = 1:numel(cases)
    request = localRequest(cases(i).branch, cases(i).etaS, "fast");
    result = mrlfeSolve(request);
    configuration = mrlfeResolveConfiguration(request);
    [baselineCp, baselineRaw] = mrlfeEvaluateAtlasFitModel(configuration.solverParams, ...
        request.frequency_Hz, request.branch, configuration.internalOptions);
    baselineValid = logical(baselineRaw.validMask(:)) & isfinite(baselineCp(:));

    assert(isequal(result.frequency_Hz, request.frequency_Hz(:)), 'Frequency grid mismatch.');
    assert(isequal(result.validMask, baselineValid(:)), ...
        'Valid mask mismatch for %s etaS %.3g.', request.branch, cases(i).etaS);
    common = result.validMask & baselineValid(:) & isfinite(result.phaseVelocity_mps) & isfinite(baselineCp(:));
    assert(any(common), 'No common finite points for %s etaS %.3g.', request.branch, cases(i).etaS);
    maxAbsDiff = max(abs(result.phaseVelocity_mps(common) - baselineCp(common)));
    assert(maxAbsDiff <= 1e-10, ...
        'Fast public result differs from FitTool atlas baseline by %.6g m/s.', maxAbsDiff);
    assert(result.execution.requestedPreset == "fast", 'Requested preset must be fast.');
    assert(result.execution.effectivePreset == "fast", 'Effective preset must be fast.');
    assert(result.fallback.applied == false, 'Fallback must not be applied.');
end

for branch = ["A0Like", "S0Like"]
    fast = mrlfeSolve(localRequest(branch, 0.05, "fast"));
    dense = mrlfeSolve(localRequest(branch, 0.05, "dense"));
    overlap = fast.validMask & dense.validMask & ...
        isfinite(fast.phaseVelocity_mps) & isfinite(dense.phaseVelocity_mps);
    assert(any(overlap), 'Fast and dense presets must have finite overlap for %s.', branch);
    assert(fast.execution.effectivePreset == "fast", 'Fast effective preset mismatch.');
    assert(dense.execution.effectivePreset == "dense", 'Dense effective preset mismatch.');
end

fprintf('mRLFE public route characterization test passed.\n');

function request = localRequest(branch, etaS, preset)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', string(preset));
request.selection = struct('strategy', "adaptive");
if branch == "A0Like"
    request.termination = struct('policy', "physicalTail");
else
    request.termination = struct('policy', "none");
end
request.fallback = struct('policy', "none");
end
