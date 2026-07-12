clear; clc;
startup

%TEST_MRLFE_SOLVE_FREQUENCY_OVERRIDE Contract test for diagnostic solve grids.

requestedFrequency_Hz = [100 1000 4000].';
solveFrequency_Hz = [100 125 150 200 300 500 750 1000 1500 2500 4000].';

request = struct();
request.branch = "A0Like";
request.frequency_Hz = requestedFrequency_Hz;
request.material = struct( ...
    'mu_Pa', 75e3, ...
    'etaS_Pas', 0, ...
    'rho_kgm3', 1070, ...
    'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct( ...
    'preset', "fast", ...
    'frequencySolveOverride_Hz', solveFrequency_Hz);
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");

configuration = mrlfeResolveConfiguration(request);
problem = mrlfeBuildProblem(configuration);

assert(isequal(problem.frequencyRequested_Hz, requestedFrequency_Hz), ...
    'Requested frequencies must remain unchanged.');
assert(isequal(problem.frequencySolve_Hz, solveFrequency_Hz), ...
    'Internal solve frequencies must equal the exact diagnostic override.');
assert(problem.frequencyGrid.source == "diagnosticOverride", ...
    'Grid metadata must report diagnosticOverride.');
assert(problem.params.frequencySpacing == "explicit", ...
    'Rayleigh-Lamb seed parameters must use explicit spacing.');
assert(isequal(problem.params.frequencyVector_Hz(:), solveFrequency_Hz), ...
    'Seed frequency vector must equal the internal solve grid.');
assert(isequal(problem.rawSeedResult.frequency(:), solveFrequency_Hz), ...
    'Rayleigh-Lamb seed result must be evaluated on the exact solve grid.');

result = mrlfeSolve(request);
assert(isequal(result.frequency_Hz(:), requestedFrequency_Hz), ...
    'Public mRLFE output must remain on the requested frequency grid.');

badRequest = request;
badRequest.numerics.frequencySolveOverride_Hz = [200 500 2000].';
failedAsExpected = false;
try
    mrlfeBuildProblem(mrlfeResolveConfiguration(badRequest));
catch ME
    failedAsExpected = strcmp(ME.identifier, 'mrlfe:InvalidSolveFrequencyCoverage');
end
assert(failedAsExpected, ...
    'An override that does not cover the requested interval must be rejected.');

fprintf(['test_mrlfe_solve_frequency_override passed. Exact internal grids are ' ...
    'supported without changing the public output grid.\n']);
