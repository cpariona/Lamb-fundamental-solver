function outputFolder = mrlfeOutputFolder(launchFolder, taskName)
%MRLFEOUTPUTFOLDER Return a standardized output folder for mRLFE tasks.
%
%   outputFolder = mrlfeOutputFolder(launchFolder, taskName) returns:
%
%       <launchFolder>/Results/mrlfe/<taskName>

if nargin < 1 || isempty(launchFolder)
    launchFolder = pwd;
end
if nargin < 2 || isempty(taskName)
    error('A short taskName is required, for example "mu_sweep".');
end

taskName = char(string(taskName));
rootFolder = fullfile(launchFolder, 'Results', 'mrlfe');
outputFolder = fullfile(rootFolder, taskName);

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
end
