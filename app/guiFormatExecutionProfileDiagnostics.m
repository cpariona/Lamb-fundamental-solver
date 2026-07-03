function lines = guiFormatExecutionProfileDiagnostics(metadata, varargin)
%GUIFORMATEXECUTIONPROFILEDIAGNOSTICS Format common execution-profile diagnostics.
%
% This helper is presentation-only. It assumes model adapters already resolved
% requested/effective profiles and only turns metadata into stable text lines.

p = inputParser;
addRequired(p, 'metadata', @(x)isstruct(x) || isempty(x));
addParameter(p, 'Surface', "", @(x)ischar(x) || isstring(x));
addParameter(p, 'Model', "", @(x)ischar(x) || isstring(x));
addParameter(p, 'ControlProfile', "", @(x)ischar(x) || isstring(x));
addParameter(p, 'VisibleBranch', "", @(x)ischar(x) || isstring(x));
addParameter(p, 'ValidCount', nan, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'TotalCount', nan, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'ElapsedSeconds', nan, @(x)isnumeric(x) && isscalar(x));
addParameter(p, 'Fallback', "", @(x)ischar(x) || isstring(x) || islogical(x) || isnumeric(x));
addParameter(p, 'ExtraLines', strings(0, 1), @(x)ischar(x) || isstring(x) || iscellstr(x));
parse(p, metadata, varargin{:});

metadata = localMetadata(metadata);
lines = strings(0, 1);

lines(end+1) = "Execution profile";
lines = appendIfText(lines, "  surface: ", p.Results.Surface);
lines = appendIfText(lines, "  model: ", p.Results.Model);
lines = appendIfText(lines, "  control value: ", p.Results.ControlProfile);
lines(end+1) = "  requested: " + localField(metadata, 'requestedExecutionProfile', "");
lines(end+1) = "  effective: " + localField(metadata, 'effectiveExecutionProfile', "");
lines(end+1) = "  source: " + localField(metadata, 'executionProfileSource', "");
lines(end+1) = "  support mode: " + localField(metadata, 'profileSupportMode', "");
lines(end+1) = "  override applied: " + string(logical(localField(metadata, 'profileOverrideApplied', false)));
reason = localField(metadata, 'profileOverrideReason', "");
if strlength(reason) == 0
    reason = "not applicable";
end
lines(end+1) = "  override reason: " + reason;

lines(end+1) = "Internal configuration";
lines(end+1) = "  solver preset: " + displayValue(localField(metadata, 'internalSolverPreset', ""));
lines(end+1) = "  atlas preset: " + displayValue(localField(metadata, 'internalAtlasPreset', ""));
lines(end+1) = "  route policy: " + displayValue(localField(metadata, 'routePolicy', ""));
if isfield(metadata, 'actualRoute') && strlength(string(metadata.actualRoute)) > 0
    lines(end+1) = "  actual route: " + string(metadata.actualRoute);
end
settings = formatEffectiveNumericalSettings(metadata);
if isempty(settings)
    lines(end+1) = "  effective numerical settings: not applicable";
else
    lines(end+1) = "  effective numerical settings:";
    settingLines = strings(numel(settings), 1);
    for iSetting = 1:numel(settings)
        settingLines(iSetting) = "    " + settings(iSetting);
    end
    lines = [lines(:); settingLines(:)]; %#ok<AGROW>
end

lines(end+1) = "Result";
lines = appendIfText(lines, "  visible branch: ", p.Results.VisibleBranch);
if isfinite(p.Results.ValidCount) && isfinite(p.Results.TotalCount)
    lines(end+1) = sprintf("  valid points: %d/%d", p.Results.ValidCount, p.Results.TotalCount);
end
if isfinite(p.Results.ElapsedSeconds)
    lines(end+1) = sprintf("  elapsed time: %.6g s", p.Results.ElapsedSeconds);
end
fallback = string(p.Results.Fallback);
if strlength(fallback) > 0
    lines(end+1) = "  fallback: " + fallback;
end

extra = string(p.Results.ExtraLines);
extra = extra(:);
extra = extra(strlength(extra) > 0);
if ~isempty(extra)
    lines(end+1) = "Additional diagnostics";
    extraLines = strings(numel(extra), 1);
    for iExtra = 1:numel(extra)
        extraLines(iExtra) = "  " + extra(iExtra);
    end
    lines = [lines(:); extraLines(:)]; %#ok<AGROW>
end
lines = lines(:);
end

function lines = appendIfText(lines, prefix, value)
value = string(value);
if strlength(value) > 0
    lines(end+1) = string(prefix) + value;
end
end

function metadata = localMetadata(metadata)
if isempty(metadata) || ~isstruct(metadata)
    metadata = struct();
end
end

function value = localField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function text = displayValue(value)
text = string(value);
if isempty(text) || strlength(text(1)) == 0
    text = "not applicable";
else
    text = text(1);
end
end

function settings = formatEffectiveNumericalSettings(metadata)
settings = strings(0, 1);

if isfield(metadata, 'gridPointsInitial')
    settings(end+1) = "gridPointsInitial = " + string(metadata.gridPointsInitial);
end
if isfield(metadata, 'gridPointsTracking')
    settings(end+1) = "gridPointsTracking = " + string(metadata.gridPointsTracking);
end
if isfield(metadata, 'jumpTol')
    settings(end+1) = "jumpTol = " + string(metadata.jumpTol);
end
if isfield(metadata, 'mrlfeGridPoints')
    settings(end+1) = "mrlfeGridPoints = " + string(metadata.mrlfeGridPoints);
end
if isfield(metadata, 'searchFactors')
    settings(end+1) = "searchFactors = " + mat2str(metadata.searchFactors);
end
if isfield(metadata, 'mrlfeComplexMaxIter')
    settings(end+1) = "mrlfeComplexMaxIter = " + string(metadata.mrlfeComplexMaxIter);
end
if isfield(metadata, 'mrlfeComplexMaxFunEvals')
    settings(end+1) = "mrlfeComplexMaxFunEvals = " + string(metadata.mrlfeComplexMaxFunEvals);
end

if isfield(metadata, 'atlasNumYPoints')
    settings(end+1) = "atlasNumYPoints = " + string(metadata.atlasNumYPoints);
end
if isfield(metadata, 'atlasTopNMinima')
    settings(end+1) = "atlasTopNMinima = " + string(metadata.atlasTopNMinima);
end
if isfield(metadata, 'atlasInitializationNumFrequencyPoints')
    settings(end+1) = "atlasInitializationNumFrequencyPoints = " + string(metadata.atlasInitializationNumFrequencyPoints);
end

if isfield(metadata, 'etaS')
    settings(end+1) = "etaS = " + string(metadata.etaS) + " Pa*s";
end
if isfield(metadata, 'useUnifiedAtlasRoute')
    settings(end+1) = "useUnifiedAtlasRoute = " + string(logical(metadata.useUnifiedAtlasRoute));
end
if isfield(metadata, 'a0Policy')
    settings(end+1) = "A0 policy = " + string(metadata.a0Policy);
end
end
