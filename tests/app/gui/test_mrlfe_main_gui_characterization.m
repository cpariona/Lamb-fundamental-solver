function test_mrlfe_main_gui_characterization()
%TEST_MRLFE_MAIN_GUI_CHARACTERIZATION Characterize Main GUI/public solver equivalence.

fprintf('\nRunning mRLFE Main GUI public-solver characterization test...\n');
fprintf('----------------------------------------------------------------\n');

branches = ["A0Like", "S0Like"];
etaValues = [0, 0.05, 0.10];
muValues = [50e3, 75e3, 158e3, 250e3];

maxAbsDiff = 0;
maxRelDiff = 0;
validMaskDiffs = 0;
caseCount = 0;

for branchName = branches
    for etaS = etaValues
        for mu = muValues
            [out, request] = runMainCase(branchName, etaS, mu);
            guiResult = out.metadata.modelResults.(char(branchName));
            directResult = mrlfeSolve(request);

            assert(isequal(guiResult.frequency_Hz(:), directResult.frequency_Hz(:)), ...
                'Frequency grid changed.');
            assert(guiResult.branch == directResult.branch, 'Branch identity changed.');
            assert(guiResult.execution.effectivePreset == directResult.execution.effectivePreset, ...
                'Effective preset changed.');
            assert(guiResult.termination.policy == directResult.termination.policy, ...
                'Termination policy changed.');
            assert(guiResult.fallback.policy == "none" && directResult.fallback.policy == "none", ...
                'Fallback policy must be none.');

            bothFinite = isfinite(guiResult.phaseVelocity_mps(:)) & isfinite(directResult.phaseVelocity_mps(:));
            if any(bothFinite)
                absDiff = max(abs(guiResult.phaseVelocity_mps(bothFinite) - directResult.phaseVelocity_mps(bothFinite)));
                relDiff = max(abs(guiResult.phaseVelocity_mps(bothFinite) - directResult.phaseVelocity_mps(bothFinite)) ./ ...
                    max(abs(directResult.phaseVelocity_mps(bothFinite)), eps));
                maxAbsDiff = max(maxAbsDiff, absDiff);
                maxRelDiff = max(maxRelDiff, relDiff);
            end
            validMaskDiffs = validMaskDiffs + nnz(guiResult.validMask(:) ~= directResult.validMask(:));
            caseCount = caseCount + 1;
        end
    end
end

assert(maxAbsDiff == 0, 'Main GUI Cp must equal direct mrlfeSolve.');
assert(maxRelDiff == 0, 'Main GUI relative Cp difference must be zero.');
assert(validMaskDiffs == 0, 'Main GUI valid mask must equal direct mrlfeSolve.');

fprintf('Characterization cases: %d\n', caseCount);
fprintf('Maximum Cp absolute difference: %.12g m/s\n', maxAbsDiff);
fprintf('Maximum Cp relative difference: %.12g\n', maxRelDiff);
fprintf('Valid-mask differences: %d\n', validMaskDiffs);
fprintf('\nmRLFE Main GUI public-solver characterization test passed.\n');
end

function [out, request] = runMainCase(branchName, etaS, mu)
params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 12000;
params.numFrequencyPoints = 20;
params.frequencySpacing = "linspace";
params.mu = mu;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.4999;

options = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
options.branchNames = branchName;
options.mrlfeA0Policy = "physicalTail";
options.mrlfeParams = mrlfeDefaultInternalParameters();
options.mrlfeParams.etaS = etaS;
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;

out = guiRunMRLFEModel(struct('params', params, 'options', options, ...
    'mrlfeParams', options.mrlfeParams, 'computeVisco', etaS > 0));
request = mrlfeBuildSolveRequest(params, rlBuildFrequencyVector(params), branchName, options);
end
