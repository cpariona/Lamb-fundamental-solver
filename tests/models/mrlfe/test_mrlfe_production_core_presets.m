function test_mrlfe_production_core_presets()
%TEST_MRLFE_PRODUCTION_CORE_PRESETS Validate maintained production presets.

fprintf('\nRunning mRLFE production core preset test...\n');
fprintf('-------------------------------------------\n');

for preset = ["fast", "balanced", "robust", "dense"]
    for branch = ["A0Like", "S0Like"]
        result = lamb.models.mrlfe.mrlfeSolve(localRequest(branch, 0.05, preset, "physicalTail"));
        assert(result.execution.requestedPreset == preset, 'Requested preset mismatch.');
        assert(result.execution.effectivePreset == preset, 'Effective preset mismatch.');
        assert(any(result.validMask & isfinite(result.phaseVelocity_mps)), ...
            'Preset %s did not produce finite values for %s.', preset, branch);
    end
end

fprintf('mRLFE production core preset test passed.\n');
end

function request = localRequest(branch, etaS, preset, terminationPolicy)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', string(preset));
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', string(terminationPolicy));
request.fallback = struct('policy', "none");
end
