function outputFolder = rlWriteSensitivityOutputs(launchFolder, taskName, filePrefix, baseParams, options, sweepMetadata, sweepResults, sweepSummary)
%RLWRITESENSITIVITYOUTPUTS Write standard Rayleigh-Lamb sensitivity outputs.
%
% sweepMetadata may be any structure describing the sensitivity campaign.

if nargin < 6 || isempty(sweepMetadata)
    sweepMetadata = struct();
end

outputFolder = resolveStudyOutputFolder(launchFolder, 'rayleigh_lamb', taskName);
filePrefix = string(filePrefix);

writetable(sweepSummary, fullfile(outputFolder, filePrefix + "_branch_summary.csv"));
save(fullfile(outputFolder, filePrefix + "_workspace.mat"), ...
    'baseParams', 'options', 'sweepMetadata', 'sweepResults', 'sweepSummary', 'launchFolder', '-v7.3');
end
