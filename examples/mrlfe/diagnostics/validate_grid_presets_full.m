%% validate_grid_presets_full.m
% Run the complete mRLFE grid-preset validation matrix.
%
% This wrapper preserves validate_grid_presets.m as the quick diagnostic and
% executes the same maintained validation logic with quickMode=false. The
% temporary script is deleted after execution, including when the run fails.

clear; clc;
startup

sourceFile = which('validate_grid_presets');
if isempty(sourceFile)
    error('mrlfe:GridValidationScriptNotFound', ...
        'validate_grid_presets.m was not found on the active MATLAB path.');
end

sourceText = fileread(sourceFile);
quickToken = 'quickMode = true;';
fullToken = 'quickMode = false;';

if count(string(sourceText), quickToken) ~= 1
    error('mrlfe:GridValidationModeToken', ...
        'Expected exactly one quickMode=true assignment in validate_grid_presets.m.');
end

fullText = strrep(sourceText, quickToken, fullToken);
tempFile = fullfile(tempdir, 'validate_grid_presets_full_generated.m');
cleanupObj = onCleanup(@() deleteIfPresent(tempFile)); %#ok<NASGU>

fileId = fopen(tempFile, 'w');
if fileId < 0
    error('mrlfe:GridValidationTempFile', ...
        'Could not create the temporary full-validation script.');
end
fileCleanup = onCleanup(@() fcloseIfOpen(fileId));
fwrite(fileId, fullText, 'char');
fclose(fileId);
clear fileCleanup

fprintf('\nRunning complete mRLFE grid validation matrix.\n');
run(tempFile);

function deleteIfPresent(filePath)
if exist(filePath, 'file')
    delete(filePath);
end
end

function fcloseIfOpen(fileId)
if fileId > 0
    try
        fclose(fileId);
    catch
    end
end
end
