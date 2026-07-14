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

fprintf('\n[mRLFE public 1/4] defaults contract\n');
test_mrlfe_public_contract_defaults;

fprintf('\n[mRLFE public 2/4] validation contract\n');
test_mrlfe_public_contract_validation;

fprintf('\n[mRLFE public 3/4] result schema contract\n');
test_mrlfe_public_contract_result_schema;

fprintf('\n[mRLFE public 4/4] route characterization\n');
test_mrlfe_public_contract_characterization;

fprintf('\nmRLFE public contract tests passed.\n');

function assertFunctionsOnPath(functionNames, label)
for i = 1:numel(functionNames)
    functionName = functionNames{i};
    assert(~isempty(which(functionName)), ...
        'Missing %s on MATLAB path: %s.', label, functionName);
end
end
