function configureTestPath()
%CONFIGURETESTPATH Explicit opt-in setup for validation, never examples.
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
configureProjectPath(projectRoot);
addpath(fullfile(projectRoot, 'studies'));
configureStudyPath(projectRoot);
entries = string(strsplit(genpath(fullfile(projectRoot, 'tests')), pathsep));
for entry = entries
    parts = split(replace(entry, "\", "/"), "/");
    if entry ~= "" && ~any(ismember(lower(parts), ...
            ["archive", "figures", "results", "outputs", "generated"]))
        addpath(char(entry));
    end
end
end
