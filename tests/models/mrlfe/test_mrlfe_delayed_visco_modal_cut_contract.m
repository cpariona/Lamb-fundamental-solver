function test_mrlfe_delayed_visco_modal_cut_contract()
%TEST_MRLFE_DELAYED_VISCO_MODAL_CUT_CONTRACT Synthetic delayed-cut contract.

branch = struct();
branch.frequency = (1:10).';
branch.Cp = [nan; nan; 3; 3.1; 3.2; 3.3; 10; 10.1; 10.2; 10.3];
branch.k = branch.frequency ./ branch.Cp;
branch.residual = [nan; nan; 1e-5; 1e-5; 1e-5; 1e-5; 1e-5; 1e-5; 1e-5; 1e-5];
branch.candidateIndex = [nan; nan; 1; 1; 1; 1; 2; 2; 2; 2];
branch.validCp = isfinite(branch.Cp);
branch.valid = branch.validCp;

options = struct();
options.mrlfeDelayedCutMinValidRun = 3;
options.mrlfeDelayedCutStopAtFirstMissingAfterValidRun = true;
options.mrlfeDelayedCutPreviousCpMaxRelativeJump = 0.5;
options.mrlfeDelayedCutResidualTolerance = 1e-3;

[cutBranch, cutSummary] = mrlfeApplyDelayedViscoModalCut(branch, options);

assert(cutSummary.FirstStableStartIndex == 3);
assert(cutSummary.FirstCutIndex == 7);
assert(cutSummary.CutReason == "cp_jump_after_stable_valid_run");
assert(nnz(cutBranch.validCp) == 4);
assert(all(isfinite(cutBranch.Cp(3:6))));
assert(all(~cutBranch.validCp(7:end)));
assert(cutBranch.firstMissingModalMinimumIndex == 7);

fprintf('test_mrlfe_delayed_visco_modal_cut_contract passed.\n');
end
