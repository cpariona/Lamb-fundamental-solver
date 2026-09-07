function configureStudyPath(projectRoot)
%CONFIGURESTUDYPATH Opt in to study code without changing normal startup.

if nargin < 1 || strlength(string(projectRoot)) == 0
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

projectRoot = string(projectRoot);
configureProjectPath(projectRoot);

studyRoot = fullfile(projectRoot, "studies");
entries = string(strsplit(genpath(studyRoot), pathsep));
excludedNames = ["figures", "results", "outputs", "generated"];
for i = 1:numel(entries)
    folder = entries(i);
    if folder == ""
        continue;
    end
    parts = split(replace(folder, "\", "/"), "/");
    if any(ismember(lower(parts), excludedNames))
        continue;
    end
    addpath(char(folder));
end
end
