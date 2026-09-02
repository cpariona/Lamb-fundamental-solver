clear; clc;
if isempty(which('mrlfeSolve'))
    startup
end

fprintf('\nRunning mRLFE public contract tests...\n');
fprintf('------------------------------------\n');

assertFunctionsOnPath({ ...
    'mrlfeSolve', ...
    'mrlfeDefaultParameters', ...
    'mrlfeDefaultOptions'}, ...
    'mRLFE public API');

assertFunctionsOnPath({ ...
    'mrlfeValidateRequest', ...
    'mrlfeBuildPublicSolveRequest', ...
    'mrlfeResolveConfiguration', ...
    'mrlfeGetNumericalPreset', ...
    'mrlfeBuildResult', ...
    'mrlfeEvaluateBranchQuality'}, ...
    'mRLFE maintained internal contract function');

fprintf('\n[mRLFE public group 1/3] API contracts\n');
run_mrlfe_public_api_contract_tests;
test_mrlfe_public_request_builder;

fprintf('\n[mRLFE public group 2/3] result schema\n');
run_mrlfe_public_result_contract_tests;

fprintf('\n[mRLFE public group 3/3] route characterization\n');
test_mrlfe_public_contract_characterization;

fprintf('\nmRLFE public contract tests passed.\n');

function assertFunctionsOnPath(functionNames, label)
for i = 1:numel(functionNames)
    functionName = functionNames{i};
    assert(~isempty(which(functionName)), ...
        'Missing %s on MATLAB path: %s.', label, functionName);
end
end
