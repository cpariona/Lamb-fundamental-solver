%TEST_LIGHTWEIGHT_NUMERICAL_REGRESSION Small deterministic solver snapshots.
%
% These checks are intentionally narrow: they guard stable public outputs for
% tiny cases without storing binary fixtures, writing Results/, or changing
% solver tolerances.

fprintf('Running lightweight numerical regression snapshots...\n');

%% Rayleigh-Lamb A0/S0 snapshot
rlParams = rlDefaultParams();
rlParams.fmin = 10;
rlParams.fmax = 100;
rlParams.numFrequencyPoints = 10;
rlParams.frequencySpacing = "linspace";

rlOptions = rlDefaultOptions();
rlOptions.computeA0 = true;
rlOptions.computeS0 = true;

rlResult = rlComputeFundamentalLambModes(rlParams, rlOptions);
assertNumericClose(rlResult.modes.A0.frequency_Hz([1 10]), [10; 100], 1e-12, ...
    'Rayleigh-Lamb frequency grid snapshot changed.');
assertNumericClose(rlResult.modes.A0.phaseVelocity_mps([1 5 10]), ...
    [0.469222525760164; 0.806804188055844; 1.228781265925443], 1e-12, ...
    'Rayleigh-Lamb A0 Cp snapshot changed.');
assertNumericClose(rlResult.modes.S0.phaseVelocity_mps([1 5 10]), ...
    [24.300948977156519; 24.300906514429840; 24.300779224230400], 1e-12, ...
    'Rayleigh-Lamb S0 Cp snapshot changed.');

%% mRLFE elastic real-k snapshot
mrlfeParams = rlDefaultParams();
mrlfeParams.mu = 158e3;
mrlfeParams.rho = 1070;
mrlfeParams.nu = 0.4999;
mrlfeParams.thickness = 0.50e-3;
mrlfeParams.fmin = 500;
mrlfeParams.fmax = 4000;
mrlfeParams.numFrequencyPoints = 18;
mrlfeParams.frequencySpacing = "linspace";

requestedFrequency_Hz = linspace(500, 4000, 18).';
mrlfeA0Public = solveMRLFERegressionBranch(mrlfeParams, requestedFrequency_Hz, "A0Like");
mrlfeS0Public = solveMRLFERegressionBranch(mrlfeParams, requestedFrequency_Hz, "S0Like");
mrlfeA0 = mrlfeA0Public.debug.solverResult.branch;
mrlfeS0 = mrlfeS0Public.debug.solverResult.branch;

fastSolveFrequency_Hz = (500:50:4000).';
assertNumericClose(mrlfeA0Public.frequency_Hz, requestedFrequency_Hz, 1e-12, ...
    'mRLFE A0Like requested frequency grid changed.');
assertNumericClose(mrlfeS0Public.frequency_Hz, requestedFrequency_Hz, 1e-12, ...
    'mRLFE S0Like requested frequency grid changed.');
assertNumericClose(mrlfeA0Public.debug.solverResult.frequencySolve_Hz, ...
    fastSolveFrequency_Hz, 1e-12, 'mRLFE A0Like fast internal grid changed.');
assertNumericClose(mrlfeS0Public.debug.solverResult.frequencySolve_Hz, ...
    fastSolveFrequency_Hz, 1e-12, 'mRLFE S0Like fast internal grid changed.');
assert(mrlfeA0Public.execution.effectivePreset == "fast" && ...
    mrlfeS0Public.execution.effectivePreset == "fast", ...
    'mRLFE snapshot must use the public fast numerical preset.');
assert(mrlfeA0Public.termination.policy == "physicalTail" && ...
    mrlfeS0Public.termination.policy == "none", ...
    'mRLFE snapshot branch termination policies changed.');
assert(mrlfeA0Public.fallback.policy == "none" && ~mrlfeA0Public.fallback.applied && ...
    mrlfeS0Public.fallback.policy == "none" && ~mrlfeS0Public.fallback.applied, ...
    'mRLFE snapshot must not use fallback.');
assert(mrlfeA0Public.quality.accepted && mrlfeS0Public.quality.accepted, ...
    'mRLFE snapshot branches must retain accepted public quality.');

assert(nnz(mrlfeA0.valid) == 18 && numel(mrlfeA0.valid) == 18, ...
    'mRLFE A0Like valid mask snapshot changed.');
assert(nnz(mrlfeS0.valid) == 18 && numel(mrlfeS0.valid) == 18, ...
    'mRLFE S0Like valid mask snapshot changed.');
% Same-route repeats were bitwise identical on MATLAB R2024b. A 1e-9 m/s
% absolute tolerance permits platform-level solver arithmetic while guarding
% the continuously refined production snapshot.
mrlfeSnapshotTolerance_mps = 1e-9;
assertNumericClose(mrlfeA0.Cp([1 9 18]), ...
    [2.56401154288649; 5.38420881255238; 7.01174906257196], ...
    mrlfeSnapshotTolerance_mps, ...
    'mRLFE A0Like Cp snapshot changed.');
assertNumericClose(mrlfeS0.Cp([1 9 18]), ...
    [24.2848467589475; 24.0396887886552; 23.4815930582035], ...
    mrlfeSnapshotTolerance_mps, ...
    'mRLFE S0Like Cp snapshot changed.');

%% Acoustoelastic IOP/HGO atlasA0 snapshot
aeParams = struct();
aeParams.R = 7.8e-3;
aeParams.thickness = 550e-6;
aeParams.mu = 50e3;
aeParams.k1 = 25e3;
aeParams.k2 = 100;
aeParams.rho = 1060;
aeParams.rhoF = 1000;
aeParams.fluidBulkModulus = 2.2e9;
aeParams.frequency = logspace(log10(300), log10(15e3), 35);
aeParams.IOP = 15 * 133.322;

aeOptions = defaultAcoustoelasticIOPHGOOptions();
aeOptions.M54_variant = "corrected";
aeOptions.normalizeRows = false;
aeOptions.atlasNumYPoints = 300;
aeOptions.atlasTopNMinima = 12;
aeOptions.atlasBranchPolicy = "atlasA0";

aeResult = solveAcoustoelasticIOPHGOBranch(aeParams, aeOptions);
assert(nnz(aeResult.validMask) == 35 && numel(aeResult.validMask) == 35, ...
    'AE IOP/HGO validCp mask snapshot changed.');
assert(string(aeResult.quality.PolicyName) == "atlasA0", ...
    'AE IOP/HGO policy snapshot changed.');
assertNumericClose(aeResult.phaseVelocity_mps([1 18 35]), ...
    [2.455677508988490; 4.939957050001901; 6.728343229778789], 1e-12, ...
    'AE IOP/HGO atlasA0 Cp snapshot changed.');

fprintf('test_lightweight_numerical_regression passed. Solver snapshots are unchanged.\n');

function result = solveMRLFERegressionBranch(params, frequency_Hz, branchName)
options = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0);
request = mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
result = mrlfeSolve(request);
end

function assertNumericClose(actual, expected, tol, message)
assert(numel(actual) == numel(expected), message);
actual = actual(:);
expected = expected(:);
assert(all(isfinite(actual) == isfinite(expected)), message);
assert(max(abs(actual(:) - expected(:))) <= tol, message);
end
