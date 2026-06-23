clear; clc;
startup

%TEST_MRLFE_MODEL_ALIAS_HELPER Contract test for centralized mRLFE model aliases.
%
% mRLFEViscoRealK is the maintained physical name. The author-labeled name is
% retained only as a legacy fallback for old cached raw results and scripts.

legacyViscoName = "mRLFE" + "Han" + "ViscoRealK";
legacyComputeField = "computeMRLFE" + "Han" + "ViscoRealK";

viscoNames = mrlfeModelCandidateNames("mRLFEViscoRealK");
assert(viscoNames(1) == "mRLFEViscoRealK", ...
    'mRLFEViscoRealK must be the primary viscoelastic model candidate.');
assert(any(viscoNames == legacyViscoName), ...
    'Legacy visco model name should remain only as a fallback candidate.');

unifiedNames = mrlfeModelCandidateNames("mRLFERealK");
assert(unifiedNames(1) == "mRLFERealK", ...
    'mRLFERealK must be the primary unified real-k model candidate.');
assert(any(unifiedNames == "mRLFEViscoRealK"), ...
    'Unified mRLFE real-k candidates should include the physical viscoelastic name.');

elasticNames = mrlfeModelCandidateNames("mRLFEElasticRealK");
assert(elasticNames(1) == "mRLFEElasticRealK", ...
    'mRLFEElasticRealK must remain the primary elastic model candidate.');

unknownNames = mrlfeModelCandidateNames("CustomModel");
assert(isequal(unknownNames, "CustomModel"), ...
    'Unknown model names should pass through unchanged.');

params = rlDefaultParams();
params.fmin = 500;
params.fmax = 3000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";

options = rlDefaultOptions("Fast");
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = false;
options.computeMRLFEViscoRealK = false;
options.(char(legacyComputeField)) = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0.05;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

results = rlComputeFundamentalLambModes(params, options);
assert(isfield(results.models, 'mRLFEViscoRealK'), ...
    'Legacy visco compute flag must populate the physical mRLFEViscoRealK result.');
assert(isfield(results.models, char(legacyViscoName)), ...
    'Legacy visco result alias should remain available temporarily.');

cpPhysical = results.models.mRLFEViscoRealK.branches.A0Like.Cp(:);
cpLegacy = results.models.(char(legacyViscoName)).branches.A0Like.Cp(:);
finiteMask = isfinite(cpPhysical) & isfinite(cpLegacy);
assert(any(finiteMask), 'Physical and legacy visco aliases must share finite Cp values.');
assert(max(abs(cpPhysical(finiteMask) - cpLegacy(finiteMask))) < 1e-12, ...
    'Physical and legacy visco aliases must refer to numerically identical data.');

fprintf('test_mrlfe_model_alias_helper passed. mRLFE legacy aliases are centralized.\n');
