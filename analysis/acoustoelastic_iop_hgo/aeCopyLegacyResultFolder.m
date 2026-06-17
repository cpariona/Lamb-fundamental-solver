function outputFolder = aeCopyLegacyResultFolder(launchFolder, legacyFolderName, shortTaskName, legacyStem, shortStem)
%AECOPYLEGACYRESULTFOLDER Copy legacy AE result files to the short result tree.
%
%   This helper is conservative: it copies files from the legacy Results folder
%   into Results/ae_iop_hgo/<shortTaskName> and renames long file prefixes. It
%   does not delete the legacy folder.

if nargin < 1 || isempty(launchFolder)
    launchFolder = pwd;
end
if nargin < 5
    error('Expected launchFolder, legacyFolderName, shortTaskName, legacyStem, and shortStem.');
end

legacyFolder = fullfile(launchFolder, 'Results', char(string(legacyFolderName)));
outputFolder = aeOutputFolder(launchFolder, shortTaskName);

if ~exist(legacyFolder, 'dir')
    warning('Legacy result folder was not found: %s', legacyFolder);
    return;
end

items = dir(legacyFolder);
for i = 1:numel(items)
    if items(i).isdir
        continue;
    end

    sourceName = items(i).name;
    targetName = sourceName;
    targetName = strrep(targetName, char(string(legacyStem)), char(string(shortStem)));
    targetName = strrep(targetName, '_minima_table', '_minima');
    targetName = strrep(targetName, '_branch_table', '_branches');
    targetName = strrep(targetName, '_tracker_match_table', '_tracker_matches');
    targetName = strrep(targetName, '_condition_summary_table', '_condition_summary');
    targetName = strrep(targetName, '_summary_table', '_summary');

    sourcePath = fullfile(legacyFolder, sourceName);
    targetPath = fullfile(outputFolder, targetName);
    copyfile(sourcePath, targetPath);
end
end
