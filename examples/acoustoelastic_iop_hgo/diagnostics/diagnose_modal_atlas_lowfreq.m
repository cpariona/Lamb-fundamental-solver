clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS_LOWFREQ Short AE IOP/HGO low-frequency modal-atlas diagnostic entrypoint.
%
% Executes a temporary copy of the legacy implementation with interactive
% plotting disabled and output redirected to Results/ae_iop_hgo/modal_atlas_lowfreq.
% Numerical calculations and saved tables/workspaces are unchanged.

launchFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
legacyPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m');

sourceText = fileread(legacyPath);
plotLine = '        plotLowFrequencyAtlasCase(atlas, condition);';
if ~contains(sourceText, plotLine)
    error('Expected low-frequency modal-atlas plotting line not found.');
end
sourceText = strrep(sourceText, plotLine, ...
    '        if makeInteractivePlots, plotLowFrequencyAtlasCase(atlas, condition); end');

oldLine = "outputFolder = fullfile(pwd, 'Results', 'acoustoelastic_iop_hgo_low_frequency_modal_atlas');";
newLine = "outputFolder = aeOutputFolder(pwd, 'modal_atlas_lowfreq');";
if ~contains(sourceText, oldLine)
    error('Expected low-frequency modal-atlas output-folder line not found.');
end
sourceText = strrep(sourceText, oldLine, newLine);

shortScript = fullfile(tempdir, 'ae_iop_hgo_lowfreq_atlas_short_output.m');
writeTemporaryScript(shortScript, launchFolder, sourceText);
run(shortScript);

function writeTemporaryScript(fileName, launchFolder, sourceText)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not create temporary low-frequency modal-atlas script: %s', fileName);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
launchFolderEscaped = strrep(launchFolder, '''', '''''');
fprintf(fid, 'cd(''%s'');\nmakeInteractivePlots = false;\n%s', launchFolderEscaped, sourceText);
end
