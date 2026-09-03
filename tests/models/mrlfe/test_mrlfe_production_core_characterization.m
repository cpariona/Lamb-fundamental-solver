clear; clc;
configureTestPath;
fprintf('\nRunning mRLFE production core characterization test...\n');
fprintf('-----------------------------------------------------\n');

fastStats = runMatrix("fast", [50e3 75e3 158e3 250e3], [0 0.05 0.10], ["A0Like" "S0Like"]);
denseStats = runMatrix("dense", 75e3, [0 0.05 0.10], ["A0Like" "S0Like"]);

assert(fastStats.caseCount == 24, 'Fast characterization matrix should contain 24 cases.');
assert(denseStats.caseCount == 6, 'Dense characterization subset should contain 6 cases.');
assert(fastStats.validMaskDifferences == 0, 'Fast characterization had valid-mask differences.');
assert(denseStats.validMaskDifferences == 0, 'Dense characterization had valid-mask differences.');
assert(fastStats.maxAbsDifference_mps <= 1e-10, 'Fast max Cp difference exceeded tolerance.');
assert(denseStats.maxAbsDifference_mps <= 1e-10, 'Dense max Cp difference exceeded tolerance.');

fprintf('Fast cases:        %d\n', fastStats.caseCount);
fprintf('Fast max abs diff: %.6g m/s\n', fastStats.maxAbsDifference_mps);
fprintf('Fast max rel diff: %.6g\n', fastStats.maxRelativeDifference);
fprintf('Dense cases:       %d\n', denseStats.caseCount);
fprintf('Dense max abs diff %.6g m/s\n', denseStats.maxAbsDifference_mps);
fprintf('Dense max rel diff %.6g\n', denseStats.maxRelativeDifference);
fprintf('mRLFE production core characterization test passed.\n');

function stats = runMatrix(preset, muValues, etaSValues, branches)
stats = struct('caseCount', 0, 'validMaskDifferences', 0, ...
    'maxAbsDifference_mps', 0, 'maxRelativeDifference', 0);

for branch = branches
    for etaS = etaSValues
        for mu = muValues
            request = localRequest(branch, etaS, mu, preset);
            result = mrlfeSolve(request);

            stats.caseCount = stats.caseCount + 1;
            assert(isequal(result.frequency_Hz, request.frequency_Hz(:)), 'Frequency grid mismatch.');
            assert(numel(result.validMask) == numel(request.frequency_Hz), ...
                'Valid mask length mismatch for %s etaS %.3g mu %.6g preset %s.', branch, etaS, mu, preset);
            assert(any(result.validMask), ...
                'No valid points for %s etaS %.3g mu %.6g preset %s.', branch, etaS, mu, preset);
            assert(result.execution.requestedPreset == string(preset), 'Requested preset mismatch.');
            assert(result.execution.effectivePreset == string(preset), 'Effective preset mismatch.');
            assert(any(result.execution.internalEngine == ["elastic_adaptive", "viscoelastic_adaptive"]), ...
                'Internal engine must use a neutral production name.');
            assert(result.fallback.applied == false, 'Fallback must not be applied.');
        end
    end
end
end

function request = localRequest(branch, etaS, mu, preset)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 12000, 20).';
request.material = struct('mu_Pa', mu, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
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
