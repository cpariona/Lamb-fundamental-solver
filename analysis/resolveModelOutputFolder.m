function outputFolder = resolveModelOutputFolder(launchFolder, modelFolderName, taskName)
%RESOLVEMODELOUTPUTFOLDER Return and create Results/<model>/<task> folders.

if nargin < 1 || isempty(launchFolder)
    launchFolder = pwd;
end
if nargin < 2 || isempty(modelFolderName)
    error('resolveModelOutputFolder:MissingModelFolderName', ...
        'A modelFolderName is required.');
end
if nargin < 3 || isempty(taskName)
    error('resolveModelOutputFolder:MissingTaskName', ...
        'A taskName is required.');
end

modelFolderName = char(string(modelFolderName));
taskName = char(string(taskName));
outputFolder = fullfile(launchFolder, 'Results', modelFolderName, taskName);

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
end
