function test_mrlfe_production_core_characterization()
%TEST_MRLFE_PRODUCTION_CORE_CHARACTERIZATION Characterize maintained production coverage.

fprintf('\nRunning mRLFE production core characterization test...\n');
fprintf('-----------------------------------------------------\n');

fastResults = runMatrix("fast", [50e3 75e3 158e3 250e3], [0 0.05 0.10], ["A0Like" "S0Like"]);
denseResults = runMatrix("dense", 75e3, [0 0.05 0.10], ["A0Like" "S0Like"]);

assert(numel(fastResults) == 24, 'Fast characterization matrix should contain 24 cases.');
assert(numel(denseResults) == 6, 'Dense characterization subset should contain 6 cases.');

fprintf('Fast 24 / Dense 6 schema and coverage checked.\n');
fprintf('mRLFE production core characterization test passed.\n');
end

function results = runMatrix(preset, muValues, etaSValues, branches)
results = cell(0,1);

for branch = branches
    for etaS = etaSValues
        for mu = muValues
            request = localRequest(branch, etaS, mu, preset);
            result = lamb.models.mrlfe.mrlfeSolve(request);

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
