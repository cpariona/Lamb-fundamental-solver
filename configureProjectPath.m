function configureProjectPath(projectRoot)
%CONFIGUREPROJECTPATH Reset and add only maintained repository folders.

projectRoot = normalizePath(projectRoot);
excludedNames = ["archive", "figures", "outputs", "generated"];

currentEntries = string(strsplit(path, pathsep));
for i = 1:numel(currentEntries)
    folder = normalizePath(currentEntries(i));
    if strlength(folder) > 0 && isInsideProject(folder, projectRoot)
        rmpath(char(folder));
    end
end

addpath(char(projectRoot));
addpath(char(fullfile(projectRoot, "src")));
roots = [ ...
    fullfile(projectRoot, "app")];

for i = 1:numel(roots)
    addMaintainedTree(roots(i), excludedNames);
end
% Only six explicit launchers are discoverable; test bodies are opt-in.
addpath(char(fullfile(projectRoot, "tests", "runners")));
end

function addMaintainedTree(treeRoot, excludedNames)
if ~isfolder(treeRoot)
    return;
end
entries = string(strsplit(genpath(treeRoot), pathsep));
for i = 1:numel(entries)
    folder = normalizePath(entries(i));
    if strlength(folder) == 0 || containsExcludedPart(folder, excludedNames)
        continue;
    end
    addpath(char(folder));
end
end

function tf = containsExcludedPart(folder, excludedNames)
parts = split(normalizePath(folder), filesep);
tf = any(ismember(lower(parts), lower(excludedNames)));
end

function tf = isInsideProject(folder, projectRoot)
folder = normalizePath(folder);
projectRoot = normalizePath(projectRoot);
if ispc
    folder = lower(folder);
    projectRoot = lower(projectRoot);
end
tf = folder == projectRoot || startsWith(folder, projectRoot + filesep);
end

function value = normalizePath(value)
value = replace(string(value), ["/", "\\"], filesep);
while strlength(value) > 1 && endsWith(value, filesep)
    value = extractBefore(value, strlength(value));
end
end
