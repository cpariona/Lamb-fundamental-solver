clear; clc;
startup

%TEST_ACOUSTOELASTIC_IOP_HGO_BRANCH_POLICY_ALIASES Verify canonical and legacy policy names.
%
% The maintained policy name is atlasA0. The previous name strictA0 remains a
% legacy alias so existing workspaces and scripts do not break.

assert(aeNormalizeBranchPolicy("atlasA0") == "atlasA0", ...
    'Canonical atlasA0 policy must remain atlasA0.');
assert(aeNormalizeBranchPolicy("strictA0") == "atlasA0", ...
    'Legacy strictA0 policy must normalize to atlasA0.');
assert(aeNormalizeBranchPolicy([]) == "atlasA0", ...
    'Empty policy must normalize to atlasA0.');

options = defaultAcoustoelasticIOPHGOOptions();
assert(options.atlasBranchPolicy == "atlasA0", ...
    'Default options must use canonical atlasA0 policy.');

legacyOptions = defaultAcoustoelasticIOPHGOOptions('atlasBranchPolicy', "strictA0");
assert(legacyOptions.atlasBranchPolicy == "atlasA0", ...
    'Default options must normalize legacy strictA0 to atlasA0.');

diagnosticPolicy = aeNormalizeBranchPolicy("smallGapInterpolation");
assert(diagnosticPolicy == "smallGapInterpolation", ...
    'Diagnostic policy names must pass through unchanged.');

fprintf('test_acoustoelastic_iop_hgo_branch_policy_aliases passed.\n');
