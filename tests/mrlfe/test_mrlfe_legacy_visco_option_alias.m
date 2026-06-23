clear; clc;
startup

%TEST_MRLFE_LEGACY_VISCO_OPTION_ALIAS Contract for legacy Han compute option.
%
% The maintained option is computeMRLFEViscoRealK. The old
% computeMRLFEHanViscoRealK flag is kept only as a compatibility alias and
% must still produce the physical mRLFEViscoRealK result.

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 3000;
params.numFrequencyPoints = 8;
params.frequencySpacing = "linspace";

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = false;
options.computeMRLFEViscoRealK = false;
options.computeMRLFEHanViscoRealK = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0.05;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

results = rlComputeFundamentalLambModes(params, options);

assert(isfield(results.models, 'mRLFEViscoRealK'), ...
    'Legacy computeMRLFEHanViscoRealK must populate the physical mRLFEViscoRealK result.');
assert(isfield(results.models, 'mRLFEHanViscoRealK'), ...
    'Legacy mRLFEHanViscoRealK result alias should remain available temporarily.');
assert(isfield(results.models, 'mRLFERealK'), ...
    'Unified mRLFERealK result must be populated for legacy visco requests.');
assert(isfield(results.models.mRLFEViscoRealK.branches, 'A0Like'), ...
    'Physical mRLFEViscoRealK result must include A0Like for this request.');

cpPhysical = results.models.mRLFEViscoRealK.branches.A0Like.Cp(:);
cpLegacy = results.models.mRLFEHanViscoRealK.branches.A0Like.Cp(:);
assert(isequal(size(cpPhysical), size(cpLegacy)), ...
    'Physical and legacy visco aliases must have the same branch size.');
assert(max(abs(cpPhysical - cpLegacy), [], 'omitnan') < 1e-12, ...
    'Physical and legacy visco aliases must refer to numerically identical data.');

fprintf('test_mrlfe_legacy_visco_option_alias passed. Legacy visco option maps to physical result.\n');
