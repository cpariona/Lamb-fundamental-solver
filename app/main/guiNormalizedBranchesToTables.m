function branchTables = guiNormalizedBranchesToTables(guiResult)
%GUINORMALIZEDBRANCHESTOTABLES Convert normalized GUI result branches to tables.
%
% branchTables = guiNormalizedBranchesToTables(guiResult) returns a struct of
% tables keyed by model and branch names. This prepares the GUI for normalized
% adapter-based export without changing existing raw-result plotting.

branchTables = struct();

if nargin < 1 || isempty(guiResult) || ~isstruct(guiResult)
    return;
end
if ~isfield(guiResult, 'branches') || isempty(guiResult.branches)
    return;
end

branches = guiResult.branches(:);
for i = 1:numel(branches)
    branch = branches(i);
    key = makeTableKey(branch, i);
    branchTables.(key) = guiNormalizedBranchToTable(branch);
end
end

function key = makeTableKey(branch, index)
modelName = "Model";
branchName = "Branch";
if isfield(branch, 'modelName') && strlength(string(branch.modelName)) > 0
    modelName = string(branch.modelName);
end
if isfield(branch, 'branchName') && strlength(string(branch.branchName)) > 0
    branchName = string(branch.branchName);
end
key = matlab.lang.makeValidName(sprintf('%s_%s_%02d', modelName, branchName, index));
end
