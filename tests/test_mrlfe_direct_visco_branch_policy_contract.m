function test_mrlfe_direct_visco_branch_policy_contract()
%TEST_MRLFE_DIRECT_VISCO_BRANCH_POLICY_CONTRACT Contract for A0/S0 policy adapter.

baseOptions = struct();
baseOptions.mrlfeRealKStopAtFirstMissingModalMinimum = true;
baseOptions.mrlfeViscoPreviousCpMaxRelativeJump = 0.18;
baseOptions.mrlfeResidualTolerance = 1e-3;

policy = struct();
policy.mrlfeViscoA0StopAtFirstMissingModalMinimum = false;
policy.mrlfeViscoA0PreviousCpMaxRelativeJump = inf;
policy.mrlfeViscoA0ResidualTolerance = 1e-2;
policy.mrlfeViscoA0ModalCpWindow = [0.25, 3.00];
policy.mrlfeViscoS0StopAtFirstMissingModalMinimum = true;
policy.mrlfeViscoS0PreviousCpMaxRelativeJump = 0.35;
policy.mrlfeViscoS0ResidualTolerance = 5e-3;
policy.mrlfeViscoS0ModalCpWindow = [0.65, 1.50];
policy.mrlfeViscoAtlasCpScanPoints = 321;
policy.mrlfeA0DPCandidates = 7;
policy.mrlfeA0DPRefineCandidates = false;

a0 = mrlfeMakeDirectViscoAtlasBranchOptions(baseOptions, "A0Like", policy);
s0 = mrlfeMakeDirectViscoAtlasBranchOptions(baseOptions, "S0Like", policy);

assert(~a0.mrlfeRealKStopAtFirstMissingModalMinimum);
assert(isinf(a0.mrlfeViscoPreviousCpMaxRelativeJump));
assert(a0.mrlfeResidualTolerance == 1e-2);
assert(isequal(a0.mrlfeViscoA0ModalCpWindow, [0.25, 3.00]));
assert(a0.mrlfeDirectViscoAtlasBranchPolicy == "A0");

assert(s0.mrlfeRealKStopAtFirstMissingModalMinimum);
assert(s0.mrlfeViscoPreviousCpMaxRelativeJump == 0.35);
assert(s0.mrlfeResidualTolerance == 5e-3);
assert(isequal(s0.mrlfeViscoS0ModalCpWindow, [0.65, 1.50]));
assert(s0.mrlfeDirectViscoAtlasBranchPolicy == "S0");

fprintf('test_mrlfe_direct_visco_branch_policy_contract passed.\n');
end
