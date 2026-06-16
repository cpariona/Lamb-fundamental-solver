function filePath = aeResolveResultFile(launchFolder, shortTaskName, shortFileName, legacyFolderName, legacyFileName)
%AERESOLVERESULTFILE Resolve a result file from short or legacy locations.
%
%   The preferred location is:
%
%       Results/ae_iop_hgo/<shortTaskName>/<shortFileName>
%
%   If it does not exist, this helper falls back to the legacy location:
%       Results/<legacyFolderName>/<legacyFileName>

if nargin < 1 || isempty(launchFolder)
    launchFolder = pwd;
end

preferred = fullfile(launchFolder, 'Results', 'ae_iop_hgo', char(string(shortTaskName)), char(string(shortFileName)));
if exist(preferred, 'file')
    filePath = preferred;
    return;
end

legacy = fullfile(launchFolder, 'Results', char(string(legacyFolderName)), char(string(legacyFileName)));
if exist(legacy, 'file')
    filePath = legacy;
    return;
end

error('Result file not found. Checked preferred path:\n%s\nand legacy path:\n%s', preferred, legacy);
end
