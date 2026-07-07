clear; clc;
startup

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
            params = mrlfeDefaultSweepParams();
            params.mu = muValues_Pa(iMu);
            params.etaS = etaS;
            params.thickness = 0.5e-3;
            params.rho = 1070;
            params.nu = 0.4999;

            options = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS, ...
                'UseUnifiedAtlasRoute', true, 'A0Policy', "adaptivePhysicalTail");
            options.mrlfeUseAtlasFitRoute = true;
            options.mrlfeFitAtlasPreset = "fast_fit_atlas";

            [CpPublic_mps, rawPublic] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
            [CpOracle_mps, rawOracle] = mrlfeEvaluateAtlasFitModel(params, frequency_Hz, branchName, options);

            assert(isequal(rawPublic.frequency_Hz(:), rawOracle.frequency_Hz(:)), ...
                'Frequency grid changed during public-solver migration.');
            assert(rawPublic.branchName == rawOracle.branchName, 'Branch identity changed.');
            assert(rawPublic.modelResult.execution.effectivePreset == "fast", ...
                'Maintained fitting route must use public fast preset.');
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
            validOracle = logical(rawOracle.validMask(:));
            validMaskDifferences = validMaskDifferences + nnz(validPublic ~= validOracle);

            comparable = validPublic & validOracle & isfinite(CpPublic_mps(:)) & isfinite(CpOracle_mps(:));
            if any(comparable)
                diff_mps = abs(CpPublic_mps(comparable) - CpOracle_mps(comparable));
                maxAbsDiff_mps = max(maxAbsDiff_mps, max(diff_mps));
                maxRelDiff = max(maxRelDiff, max(diff_mps ./ max(abs(CpOracle_mps(comparable)), eps)));
            end
            caseCount = caseCount + 1;
        end
    end
end

assert(validMaskDifferences == 0, 'Public solver changed fitting valid masks.');
assert(maxAbsDiff_mps < 1e-9, 'Public solver Cp differs from retained oracle.');
assert(maxRelDiff < 1e-12, 'Public solver relative Cp differs from retained oracle.');

fprintf('Characterization cases: %d\n', caseCount);
fprintf('Maximum Cp absolute difference: %.15g m/s\n', maxAbsDiff_mps);
fprintf('Maximum Cp relative difference: %.15g\n', maxRelDiff);
fprintf('Valid-mask differences: %d\n', validMaskDifferences);
fprintf('\nmRLFE fitting public-solver characterization test passed.\n');
