function outputFolder = rlWriteSweepOutputs(launchFolder, taskName, filePrefix, baseParams, options, sweepMetadata, sweepResults, a0Summary, s0Summary)
%RLWRITESWEEPOUTPUTS Write standard Rayleigh-Lamb sweep outputs.
%
% sweepMetadata may be any structure describing the sweep campaign.

if nargin < 6 || isempty(sweepMetadata)
    sweepMetadata = struct();
end

outputFolder = rlOutputFolder(launchFolder, taskName);
filePrefix = string(filePrefix);

writetable(a0Summary, fullfile(outputFolder, filePrefix + "_A0_branch_summary.csv"));
writetable(s0Summary, fullfile(outputFolder, filePrefix + "_S0_branch_summary.csv"));
save(fullfile(outputFolder, filePrefix + "_workspace.mat"), ...
    'baseParams', 'options', 'sweepMetadata', 'sweepResults', 'a0Summary', 's0Summary', 'launchFolder', '-v7.3');
end
