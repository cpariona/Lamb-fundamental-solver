function outputFolder = mrlfeWriteSweepOutputs(launchFolder, taskName, filePrefix, baseParams, options, sweepMetadata, sweepResults, sweepSummary)
%MRLFEWRITESWEEPOUTPUTS Write standard mRLFE sweep outputs.
%
% sweepMetadata may be any structure describing the sweep campaign.

if nargin < 6 || isempty(sweepMetadata)
    sweepMetadata = struct();
end

outputFolder = mrlfeOutputFolder(launchFolder, taskName);
filePrefix = string(filePrefix);

writetable(sweepSummary, fullfile(outputFolder, filePrefix + "_branch_summary.csv"));
save(fullfile(outputFolder, filePrefix + "_workspace.mat"), ...
    'baseParams', 'options', 'sweepMetadata', 'sweepResults', 'sweepSummary', 'launchFolder', '-v7.3');
end
