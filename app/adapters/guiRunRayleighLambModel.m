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

params = guiMergeStructs(rlDefaultParams(), guiGetStructField(guiRequest, 'params', struct()));
options = guiMergeStructs(rlDefaultOptions(), guiGetStructField(guiRequest, 'options', struct()));

elapsedTimer = tic;
rawResult = rlComputeFundamentalLambModes(params, options);
elapsedSeconds = toc(elapsedTimer);

result = guiNormalizeRawResult(rawResult, mfilename);
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
end
