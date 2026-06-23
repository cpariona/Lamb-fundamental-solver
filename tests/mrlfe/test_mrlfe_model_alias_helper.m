clear; clc;
startup

%TEST_MRLFE_MODEL_ALIAS_HELPER Contract test for canonical mRLFE model candidates.
%
% The helper should expose only maintained physical model names.

viscoNames = mrlfeModelCandidateNames("mRLFEViscoRealK");
assert(isequal(viscoNames, "mRLFEViscoRealK"), ...
    'mRLFEViscoRealK must be the only candidate for the viscoelastic model.');

unifiedNames = mrlfeModelCandidateNames("mRLFERealK");
assert(unifiedNames(1) == "mRLFERealK", ...
    'mRLFERealK must be the primary unified real-k model candidate.');
assert(any(unifiedNames == "mRLFEViscoRealK"), ...
    'Unified mRLFE real-k candidates should include the physical viscoelastic name.');
assert(any(unifiedNames == "mRLFEElasticRealK"), ...
    'Unified mRLFE real-k candidates should include the physical elastic name.');

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
options.computeMRLFEViscoRealK = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = 0.05;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

results = rlComputeFundamentalLambModes(params, options);
assert(isfield(results.models, 'mRLFEViscoRealK'), ...
    'Visco compute flag must populate the physical mRLFEViscoRealK result.');
assert(isfield(results.models, 'mRLFERealK'), ...
    'Visco compute flag must populate the unified mRLFERealK result.');
forbiddenModelName = char([109 82 76 70 69 72 97 110 86 105 115 99 111 82 101 97 108 75]);
assert(~any(strcmp(fieldnames(results.models), forbiddenModelName)), ...
    'Author-labeled mRLFE result aliases must not be produced.');

fprintf('test_mrlfe_model_alias_helper passed. mRLFE model candidates are canonical.\n');
