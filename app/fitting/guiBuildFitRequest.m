function request = guiBuildFitRequest(modelFamily, varargin)
%GUIBUILDFITREQUEST Build a normalized app-level fitting request.
%
% The GUI should pass this request to guiRunFit rather than calling
% model-specific fitting helpers directly.

request = struct();
request.modelFamily = string(modelFamily);

if mod(numel(varargin), 2) ~= 0
    error('guiBuildFitRequest expects name-value arguments after modelFamily.');
end

for i = 1:2:numel(varargin)
    fieldName = char(varargin{i});
    request.(fieldName) = varargin{i + 1};
end

request = fillDefault(request, 'branchName', "");
request = fillDefault(request, 'mode', "basic");
request = fillDefault(request, 'experimental', struct());
request = fillDefault(request, 'fixedParams', struct());
request = fillDefault(request, 'freeParams', strings(0, 1));
request = fillDefault(request, 'initialGuess', struct());
request = fillDefault(request, 'bounds', struct());
request = fillDefault(request, 'controls', struct());
request = fillDefault(request, 'fitOptions', struct());
request = fillDefault(request, 'outputMode', "workspace");
request.controls = guiNormalizeControlExecutionProfile(request.controls, ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "FitTool default");

if ~isfield(request.experimental, 'frequency_Hz') || ~isfield(request.experimental, 'Cp_mps')
    error('Fit request requires experimental.frequency_Hz and experimental.Cp_mps.');
end

request.experimental = normalizeExperimentalDispersionData(request.experimental);
request.freeParams = string(request.freeParams(:));
if isempty(request.freeParams)
    error('Fit request requires at least one free parameter.');
end

if request.experimental.numValidPoints == 1 && numel(request.freeParams) > 1
    error('A single frequency-speed pair can fit only one free parameter.');
end
end

function s = fillDefault(s, fieldName, defaultValue)
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    s.(fieldName) = defaultValue;
end
end
