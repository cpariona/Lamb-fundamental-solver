function plotData = buildParametricSweepPlotData(sweepResults, modelName, branchName)
%BUILDPARAMETRICSWEEPPLOTDATA Normalize RL/mRLFE sweep results for plotting.

if ~isstruct(sweepResults) || ~isfield(sweepResults, 'results') || ...
        ~isfield(sweepResults, 'spec') || ~isfield(sweepResults, 'displayValues')
    error('buildParametricSweepPlotData:InvalidSweepResults', ...
        'Expected runParametricSweep output.');
end

modelName = string(modelName);
branchName = string(branchName);
curves = repmat(struct('frequency_Hz', [], 'Cp_mps', [], ...
    'valid', [], 'legendLabel', ""), 1, numel(sweepResults.results));

for i = 1:numel(sweepResults.results)
    branch = extractSweepBranch(sweepResults.results{i}, modelName, branchName);
    if isempty(branch)
        curves(i).frequency_Hz = nan;
        curves(i).Cp_mps = nan;
        curves(i).valid = false;
    else
        curves(i).frequency_Hz = branch.frequency_Hz(:);
        curves(i).Cp_mps = branch.phaseVelocity_mps(:);
        curves(i).valid = getBranchValidityMask(branch);
    end
    curves(i).legendLabel = makeLegendLabel(sweepResults, i);
end

plotData = struct();
plotData.curves = curves;
plotData.titleText = makeTitle(modelName, branchName, sweepResults.spec);
plotData.fixedParameterLines = makeFixedParameterLines( ...
    sweepResults, modelName, string(sweepResults.parameter));
end

function branch = extractSweepBranch(result, modelName, branchName)
branch = [];
if modelName == "RayleighLamb"
    if isfield(result, 'modes') && isfield(result.modes, char(branchName))
        branch = result.modes.(char(branchName));
    end
    return;
end

if isfield(result, 'model') && string(result.model) == "mrlfe" && ...
        string(result.branch) == branchName
    branch = result;
    return;
end

end

function valid = getBranchValidityMask(branch)
valid = logical(branch.validMask(:)) & isfinite(branch.phaseVelocity_mps(:));
end

function txt = makeLegendLabel(sweepResults, idx)
spec = sweepResults.spec;
value = sweepResults.displayValues(idx);
label = compactLabel(string(sweepResults.parameter));
if isfield(spec, 'units') && strlength(string(spec.units)) > 0
    txt = sprintf('%s = %.4g %s', label, value, string(spec.units));
else
    txt = sprintf('%s = %.4g', label, value);
end
end

function titleText = makeTitle(modelName, branchName, spec)
modelLabel = modelName;
if modelName == "mRLFERealK" || modelName == "mRLFEViscoRealK"
    modelLabel = "mRLFE";
end
branchLabel = formatBranch(branchName);
sweepLabel = string(spec.label);
titleText = modelLabel + " " + branchLabel + " sensitivity to " + lower(sweepLabel);
end

function label = formatBranch(branchName)
switch string(branchName)
    case "A0Like"
        label = "A0-like";
    case "S0Like"
        label = "S0-like";
    otherwise
        label = string(branchName);
end
end

function label = compactLabel(parameter)
switch string(parameter)
    case "thickness"
        label = "2h";
    otherwise
        label = string(parameter);
end
end

function lines = makeFixedParameterLines(sweepResults, modelName, sweptParameter)
lines = strings(0, 1);
if ~isfield(sweepResults, 'params') || isempty(sweepResults.params)
    return;
end
params = sweepResults.params{1};

if modelName == "RayleighLamb"
    lines = addIfFixed(lines, sweptParameter, "mu", "mu = " + formatValue(params, 'mu', 1e3, '%.1f', 'kPa'));
    lines = addIfFixed(lines, sweptParameter, "nu", "nu = " + formatValue(params, 'nu', 1, '%.4f', ''));
    lines = addIfFixed(lines, sweptParameter, "thickness", "2h = " + formatValue(params, 'thickness', 1e-3, '%.1f', 'mm'));
    lines = addIfFixed(lines, sweptParameter, "rho", "rho = " + formatValue(params, 'rho', 1, '%.0f', 'kg/m^3'));
    return;
end

if modelName == "mRLFERealK" || modelName == "mRLFEViscoRealK"
    lines = addIfFixed(lines, sweptParameter, "mu", "mu = " + formatValue(params, 'mu', 1e3, '%.1f', 'kPa'));
    lines = addIfFixed(lines, sweptParameter, "thickness", "2h = " + formatValue(params, 'thickness', 1e-3, '%.1f', 'mm'));
    lines = addIfFixed(lines, sweptParameter, "rho", "rho = " + formatValue(params, 'rho', 1, '%.0f', 'kg/m^3'));
    if isfield(sweepResults, 'options') && ~isempty(sweepResults.options)
        options = sweepResults.options{1};
        if sweptParameter ~= "etaS" && isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, 'etaS')
            lines(end+1, 1) = "etaS = " + sprintf('%.3g Pa*s', options.mrlfeParams.etaS);
        end
    end
end
end

function lines = addIfFixed(lines, sweptParameter, fieldName, textValue)
if sweptParameter ~= string(fieldName) && ~contains(textValue, "missing")
    lines(end+1, 1) = textValue;
end
end

function textValue = formatValue(params, fieldName, scale, formatSpec, unit)
if ~isfield(params, fieldName) || isempty(params.(fieldName))
    textValue = "missing";
    return;
end
value = params.(fieldName) ./ scale;
textValue = string(sprintf(formatSpec, value));
if strlength(string(unit)) > 0
    textValue = textValue + " " + string(unit);
end
end
