function outputFolder = aeOutputFolder(launchFolder, taskName)
%AEOUTPUTFOLDER Return a short standardized output folder for AE IOP/HGO tasks.
%
%   outputFolder = aeOutputFolder(launchFolder, taskName) returns:
%
%       <launchFolder>/Results/ae_iop_hgo/<taskName>
%
%   This keeps paths shorter than repeating the full model name in every result
%   folder. The folder is created if needed.

if nargin < 1 || isempty(launchFolder)
    launchFolder = pwd;
end
if nargin < 2 || isempty(taskName)
    error('A short taskName is required, for example "idA0_plausibility".');
end

taskName = char(string(taskName));
outputFolder = resolveModelOutputFolder(launchFolder, 'ae_iop_hgo', taskName);
end
