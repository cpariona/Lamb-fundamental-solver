function savedPath = guiSaveMainResultExport(filePath, exportData)
%GUISAVEMAINRESULTEXPORT Save one compact LambFundamental_GUI export payload.

if nargin < 1 || strlength(string(filePath)) == 0
    error('guiSaveMainResultExport:InvalidPath', 'A destination MAT-file path is required.');
end
if nargin < 2 || ~isstruct(exportData) || ~isfield(exportData, 'curves') || ~isfield(exportData, 'parameters')
    error('guiSaveMainResultExport:InvalidExportData', ...
        'Expected an export payload produced by guiBuildMainResultExport.');
end

savedPath = char(filePath);
[folder, name, extension] = fileparts(savedPath);
if strlength(string(extension)) == 0
    extension = '.mat';
elseif ~strcmpi(extension, '.mat')
    error('guiSaveMainResultExport:InvalidExtension', 'Main GUI results must be saved as a MAT-file.');
end
if isempty(folder)
    folder = pwd;
end
savedPath = fullfile(folder, [name, extension]);

LambExport = exportData; %#ok<NASGU>
save(savedPath, 'LambExport');
end