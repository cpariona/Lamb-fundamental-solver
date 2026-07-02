function startup()
% Add active Lamb Fundamental Solver folders to the MATLAB path.
%
% Only maintained example folders are added to the default path.
% The models tree contains the primary Rayleigh-Lamb rl* implementation.

projectRoot = fileparts(mfilename('fullpath'));

addpath(projectRoot);
addProjectTree(fullfile(projectRoot, 'app'), {});
addProjectTree(fullfile(projectRoot, 'models'), {});
addProjectTree(fullfile(projectRoot, 'analysis'), {});
addProjectTree(fullfile(projectRoot, 'examples', 'rayleigh_lamb'), {'archive', 'figures'});
addProjectTree(fullfile(projectRoot, 'examples', 'acoustoelastic_iop_hgo'), {'archive', 'figures'});
addProjectTree(fullfile(projectRoot, 'examples', 'mrlfe'), {'archive', 'figures'});
addProjectTree(fullfile(projectRoot, 'tests'), {});

fprintf('Lamb Fundamental Solver active paths added from:\n%s\n', projectRoot);
end

function addProjectTree(treeRoot, excludedFolderNames)
if ~exist(treeRoot, 'dir')
    return;
end

pathEntries = strsplit(genpath(treeRoot), pathsep);
for i = 1:numel(pathEntries)
    folder = pathEntries{i};
    if isempty(folder) || containsExcludedFolder(folder, excludedFolderNames)
        continue;
    end
    addpath(folder);
end
end

function tf = containsExcludedFolder(folder, excludedFolderNames)
if isempty(excludedFolderNames)
    tf = false;
    return;
end

parts = regexp(folder, '[\\/]', 'split');
tf = any(ismember(lower(parts), lower(excludedFolderNames)));
end
