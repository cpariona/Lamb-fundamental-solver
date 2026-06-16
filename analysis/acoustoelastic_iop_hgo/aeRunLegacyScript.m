function aeRunLegacyScript(scriptPath)
%AERUNLEGACYSCRIPT Run a legacy MATLAB script with a long filename safely.
%
%   aeRunLegacyScript(scriptPath) copies the target script into a short
%   temporary filename, prepends cd(pwd_at_call_time), and runs the copy.
%
%   This avoids MATLAB namelengthmax failures for descriptive legacy scripts
%   while preserving the caller launch folder used by Results paths.

if nargin < 1 || isempty(scriptPath)
    error('A script path is required.');
end

scriptPath = char(string(scriptPath));
if ~exist(scriptPath, 'file')
    error('Legacy script not found: %s', scriptPath);
end

launchFolder = pwd;
sourceText = fileread(scriptPath);
[~, stem] = fileparts(scriptPath);
shortStem = matlab.lang.makeValidName(stem);
if strlength(string(shortStem)) > 32
    shortStem = char(extractBefore(string(shortStem), 33));
end
shortScript = fullfile(tempdir, [shortStem, '_legacy.m']);

launchFolderEscaped = strrep(launchFolder, '''', '''''');
shortText = sprintf('cd(''%s'');\n%s', launchFolderEscaped, sourceText);
writeTextFile(shortScript, shortText);
run(shortScript);
end

function writeTextFile(fileName, text)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not create temporary legacy script: %s', fileName);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fwrite(fid, text, 'char');
end
