function outputFolder = rlOutputFolder(launchFolder, taskName)
%RLOUTPUTFOLDER Return a standardized output folder for Rayleigh-Lamb tasks.
%
%   outputFolder = rlOutputFolder(launchFolder, taskName) returns:
%
%       <launchFolder>/Results/rayleigh_lamb/<taskName>

if nargin < 1 || isempty(launchFolder)
    launchFolder = pwd;
end
if nargin < 2 || isempty(taskName)
    error('A short taskName is required, for example "thickness_sweep".');
end

taskName = char(string(taskName));
rootFolder = fullfile(launchFolder, 'Results', 'rayleigh_lamb');
outputFolder = fullfile(rootFolder, taskName);

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
end
