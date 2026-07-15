clear; clc;
startup

fprintf('\nRunning mRLFE public contract tests...\n');
fprintf('------------------------------------\n');

assertFunctionsOnPath({ ...
    'mrlfeSolve', ...
    'mrlfeDefaultParameters', ...
    'mrlfeDefaultOptions', ...
    'mrlfeValidateRequest', ...
    'mrlfeResolveConfiguration', ...
    'mrlfeGetNumericalPreset', ...
    'mrlfeBuildResult', ...
    'mrlfeEvaluateBranchQuality'}, ...
    'mRLFE public contract API/test');

fprintf('\n[mRLFE public group 1/3] API contracts\n');
run_mrlfe_public_api_contract_tests;

fprintf('\n[mRLFE public group 2/3] result schema\n');
run_mrlfe_public_result_contract_tests;

fprintf('\n[mRLFE public group 3/3] route characterization\n');
run_mrlfe_public_characterization_tests;

fprintf('\nmRLFE public contract tests passed.\n');

function assertFunctionsOnPath(functionNames, label)
for i = 1:numel(functionNames)
    functionName = functionNames{i};
    assert(~isempty(which(functionName)), ...
        'Missing %s on MATLAB path: %s.', label, functionName);
end
end
