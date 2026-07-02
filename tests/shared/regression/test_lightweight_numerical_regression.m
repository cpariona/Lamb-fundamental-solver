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
rlOptions.computeMRLFE = false;

rlResult = rlComputeFundamentalLambModes(rlParams, rlOptions);
assertNumericClose(rlResult.grid.frequency([1 10]), [10; 100], 1e-12, ...
    'Rayleigh-Lamb frequency grid snapshot changed.');
assertNumericClose(rlResult.modes.A0.Cp([1 5 10]), ...
    [0.469222525760164; 0.806804188055844; 1.228781265925443], 1e-12, ...
    'Rayleigh-Lamb A0 Cp snapshot changed.');
assertNumericClose(rlResult.modes.S0.Cp([1 5 10]), ...
    [24.300948977156519; 24.300906514429840; 24.300779224230400], 1e-12, ...
    'Rayleigh-Lamb S0 Cp snapshot changed.');

%% mRLFE elastic real-k snapshot
mrlfeParams = rlDefaultParams();
mrlfeParams.fmin = 500;
mrlfeParams.fmax = 4000;
mrlfeParams.numFrequencyPoints = 18;
mrlfeParams.frequencySpacing = "linspace";

mrlfeOptions = rlDefaultOptions("Fast");
mrlfeOptions.computeA0 = true;
mrlfeOptions.computeS0 = true;
mrlfeOptions.computeMRLFE = true;
mrlfeOptions.computeMRLFERealK = false;
mrlfeOptions.mrlfeParams = defaultMRLFEParams();

mrlfeResult = rlComputeFundamentalLambModes(mrlfeParams, mrlfeOptions);
mrlfeA0 = mrlfeResult.models.mRLFE.branches.A0Like;
mrlfeS0 = mrlfeResult.models.mRLFE.branches.S0Like;

assert(nnz(mrlfeA0.valid) == 18 && numel(mrlfeA0.valid) == 18, ...
    'mRLFE A0Like valid mask snapshot changed.');
assert(nnz(mrlfeS0.valid) == 18 && numel(mrlfeS0.valid) == 18, ...
    'mRLFE S0Like valid mask snapshot changed.');
assertNumericClose(mrlfeA0.Cp([1 9 18]), ...
    [2.560317111928414; 5.386393893277469; 7.011010224801658], 1e-12, ...
    'mRLFE A0Like Cp snapshot changed.');
assertNumericClose(mrlfeS0.Cp([1 9 18]), ...
    [24.284845559129135; 24.039695107953005; 23.481593219654226], 1e-12, ...
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
aeOptions.usePhysicalCpWindow = false;
aeOptions.atlasNumYPoints = 300;
aeOptions.atlasTopNMinima = 12;
aeOptions.atlasBranchPolicy = "atlasA0";

aeResult = solveAcoustoelasticIOPHGOAtlasBranch(aeParams, aeOptions);
assert(nnz(aeResult.validCp) == 35 && numel(aeResult.validCp) == 35, ...
    'AE IOP/HGO validCp mask snapshot changed.');
assert(string(aeResult.reliability.PolicyName) == "atlasA0", ...
    'AE IOP/HGO policy snapshot changed.');
assertNumericClose(aeResult.Cp([1 18 35]), ...
    [2.446884781169930; 4.926318840515296; 6.746363076443509], 1e-12, ...
    'AE IOP/HGO atlasA0 Cp snapshot changed.');

fprintf('test_lightweight_numerical_regression passed. Solver snapshots are unchanged.\n');

function assertNumericClose(actual, expected, tol, message)
assert(numel(actual) == numel(expected), message);
actual = actual(:);
expected = expected(:);
assert(all(isfinite(actual) == isfinite(expected)), message);
assert(max(abs(actual(:) - expected(:))) <= tol, message);
end
