function test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy()
%TEST_ACOUSTOELASTIC_IOP_HGO_IDENTITYA0_DIAGNOSTIC_POLICY
% Verify that identityA0Diagnostic preserves official atlas output.

params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.IOP = 25 * 133.322;
params.mu = 25e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(100), log10(20e3), 40);

options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 500;
options.atlasTopNMinima = 18;

resultAtlas = solveAcoustoelasticIOPHGOBranch(params, options);

options.atlasBranchPolicy = "identityA0Diagnostic";
resultIdentity = solveAcoustoelasticIOPHGOBranch(params, options);

assert(isfield(resultIdentity, 'identityA0'), ...
    'identityA0Diagnostic must add result.identityA0.');
assert(isequaln(resultAtlas.Cp, resultIdentity.Cp), ...
    'identityA0Diagnostic must not modify official result.Cp.');
assert(isequal(resultAtlas.validCp, resultIdentity.validCp), ...
    'identityA0Diagnostic must not modify official result.validCp.');
assert(isfield(resultIdentity.identityA0, 'CpCandidate'), ...
    'identityA0Diagnostic must write CpCandidate.');
assert(isfield(resultIdentity.identityA0, 'validCandidate'), ...
    'identityA0Diagnostic must write validCandidate.');
assert(isfield(resultIdentity.identityA0, 'score'), ...
    'identityA0Diagnostic must include the branch-identity score.');
assert(numel(resultIdentity.identityA0.CpCandidate) == numel(resultIdentity.Cp), ...
    'identityA0 CpCandidate length must match result.Cp length.');
assert(numel(resultIdentity.identityA0.validCandidate) == numel(resultIdentity.validCp), ...
    'identityA0 validCandidate length must match result.validCp length.');
assert(isequal(resultIdentity.identityA0.frequency, resultIdentity.frequency), ...
    'identityA0 frequency must use the requested result frequency grid.');
assert(isequaln(resultIdentity.identityA0.CpCandidate(resultIdentity.validCp), ...
    resultIdentity.Cp(resultIdentity.validCp)), ...
    'identityA0 must preserve official Cp values at valid requested frequencies.');
assert(all(resultIdentity.identityA0.validCandidate(resultIdentity.validCp)), ...
    'identityA0 must preserve the official valid mask on the requested grid.');

fprintf('identityA0Diagnostic policy preserves official atlasA0 output and adds diagnostic candidate fields.\n');
end
