function savedPath = guiSaveSolverResultExport(filePath, exportData)
%GUISAVESOLVERRESULTEXPORT Save one compact solver-GUI export payload.
if nargin < 1 || strlength(string(filePath)) == 0
    error('guiSaveSolverResultExport:InvalidPath', 'A destination MAT-file path is required.');
end
if nargin < 2 || ~isstruct(exportData) || ~isfield(exportData, 'curves') || ~isfield(exportData, 'parameters')
    error('guiSaveSolverResultExport:InvalidExportData', 'Expected an export payload produced by guiBuildSolverResultExport.');
end
savedPath = char(filePath);
[folder, name, extension] = fileparts(savedPath);
if strlength(string(extension)) == 0
    extension = '.mat';
elseif ~strcmpi(extension, '.mat')
    error('guiSaveSolverResultExport:InvalidExtension', 'Solver GUI results must be saved as a MAT-file.');
end
if isempty(folder), folder = pwd; end
savedPath = fullfile(folder, [name, extension]);
LambExport = exportData; %#ok<NASGU>
save(savedPath, 'LambExport');
end
