function tests = test_mrlfe_joint_repetitions_contract()
%TEST_MRLFE_JOINT_REPETITIONS_CONTRACT Public mRLFE fitting keeps repeated rows.
%   Out-of-order duplicate positive frequencies, an excluded DC row and the
%   explicit validMask must pass through lamb.fitting.mrlfe unchanged.
tests = functiontests(localfunctions);
end

function testDuplicatePositiveRowsDcAndMaskPreserved(testCase)
trueParams = lamb.fitting.mrlfe.mrlfeDefaultFitParameters();
trueParams.mu = 75e3;
trueParams.thickness = 0.50e-3;
trueParams.rho = 1070;
trueParams.nu = 0.4999;

% Out-of-order repetitions of positive frequencies plus an excluded DC row.
frequency_Hz = [4000; 2000; 4000; 0; 8000; 2000; 6000; 6000];
validMask = [true; true; true; false; true; true; true; false];

solverOptions = lamb.fitting.mrlfe.mrlfeDefaultFitOptions("A0Like", 'EtaS', 0.0);
Cp_mps = nan(size(frequency_Hz));
positive = frequency_Hz > 0;
Cp_mps(positive) = lamb.fitting.mrlfe.mrlfeEvaluateFitModel( ...
    trueParams, frequency_Hz(positive), "A0Like", solverOptions);
% Masked-out positive row holds a deliberately wrong value that must not be used.
Cp_mps(end) = 10 * max(Cp_mps(positive));

experimental = struct('frequency_Hz', frequency_Hz, 'Cp_mps', Cp_mps, 'validMask', validMask);
experimentalBefore = experimental;

fitConfig = struct();
fitConfig.branchName = "A0Like";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', trueParams.thickness, ...
    'rho', trueParams.rho, 'nu', trueParams.nu);
fitConfig.initialGuess = struct('mu', 50e3);
fitConfig.bounds = struct('mu', [20e3, 160e3]);
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 35, 'MaxFunEvals', 70, 'TolX', 1e-4));

fitResult = lamb.fitting.mrlfe.mrlfeFitDispersionData(experimental, fitConfig);

% Input observations and explicit mask are not repaired, reordered or deduplicated.
verifyEqual(testCase, experimental.frequency_Hz, experimentalBefore.frequency_Hz);
verifyEqual(testCase, experimental.validMask, experimentalBefore.validMask);
verifyEqual(testCase, experimental.Cp_mps, experimentalBefore.Cp_mps);

% Fit uses the repeated rows and recovers the true parameter, ignoring DC and masked rows.
verifyEqual(testCase, fitResult.bestParams.mu, trueParams.mu, 'RelTol', 0.03);

verifyEqual(testCase, fitResult.frequency_Hz, frequency_Hz);
verifyEqual(testCase, fitResult.Cp_exp_mps, Cp_mps);
verifyEqual(testCase, fitResult.validMask, validMask);
verifyTrue(testCase, isnan(fitResult.Cp_fit_mps(4)));
verifyEqual(testCase, numel(fitResult.residuals), nnz(validMask));
end
