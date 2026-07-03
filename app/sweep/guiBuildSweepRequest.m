function request = guiBuildSweepRequest(modelFamily, varargin)
%GUIBUILDSWEEPREQUEST Build a normalized GUI sweep request structure.
%
% The sweep GUI should pass this request to guiRunSweep instead of calling
% model-specific solver utilities directly. Model-specific adapters may extend
% the request contract, but common fields should stay stable across models.

request = struct();
request.modelFamily = string(modelFamily);

if mod(numel(varargin), 2) ~= 0
    error('guiBuildSweepRequest expects name-value arguments after modelFamily.');
end

for i = 1:2:numel(varargin)
    fieldName = char(varargin{i});
    request.(fieldName) = varargin{i + 1};
end

request = fillDefault(request, 'modelVariant', "");
request = fillDefault(request, 'modelLabel', "");
request = fillDefault(request, 'branchName', "");
request = fillDefault(request, 'sweepField', "");
request = fillDefault(request, 'sweepLabel', request.sweepField);
request = fillDefault(request, 'sweepValuesDisplay', []);
request = fillDefault(request, 'displayUnit', "");
request = fillDefault(request, 'displayScale', 1);
request = fillDefault(request, 'solverUnit', "");
request = fillDefault(request, 'baseParams', struct());
request = fillDefault(request, 'baseOptions', struct());
request = fillDefault(request, 'controls', struct());
request = fillDefault(request, 'outputMode', "workspace");
request = fillDefault(request, 'outputTaskName', "sweep");
request.controls = guiNormalizeControlExecutionProfile(request.controls, ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "SweepTool default");

if strlength(request.sweepField) == 0
    error('Sweep request requires sweepField.');
end
if isempty(request.sweepValuesDisplay)
    error('Sweep request requires at least one sweepValuesDisplay value.');
end

request.sweepValuesDisplay = request.sweepValuesDisplay(:).';
end

function s = fillDefault(s, fieldName, defaultValue)
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    s.(fieldName) = defaultValue;
end
end
