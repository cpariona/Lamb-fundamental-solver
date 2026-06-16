clear; clc; close all;

%DIAGNOSE_IDENTITYA0_PLAUSIBILITY Short MATLAB-compatible entrypoint.
%
% MATLAB's run() resolves scripts by file stem and may execute them from the
% temporary script folder. This wrapper writes a short temporary script that
% first restores the caller launch folder, then executes the long diagnostic
% implementation.

launchFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
longScript = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_identityA0_physical_plausibility.m');
shortScript = fullfile(tempdir, 'identityA0_plaus_impl.m');

if ~exist(longScript, 'file')
    error('Expected diagnostic script not found: %s', longScript);
end

sourceText = fileread(longScript);
launchFolderEscaped = strrep(launchFolder, '''', '''''');
shortText = sprintf('cd(''%s'');\n%s', launchFolderEscaped, sourceText);
writeTextFile(shortScript, shortText);
run(shortScript);

function writeTextFile(fileName, text)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not create temporary diagnostic script: %s', fileName);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fwrite(fid, text, 'char');
end
