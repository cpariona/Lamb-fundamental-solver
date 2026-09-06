function test_acoustoelastic_iop_hgo_branch_policy_validation()
%TEST_ACOUSTOELASTIC_IOP_HGO_BRANCH_POLICY_VALIDATION Verify maintained branch-policy names.
%
% The maintained production policy is atlasA0. Diagnostic extension remains
% available as identityA0Diagnostic. Legacy branch-policy aliases must fail.

assert(aeNormalizeBranchPolicy("atlasA0") == "atlasA0", ...
    'Canonical atlasA0 policy must remain atlasA0.');
assert(aeNormalizeBranchPolicy("identityA0Diagnostic") == "identityA0Diagnostic", ...
    'identityA0Diagnostic policy must remain available as a diagnostic extension.');
assert(aeNormalizeBranchPolicy([]) == "atlasA0", ...
    'Empty policy must normalize to atlasA0.');

options = defaultAcoustoelasticIOPHGOOptions();
assert(options.atlasBranchPolicy == "atlasA0", ...
    'Default options must use canonical atlasA0 policy.');

diagnosticOptions = defaultAcoustoelasticIOPHGOOptions('atlasBranchPolicy', "identityA0Diagnostic");
assert(diagnosticOptions.atlasBranchPolicy == "identityA0Diagnostic", ...
    'Default options must preserve the identityA0Diagnostic diagnostic policy.');

assertUnsupportedPolicyFails("strictA0");
assertUnsupportedPolicyFails("smallGapInterpolation");
assertUnsupportedPolicyFails("raw_branch1");

fprintf('test_acoustoelastic_iop_hgo_branch_policy_validation passed. atlasA0 is the only production policy.\n');
end

function assertUnsupportedPolicyFails(policy)
policyText = char(string(policy));
try
    aeNormalizeBranchPolicy(policy);
catch ME
    assert(contains(ME.message, 'Unsupported acoustoelastic atlas branch policy'), ...
        'Unsupported policy %s failed with an unexpected error: %s', policyText, ME.message);
    return;
end
error('Unsupported policy %s did not fail.', policyText);
end
