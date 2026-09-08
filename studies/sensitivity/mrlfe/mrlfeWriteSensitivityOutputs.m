function outputFolder = mrlfeWriteSensitivityOutputs(launchFolder, taskName, filePrefix, baseParams, options, sweepMetadata, sweepResults, sweepSummary)
%MRLFEWRITESENSITIVITYOUTPUTS Write standard mRLFE sensitivity outputs.
%
% sweepMetadata may be any structure describing the sensitivity campaign.

if nargin < 6 || isempty(sweepMetadata)
    sweepMetadata = struct();
end

outputFolder = resolveStudyOutputFolder(launchFolder, 'mrlfe', taskName);
filePrefix = string(filePrefix);

writetable(sweepSummary, fullfile(outputFolder, filePrefix + "_branch_summary.csv"));
save(fullfile(outputFolder, filePrefix + "_workspace.mat"), ...
    'baseParams', 'options', 'sweepMetadata', 'sweepResults', 'sweepSummary', 'launchFolder', '-v7.3');
end
