function test_mrlfe_sweep_point_characterization()
%TEST_MRLFE_SWEEP_POINT_CHARACTERIZATION Compare sweep points with direct public solves.

fprintf('\nRunning mRLFE SweepTool point characterization test...\n');
fprintf('-----------------------------------------------------\n');

branches = ["A0Like", "S0Like"];
etaSValues = [0, 0.05, 0.10];
muValues_kPa = [50, 75, 158, 250];

caseCount = 0;
maxAbsDiff_mps = 0;
maxRelDiff = 0;
validMaskDifferences = 0;

for iBranch = 1:numel(branches)
    branchName = branches(iBranch);
    for iEta = 1:numel(etaSValues)
        etaS = etaSValues(iEta);
        out = runMuSweep(branchName, etaS, muValues_kPa);
        assert(numel(out.sweepResult.points) == numel(muValues_kPa), ...
            'SweepTool must preserve point count.');
        assert(isequal(out.sweepSpec.values(:), muValues_kPa(:) * 1e3), ...
            'SweepTool must preserve mu point ordering and units.');

        for iPoint = 1:numel(muValues_kPa)
            point = out.sweepResult.points{iPoint};
            storedRequest = out.sweepResult.requests{iPoint};
            assert(isstruct(storedRequest) && isfield(storedRequest, 'parameters') && ...
                isfield(storedRequest, 'options'), ...
                'Canonical sweep requests must preserve configuration.requested.');

            pointParams = out.sweepResult.params{iPoint};
            pointOptions = out.sweepResult.options{iPoint};
            directRequest = mrlfeBuildSolveRequest( ...
                pointParams, buildFrequencyVector(pointParams), branchName, pointOptions);
            direct = mrlfeSolve(directRequest);
            modelResult = point.modelResult;

            assert(point.status == "ok", 'Sweep point unexpectedly failed.');
            assert(isequal(modelResult.frequency_Hz(:), direct.frequency_Hz(:)), ...
                'Sweep point frequency grid changed.');
            assert(point.modelResult.branch == direct.branch, 'Sweep point branch changed.');
            assert(point.modelResult.execution.effectivePreset == "fast", ...
                'Sweep point effective preset must be fast.');
            assert(point.modelResult.fallback.applied == false, ...
                'Sweep point must not apply fallback.');

            validMaskDifferences = validMaskDifferences + nnz(modelResult.validMask(:) ~= direct.validMask(:));
            comparable = modelResult.validMask(:) & direct.validMask(:) & ...
                isfinite(modelResult.phaseVelocity_mps(:)) & isfinite(direct.phaseVelocity_mps(:));
            if any(comparable)
                diff_mps = abs(modelResult.phaseVelocity_mps(comparable) - direct.phaseVelocity_mps(comparable));
                maxAbsDiff_mps = max(maxAbsDiff_mps, max(diff_mps));
                maxRelDiff = max(maxRelDiff, max(diff_mps ./ max(abs(direct.phaseVelocity_mps(comparable)), eps)));
            end
            caseCount = caseCount + 1;
        end
    end
end

assert(validMaskDifferences == 0, 'SweepTool valid masks differ from direct mrlfeSolve.');
assert(maxAbsDiff_mps == 0, 'SweepTool Cp values differ from direct mrlfeSolve.');
assert(maxRelDiff == 0, 'SweepTool relative Cp values differ from direct mrlfeSolve.');

fprintf('Characterization cases: %d\n', caseCount);
fprintf('Maximum Cp absolute difference: %.15g m/s\n', maxAbsDiff_mps);
fprintf('Maximum Cp relative difference: %.15g\n', maxRelDiff);
fprintf('Valid-mask differences: %d\n', validMaskDifferences);
fprintf('\nmRLFE SweepTool point characterization test passed.\n');
end

function out = runMuSweep(branchName, etaS, muValues_kPa)
params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 12000;
params.numFrequencyPoints = 20;
params.frequencySpacing = "linspace";
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.4999;

controls = struct('robustness', "Fast", 'etaS', etaS, ...
    'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
    'mrlfeA0Policy', "physicalTail");

out = guiRunMRLFESweep(guiBuildSweepRequest("mrlfe", ...
    'modelLabel', "mRLFE real-k", ...
    'branchName', branchName, ...
    'sweepField', "mu", ...
    'sweepLabel', "mu", ...
    'sweepValuesDisplay', muValues_kPa, ...
    'displayUnit', "kPa", ...
    'displayScale', 1e3, ...
    'baseParams', params, ...
    'controls', controls));
end
