function test_mrlfe_atlas_policy_matrix_contract()
%TEST_MRLFE_ATLAS_POLICY_MATRIX_CONTRACT Lightweight contract for policy matrix helper.

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 1.2e3;
params.numFrequencyPoints = 12;
params.frequencySpacing = "linspace";

policyOptions = struct();
policyOptions.robustness = "Fast";
policyOptions.branchNames = ["A0Like", "S0Like"];
policyOptions.etaSValues = [0, 0.02];
policyOptions.mrlfeParams = defaultMRLFEParams();
policyOptions.mrlfeParams.fluidDensity = 1000;
policyOptions.mrlfeParams.fluidSoundSpeed = 1500;
policyOptions.mrlfeModalAtlasCpScanPoints = 120;
policyOptions.mrlfeModalAtlasTopNMinima = 6;
policyOptions.mrlfeModalAtlasRefineMinima = false;
policyOptions.mrlfeModalAtlasMinBranchPoints = 4;
policyOptions.mrlfeViscoAtlasCpScanPoints = 120;
policyOptions.mrlfeA0DPCandidates = 6;
policyOptions.mrlfeA0DPRefineCandidates = false;
policyOptions.mrlfeRealKStopAtFirstMissingModalMinimum = true;

[summaryRows, caseResults] = compareMRLFEAtlasPolicy(params, policyOptions);

assert(istable(summaryRows));
assert(height(summaryRows) == 6);
assert(numel(caseResults) == height(summaryRows));
assert(all(ismember(["A0Like", "S0Like"], unique(summaryRows.BranchName))));
assert(any(summaryRows.CandidateSolver == "modalAtlasContinuous"));
assert(any(summaryRows.CandidateSolver == "modalAtlasCut"));
assert(any(summaryRows.CandidateSolver == "directViscoAtlas"));
assert(all(summaryRows.ReferenceValidPoints >= 0));
assert(all(summaryRows.CandidateValidPoints >= 0));
assert(all(summaryRows.OverlapPoints >= 0));
assert(all(isfinite(summaryRows.ReferenceTime_s)));
assert(all(isfinite(summaryRows.CandidateTime_s)));

fprintf('test_mrlfe_atlas_policy_matrix_contract passed.\n');
end
