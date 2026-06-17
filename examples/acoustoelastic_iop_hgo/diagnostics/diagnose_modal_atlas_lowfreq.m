clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS_LOWFREQ Short AE IOP/HGO low-frequency modal-atlas diagnostic entrypoint.
%
% The legacy implementation computes and saves data, but also generates
% interactive log-scaled imagesc/colorbar figures. In some MATLAB versions that
% plotting path emits repeated benign graphics warnings. This wrapper executes a
% temporary copy of the legacy script with only the interactive plotting call
% disabled. Numerical calculations and saved tables/workspaces are unchanged.

launchFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
legacyPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m');

sourceText = fileread(legacyPath);
sourceText = strrep(sourceText, ...
    '        plotLowFrequencyAtlasCase(atlas, condition);', ...
    '        % plotLowFrequencyAtlasCase(atlas, condition); % disabled by short wrapper');

shortScript = fullfile(tempdir, 'ae_iop_hgo_lowfreq_atlas_noplot.m');
writeTemporaryScript(shortScript, launchFolder, sourceText);
run(shortScript);

aeCopyLegacyResultFolder(launchFolder, ...
    'acoustoelastic_iop_hgo_low_frequency_modal_atlas', ...
    'modal_atlas_lowfreq', ...
    'acoustoelastic_iop_hgo_low_frequency_modal_atlas', ...
    'modal_atlas_lowfreq');

function writeTemporaryScript(fileName, launchFolder, sourceText)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not create temporary no-plot script: %s', fileName);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
launchFolderEscaped = strrep(launchFolder, '''', '''''');
fprintf(fid, 'cd(''%s'');\n%s', launchFolderEscaped, sourceText);
end
