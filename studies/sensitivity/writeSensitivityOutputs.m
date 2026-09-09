function outputFolder = writeSensitivityOutputs(launchFolder, familyName, taskName, filePrefix, baseParams, options, sweepMetadata, sweepResults, sweepSummary)
%WRITESENSITIVITYOUTPUTS Write the standard sensitivity-study artifacts.

if nargin < 7 || isempty(sweepMetadata)
    sweepMetadata = struct();
end

outputFolder = resolveStudyOutputFolder(launchFolder, familyName, taskName);
filePrefix = string(filePrefix);

writetable(sweepSummary, fullfile(outputFolder, filePrefix + "_branch_summary.csv"));
save(fullfile(outputFolder, filePrefix + "_workspace.mat"), ...
    'baseParams', 'options', 'sweepMetadata', 'sweepResults', 'sweepSummary', 'launchFolder', '-v7.3');
end
