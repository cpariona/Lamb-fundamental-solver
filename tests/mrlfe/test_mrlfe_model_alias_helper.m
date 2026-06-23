clear; clc;
startup

%TEST_MRLFE_MODEL_ALIAS_HELPER Contract test for centralized mRLFE model aliases.
%
% mRLFEViscoRealK is the maintained physical name. mRLFEHanViscoRealK remains
% only as a legacy fallback for old cached raw results.

viscoNames = mrlfeModelCandidateNames("mRLFEViscoRealK");
assert(viscoNames(1) == "mRLFEViscoRealK", ...
    'mRLFEViscoRealK must be the primary viscoelastic model candidate.');
assert(any(viscoNames == "mRLFEHanViscoRealK"), ...
    'mRLFEHanViscoRealK should remain only as a legacy fallback candidate.');

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

fprintf('test_mrlfe_model_alias_helper passed. mRLFE legacy aliases are centralized.\n');
