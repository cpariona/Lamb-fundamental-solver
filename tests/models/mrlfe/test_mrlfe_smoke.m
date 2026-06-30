clear; clc;
startup

% Smoke test for the maintained mRLFE real-k elastic path.
% This verifies that the refactored mRLFE folders are on the path and that a
% small fundamental-mode computation returns finite A0-like/S0-like branches.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 4000;
params.numFrequencyPoints = 18;
params.frequencySpacing = "linspace";

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = true;
options.computeMRLFE = true;
options.computeMRLFERealK = false;

mrlfeParams = defaultMRLFEParams();
options.mrlfeParams = mrlfeParams;

results = rlComputeFundamentalLambModes(params, options);

assert(isstruct(results), 'Results must be a struct.');
assert(isfield(results, 'models'), 'Results must contain models.');
assert(isfield(results.models, 'mRLFE'), 'Results must contain models.mRLFE.');
assert(isfield(results.models.mRLFE, 'branches'), 'mRLFE result must contain branches.');
assert(isfield(results.models.mRLFE.branches, 'A0Like'), 'mRLFE branches must contain A0Like.');
assert(isfield(results.models.mRLFE.branches, 'S0Like'), 'mRLFE branches must contain S0Like.');

A0Like = results.models.mRLFE.branches.A0Like;
S0Like = results.models.mRLFE.branches.S0Like;

assert(numel(A0Like.frequency) == params.numFrequencyPoints, 'A0Like frequency length mismatch.');
assert(numel(S0Like.frequency) == params.numFrequencyPoints, 'S0Like frequency length mismatch.');
assert(any(A0Like.valid), 'A0Like branch must contain at least one valid point.');
assert(any(S0Like.valid), 'S0Like branch must contain at least one valid point.');
assert(any(isfinite(A0Like.Cp(A0Like.valid))), 'A0Like must contain finite valid Cp values.');
assert(any(isfinite(S0Like.Cp(S0Like.valid))), 'S0Like must contain finite valid Cp values.');
assert(all(A0Like.Cp(A0Like.valid) > 0), 'A0Like valid Cp values must be positive.');
assert(all(S0Like.Cp(S0Like.valid) > 0), 'S0Like valid Cp values must be positive.');

fprintf('test_mrlfe_smoke passed. A0Like valid: %d/%d. S0Like valid: %d/%d.\n', ...
    nnz(A0Like.valid), numel(A0Like.valid), nnz(S0Like.valid), numel(S0Like.valid));
