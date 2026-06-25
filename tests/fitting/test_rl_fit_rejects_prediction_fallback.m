clear; clc;
startup

fprintf('\nRunning RL fitting prediction-fallback rejection test...\n');
fprintf('----------------------------------------------------\n');

frequency_Hz = linspace(1000, 8000, 12).';
Cp_mps = 6.0 * ones(size(frequency_Hz));
experimental = struct();
experimental.frequency_Hz = frequency_Hz;
experimental.Cp_mps = Cp_mps;
experimental.validMask = true(size(frequency_Hz));

params = rlDefaultParams();
fitConfig = struct();
fitConfig.branchName = "A0";
fitConfig.freeParams = "mu";
fitConfig.fixedParams = struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu);
fitConfig.initialGuess = struct('mu', 158e3);
fitConfig.bounds = struct('mu', [31.6e3, 200e3]);
fitConfig.solverOptions = rlDefaultOptions("Fast");
fitConfig.fitOptions = struct('useStandardErrorWeights', false, 'minValidFraction', 0.80);

failedAsExpected = false;
try
    fitResult = rlFitDispersionData(experimental, fitConfig); %#ok<NASGU>
catch ME
    failedAsExpected = contains(ME.message, 'No valid model/experimental point pairs') || ...
        contains(ME.message, 'Insufficient valid Rayleigh-Lamb model coverage') || ...
        contains(ME.message, 'Could not refine initial root');
end

assert(failedAsExpected, ...
    'Flat RL A0 fitting should fail instead of using prediction fallback as fitted data.');

fprintf('\nRL fitting prediction-fallback rejection test passed.\n');
