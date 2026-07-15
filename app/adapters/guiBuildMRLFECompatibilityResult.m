function rawResult = guiBuildMRLFECompatibilityResult(modelResults)
%GUIBUILDMRLFECOMPATIBILITYRESULT Adapt public mRLFE results for app legacy consumers.
%
% This is the only app-layer owner allowed to read the unstable raw internal
% result. Main GUI normalization and SweepTool summary extraction still need
% the historical rawFullResult/branch shape. Remove this adapter when those
% two consumers accept public result fields directly.

if iscell(modelResults)
    rawResult = adaptBranchCollection(modelResults);
else
    rawResult = modelResults.diagnostics.rawInternalResult.rawFullResult;
    rawResult.publicModelResult = modelResults;
end
end

function rawResult = adaptBranchCollection(modelResults)
rawResult = modelResults{1}.diagnostics.rawInternalResult.rawFullResult;
rawResult.models.mRLFERealK.branches = struct();
rawResult.models.mRLFE.branches = struct();
publicResults = struct();
for i = 1:numel(modelResults)
    result = modelResults{i};
    branchName = char(result.branch);
    branch = result.diagnostics.rawInternalResult.branch;
    rawResult.models.mRLFERealK.branches.(branchName) = branch;
    rawResult.models.mRLFE.branches.(branchName) = branch;
    publicResults.(branchName) = result;
end
rawResult.models.mRLFERealK.publicModelResults = publicResults;
rawResult.models.mRLFE.publicModelResults = publicResults;
end
