clear; clc; close all;

%DIAGNOSE_MODAL_ATLAS Short AE IOP/HGO modal-atlas diagnostic entrypoint.
%
% Executes a temporary copy of the legacy implementation and ensures outputs are
% written to Results/ae_iop_hgo/modal_atlas. The wrapper accepts either the old
% legacy output-folder line or the already-migrated aeOutputFolder line so this
% entrypoint remains stable during the focused modal-atlas migration pass.

launchFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
legacyPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_modal_atlas.m');

sourceText = fileread(legacyPath);
oldLine = "outputFolder = fullfile(pwd, 'Results', 'acoustoelastic_iop_hgo_modal_atlas');";
newLine = "outputFolder = aeOutputFolder(pwd, 'modal_atlas');";
if contains(sourceText, oldLine)
    sourceText = strrep(sourceText, oldLine, newLine);
elseif ~contains(sourceText, newLine)
    error('Expected modal-atlas output-folder line not found.');
end

shortScript = fullfile(tempdir, 'ae_iop_hgo_modal_atlas_short_output.m');
writeTemporaryScript(shortScript, launchFolder, sourceText);
run(shortScript);

function writeTemporaryScript(fileName, launchFolder, sourceText)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not create temporary modal-atlas script: %s', fileName);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
launchFolderEscaped = strrep(launchFolder, '''', '''''');
fprintf(fid, 'cd(''%s'');\n%s', launchFolderEscaped, sourceText);
end
