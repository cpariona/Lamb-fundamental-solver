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

options = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 500;
options.atlasTopNMinima = 18;

resultAtlas = lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(params, options);

options.atlasBranchPolicy = "identityA0Diagnostic";
resultIdentity = lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(params, options);

assert(isfield(resultIdentity.diagnostics, 'identityA0'), ...
    'identityA0Diagnostic must add diagnostics.identityA0.');
identity = resultIdentity.diagnostics.identityA0;
assert(isequaln(resultAtlas.phaseVelocity_mps, resultIdentity.phaseVelocity_mps), ...
    'identityA0Diagnostic must not modify official phase velocity.');
assert(isequal(resultAtlas.validMask, resultIdentity.validMask), ...
    'identityA0Diagnostic must not modify the official valid mask.');
assert(isfield(identity, 'CpCandidate'), ...
    'identityA0Diagnostic must write CpCandidate.');
assert(isfield(identity, 'validCandidate'), ...
    'identityA0Diagnostic must write validCandidate.');
assert(isfield(identity, 'score'), ...
    'identityA0Diagnostic must include the branch-identity score.');
assert(numel(identity.CpCandidate) == numel(resultIdentity.phaseVelocity_mps), ...
    'identityA0 CpCandidate length must match result.Cp length.');
assert(numel(identity.validCandidate) == numel(resultIdentity.validMask), ...
    'identityA0 validCandidate length must match result.validCp length.');
assert(isequal(identity.frequency, resultIdentity.frequency_Hz), ...
    'identityA0 frequency must use the requested result frequency grid.');
assert(isequaln(identity.CpCandidate(resultIdentity.validMask), ...
    resultIdentity.phaseVelocity_mps(resultIdentity.validMask)), ...
    'identityA0 must preserve official Cp values at valid requested frequencies.');
assert(all(identity.validCandidate(resultIdentity.validMask)), ...
    'identityA0 must preserve the official valid mask on the requested grid.');

fprintf('identityA0Diagnostic policy preserves official atlasA0 output and adds diagnostic candidate fields.\n');
end
