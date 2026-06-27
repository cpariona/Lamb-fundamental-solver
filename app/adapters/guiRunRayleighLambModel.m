function result = guiRunRayleighLambModel(guiRequest)
%GUIRUNRAYLEIGHLAMBMODEL Run the Rayleigh-Lamb model for GUI workflows.
%
% result = guiRunRayleighLambModel(guiRequest) converts a GUI request struct
% into Rayleigh-Lamb params/options, calls the maintained rl* API, and returns
% normalized branch results for later plotting/export layers.
%
% Expected optional guiRequest fields:
%   params  - struct overlay for rlDefaultParams()
%   options - struct overlay for rlDefaultOptions()
%
% This adapter does not change numerical solver behavior.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = mergeStructs(rlDefaultParams(), getStructField(guiRequest, 'params', struct()));
options = mergeStructs(rlDefaultOptions(), getStructField(guiRequest, 'options', struct()));

elapsedTimer = tic;
rawResult = rlComputeFundamentalLambModes(params, options);
elapsedSeconds = toc(elapsedTimer);

result = guiNormalizeRawResult(rawResult, mfilename);
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
end

function value = getStructField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end

function base = mergeStructs(base, overlay)
if ~isstruct(overlay)
    return;
end
names = fieldnames(overlay);
for i = 1:numel(names)
    base.(names{i}) = overlay.(names{i});
end
end
