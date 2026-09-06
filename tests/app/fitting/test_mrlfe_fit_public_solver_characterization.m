function test_mrlfe_fit_public_solver_characterization()
%TEST_MRLFE_FIT_PUBLIC_SOLVER_CHARACTERIZATION Compare fitting evaluator with direct public solves.

fprintf('\nRunning mRLFE fitting public-solver characterization test...\n');
fprintf('------------------------------------------------------------\n');

branches = ["A0Like", "S0Like"];
etaSValues = [0, 0.05, 0.10];
muValues_Pa = [50, 75, 158, 250] * 1e3;
frequency_Hz = linspace(1000, 12000, 20).';

maxAbsDiff_mps = 0;
maxRelDiff = 0;
validMaskDifferences = 0;
caseCount = 0;

for iBranch = 1:numel(branches)
    branchName = branches(iBranch);
    for iEta = 1:numel(etaSValues)
        etaS = etaSValues(iEta);
        for iMu = 1:numel(muValues_Pa)
            params = lamb.fitting.mrlfe.mrlfeDefaultFitParameters();
            params.mu = muValues_Pa(iMu);
            params.etaS = etaS;
            params.thickness = 0.5e-3;
            params.rho = 1070;
            params.nu = 0.4999;

            options = lamb.fitting.mrlfe.mrlfeDefaultFitOptions(branchName, 'EtaS', etaS, ...
                'A0Policy', "physicalTail");
            options.forwardModel = struct( ...
                'gridPolicy', "fitOptimized", ...
                'minimumPointCount', 12, ...
                'maximumPointCount', 40, ...
                'maximumStep_Hz', 250);

            [CpPublic_mps, rawPublic] = lamb.fitting.mrlfe.mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);

            request = lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
            request.numerics.preset = "fast";
            [frequencySolve_Hz, ~] = lamb.fitting.mrlfe.mrlfeBuildFitFrequencyGrid(frequency_Hz, options.forwardModel);
            request.numerics.frequencySolveOverride_Hz = frequencySolve_Hz;
            direct = lamb.models.mrlfe.mrlfeSolve(request);

            assert(isequal(rawPublic.frequency_Hz(:), direct.frequency_Hz(:)), ...
                'Frequency grid changed during public-solver migration.');
            assert(rawPublic.branchName == direct.branch, 'Branch identity changed.');
            assert(rawPublic.modelResult.execution.effectivePreset == "fast", ...
                'Maintained fitting route must retain the selected public preset metadata.');
            assert(rawPublic.fitGrid.gridPolicy == "fitOptimized", ...
                'Maintained fitting route must report fitOptimized grid policy.');
            assert(isequal(rawPublic.frequencySolve_Hz(:), frequencySolve_Hz(:)), ...
                'Fitting evaluator did not use the expected optimized solve grid.');
            assert(rawPublic.modelResult.fallback.policy == "none" && rawPublic.modelResult.fallback.applied == false, ...
                'Maintained fitting route must not apply fallback.');
            if branchName == "A0Like"
                assert(rawPublic.modelResult.termination.policy == "physicalTail", ...
                    'A0Like fitting must preserve physicalTail termination.');
            else
                assert(rawPublic.modelResult.termination.policy == "none", ...
                    'S0Like fitting must preserve no additional termination.');
            end

            validPublic = logical(rawPublic.validMask(:));
            validDirect = logical(direct.validMask(:));
            validMaskDifferences = validMaskDifferences + nnz(validPublic ~= validDirect);

            comparable = validPublic & validDirect & isfinite(CpPublic_mps(:)) & isfinite(direct.phaseVelocity_mps(:));
            if any(comparable)
                diff_mps = abs(CpPublic_mps(comparable) - direct.phaseVelocity_mps(comparable));
                maxAbsDiff_mps = max(maxAbsDiff_mps, max(diff_mps));
                maxRelDiff = max(maxRelDiff, max(diff_mps ./ max(abs(direct.phaseVelocity_mps(comparable)), eps)));
            end
            caseCount = caseCount + 1;
        end
    end
end

assert(validMaskDifferences == 0, 'Fitting evaluator differs from direct public solver valid masks on the same optimized grid.');
assert(maxAbsDiff_mps == 0, 'Fitting evaluator Cp differs from direct public solver on the same optimized grid.');
assert(maxRelDiff == 0, 'Fitting evaluator relative Cp differs from direct public solver on the same optimized grid.');

fprintf('Characterization cases: %d\n', caseCount);
fprintf('Maximum Cp absolute difference: %.15g m/s\n', maxAbsDiff_mps);
fprintf('Maximum Cp relative difference: %.15g\n', maxRelDiff);
fprintf('Valid-mask differences: %d\n', validMaskDifferences);
fprintf('\nmRLFE fitting public-solver characterization test passed.\n');
end
