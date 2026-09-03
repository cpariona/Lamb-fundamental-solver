function [fastResults, denseResults] = test_mrlfe_production_core_characterization(referenceFile)
% Optional referenceFile contains fastResults/denseResults captured from an
% explicitly selected historical model tree. Never manufacture zero deltas
% when no independent reference was supplied.
fprintf('\nRunning mRLFE production core characterization test...\n');
fprintf('-----------------------------------------------------\n');

fastResults = runMatrix("fast", [50e3 75e3 158e3 250e3], [0 0.05 0.10], ["A0Like" "S0Like"]);
if nargin > 0
    reference = load(referenceFile, 'fastResults', 'denseResults');
    fastStats = compareResults(fastResults, reference.fastResults, "Fast");
end
denseResults = runMatrix("dense", 75e3, [0 0.05 0.10], ["A0Like" "S0Like"]);

assert(numel(fastResults) == 24, 'Fast characterization matrix should contain 24 cases.');
assert(numel(denseResults) == 6, 'Dense characterization subset should contain 6 cases.');

if nargin > 0
    denseStats = compareResults(denseResults, reference.denseResults, "Dense");
    assert(fastStats.maskDifferences == 0 && denseStats.maskDifferences == 0, ...
        'Historical valid masks differ.');
    assert(fastStats.maxAbs <= 1e-10 && denseStats.maxAbs <= 1e-10, ...
        'Historical Cp difference exceeds characterization tolerance.');
else
    fprintf('Fast 24 / Dense 6 schema and coverage checked; no historical delta claimed.\n');
end
fprintf('mRLFE production core characterization test passed.\n');
end

function results = runMatrix(preset, muValues, etaSValues, branches)
results = cell(0,1);

for branch = branches
    for etaS = etaSValues
        for mu = muValues
            request = localRequest(branch, etaS, mu, preset);
            result = mrlfeSolve(request);

            results{end+1,1} = result; %#ok<AGROW>
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

function stats = compareResults(actual, expected, label)
assert(numel(actual) == numel(expected), 'Historical case count differs.');
maxAbs = 0; maxRel = 0; maskDiffs = 0;
for i = 1:numel(actual)
    a = actual{i}; b = expected{i};
    assert(a.branch == b.branch && isequal(a.frequency_Hz, b.frequency_Hz));
    assert(a.execution.effectivePreset == b.execution.effectivePreset);
    assert(isequal(isfinite(a.phaseVelocity_mps), isfinite(b.phaseVelocity_mps)));
    maskDiffs = maskDiffs + nnz(a.validMask ~= b.validMask);
    finite = isfinite(a.phaseVelocity_mps) & isfinite(b.phaseVelocity_mps);
    assert(any(finite), 'Historical comparison needs finite overlap.');
    delta = abs(a.phaseVelocity_mps(finite) - b.phaseVelocity_mps(finite));
    fprintf('%s case %d %s: max abs %.12g m/s\n', label, i, a.branch, max(delta));
    maxAbs = max(maxAbs, max(delta));
    maxRel = max(maxRel, max(delta ./ max(abs(b.phaseVelocity_mps(finite)), eps)));
end
fprintf('%s cases %d | measured max abs %.12g m/s | max rel %.12g | masks %d\n', ...
    label, numel(actual), maxAbs, maxRel, maskDiffs);
stats = struct('maxAbs', maxAbs, 'maxRelative', maxRel, 'maskDifferences', maskDiffs);
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
