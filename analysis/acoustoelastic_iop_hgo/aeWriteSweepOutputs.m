function outputFolder = aeWriteSweepOutputs(launchFolder, taskName, filePrefix, baseParams, options, sweepValuesDisplay, sweepValuesSI, sweepResult, summary)
%AEWRITESWEEPOUTPUTS Write standard AE IOP/HGO sweep outputs.

outputFolder = aeOutputFolder(launchFolder, taskName);

writetable(summary.conditionTable, fullfile(outputFolder, filePrefix + "_condition_summary.csv"));
writetable(summary.dispersionTable, fullfile(outputFolder, filePrefix + "_dispersion_table.csv"));
if isfield(summary, 'branchTable') && ~isempty(summary.branchTable)
    writetable(summary.branchTable, fullfile(outputFolder, filePrefix + "_selected_branch_table.csv"));
end

save(fullfile(outputFolder, filePrefix + "_workspace.mat"), ...
    'baseParams', 'options', 'sweepValuesDisplay', 'sweepValuesSI', 'sweepResult', 'summary', 'launchFolder', '-v7.3');
end
