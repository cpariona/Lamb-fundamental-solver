function result = guiRunMRLFEModel(guiRequest)
%GUIRUNMRLFEMODEL Run maintained mRLFE workflows for GUI usage.
%
% result = guiRunMRLFEModel(guiRequest) prepares Rayleigh-Lamb seed modes,
% calls the maintained mRLFE solver surface through the existing rl* workflow,
% and returns normalized mRLFE branch results.
%
% Expected optional guiRequest fields:
%   params           - struct overlay for rlDefaultParams()
%   options          - struct overlay for rlDefaultOptions()
%   mrlfeParams      - struct overlay stored in options.mrlfeParams
%   computeElastic   - logical, default true
%   computeHan       - logical, default false
%   computeHanVisco  - logical alias for computeHan
%
% This adapter does not rename mRLFE model functions or change numerical
% solver behavior. It centralizes GUI-facing model calls for later UI cleanup.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = mergeStructs(rlDefaultParams(), getStructField(guiRequest, 'params', struct()));
options = mergeStructs(rlDefaultOptions(), getStructField(guiRequest, 'options', struct()));

computeElastic = getStructField(guiRequest, 'computeElastic', true);
computeHan = getStructField(guiRequest, 'computeHan', getStructField(guiRequest, 'computeHanVisco', false));
computeA0Like = getStructField(options, 'mrlfeComputeA0Like', true);
computeS0Like = getStructField(options, 'mrlfeComputeS0Like', true);
computeMRLFE = logical(computeElastic || computeHan);

options.computeA0 = logical(getStructField(options, 'computeA0', true) || (computeMRLFE && computeA0Like));
options.computeS0 = logical(getStructField(options, 'computeS0', true) || (computeMRLFE && computeS0Like));
options.computeMRLFE = false;
options.computeMRLFERealK = logical(computeElastic || computeHan);
options.computeMRLFEHanViscoRealK = logical(computeHan);

if isfield(guiRequest, 'mrlfeParams') && isstruct(guiRequest.mrlfeParams)
    options.mrlfeParams = guiRequest.mrlfeParams;
end

rawResult = rlComputeFundamentalLambModes(params, options);
result = guiNormalizeRawResult(rawResult, mfilename);
result.metadata.params = params;
result.metadata.options = options;
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
