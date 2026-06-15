function plotData = guiGetNormalizedBranchPlotData(branch, xSelection)
%GUIGETNORMALIZEDBRANCHPLOTDATA Return plot-ready data from a normalized GUI branch.
%
% plotData = guiGetNormalizedBranchPlotData(branch, xSelection) extracts x, y,
% validity mask, labels, and display metadata from a normalized adapter branch.
% This helper prepares the GUI plotting layer to consume adapter-normalized
% results instead of raw model-specific fields.
%
% Supported xSelection values:
%   "frequency"        -> branch.frequency [Hz]
%   "wavenumber"       -> real(branch.wavenumber) [1/m]
%   "kThickness"       -> real(branch.kThickness) [-]
%   "angularFrequency" -> 2*pi*branch.frequency [rad/s]

if nargin < 2 || isempty(xSelection)
    xSelection = "frequency";
end
xSelection = string(xSelection);

if nargin < 1 || ~isstruct(branch)
    error('guiGetNormalizedBranchPlotData:InvalidInput', 'Expected a normalized GUI branch struct.');
end

frequency = getColumn(branch, 'frequency');
phaseVelocity = getColumn(branch, 'phaseVelocity');
wavenumber = getColumn(branch, 'wavenumber');
kThickness = getColumn(branch, 'kThickness');

switch xSelection
    case "frequency"
        x = frequency;
        xLabel = 'frequency [Hz]';
    case "angularFrequency"
        x = 2*pi*frequency;
        xLabel = 'angularFrequency [rad/s]';
    case "wavenumber"
        x = real(wavenumber);
        xLabel = 'wavenumber k [1/m]';
    case "kThickness"
        x = real(kThickness);
        xLabel = 'kThickness = k * thickness [-]';
    otherwise
        x = frequency;
        xLabel = 'frequency [Hz]';
end

y = phaseVelocity;
validMask = getValidMask(branch, x, y);

plotData = struct();
plotData.modelName = string(getScalarField(branch, 'modelName', ""));
plotData.branchName = string(getScalarField(branch, 'branchName', ""));
plotData.displayName = strtrim(plotData.modelName + " " + plotData.branchName);
plotData.xSelection = xSelection;
plotData.x = x(:);
plotData.y = y(:);
plotData.validMask = validMask(:);
plotData.xLabel = xLabel;
plotData.yLabel = 'Phase velocity Cp [m/s]';
plotData.metadata = getStructField(branch, 'metadata', struct());
plotData.diagnostics = getStructField(branch, 'diagnostics', struct());
end

function value = getColumn(s, fieldName)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName)(:);
else
    value = [];
end
end

function value = getScalarField(s, fieldName, defaultValue)
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = getStructField(s, fieldName, defaultValue)
if isfield(s, fieldName) && isstruct(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function validMask = getValidMask(branch, x, y)
validMask = isfinite(x(:)) & isfinite(y(:));
if isfield(branch, 'diagnostics') && isstruct(branch.diagnostics)
    if isfield(branch.diagnostics, 'validCp') && ~isempty(branch.diagnostics.validCp)
        validMask = validMask & logical(branch.diagnostics.validCp(:));
    elseif isfield(branch.diagnostics, 'valid') && ~isempty(branch.diagnostics.valid)
        validMask = validMask & logical(branch.diagnostics.valid(:));
    end
end
end
