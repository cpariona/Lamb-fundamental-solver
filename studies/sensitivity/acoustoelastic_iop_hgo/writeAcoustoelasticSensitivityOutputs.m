function outputFolder = writeAcoustoelasticSensitivityOutputs(launchFolder, taskName, filePrefix, baseParams, options, sweepMetadata, sweepResult, summary)
%AEWRITESWEEPOUTPUTS Write standard AE IOP/HGO sweep outputs.
%
% sweepMetadata may be any structure describing the sweep campaign.

if nargin < 6 || isempty(sweepMetadata)
    sweepMetadata = struct();
end

outputFolder = resolveStudyOutputFolder(launchFolder, 'ae_iop_hgo', taskName);
filePrefix = string(filePrefix);

writetable(summary.conditionTable, fullfile(outputFolder, filePrefix + "_condition_summary.csv"));
writetable(summary.dispersionTable, fullfile(outputFolder, filePrefix + "_dispersion_table.csv"));
if isfield(summary, 'branchTable') && ~isempty(summary.branchTable)
    writetable(summary.branchTable, fullfile(outputFolder, filePrefix + "_selected_branch_table.csv"));
end

save(fullfile(outputFolder, filePrefix + "_workspace.mat"), ...
    'baseParams', 'options', 'sweepMetadata', 'sweepResult', 'summary', 'launchFolder', '-v7.3');
end
