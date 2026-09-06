function [sweepResults, sweepSummary, fig, outputFolder, figureFolder] = rlRunSweep(sweepName, branchName, varargin)
%RLRUNSWEEP Run a maintained Rayleigh-Lamb sweep workflow.

p = inputParser;
addRequired(p, 'sweepName', @(x)ischar(x) || isstring(x));
addRequired(p, 'branchName', @(x)ischar(x) || isstring(x));
addParameter(p, 'AssignToBase', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'WriteOutputs', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'LaunchFolder', pwd, @(x)ischar(x) || isstring(x));
addParameter(p, 'ScriptFile', '', @(x)ischar(x) || isstring(x));
parse(p, sweepName, branchName, varargin{:});

sweepName = lower(string(p.Results.sweepName));
branchName = string(p.Results.branchName);

[sweepSpec, caseInfo] = rlMakeSweepSpec(sweepName);
baseParams = rlDefaultSweepParams();
options = rlDefaultSweepOptions(branchName);

referenceMu_kPa = baseParams.mu / 1e3;
referenceThickness_mm = baseParams.thickness * 1e3;

fprintf('\nRayleigh-Lamb %s sweep\n', char(sweepName));
fprintf('Launch folder: %s\n', char(string(p.Results.LaunchFolder)));
fprintf('%s values: %s %s\n', char(string(sweepSpec.label)), mat2str(getDisplayValues(sweepSpec)), char(string(sweepSpec.units)));
fprintf('Elastic reference: mu = %.1f kPa, 2h = %.1f mm\n', referenceMu_kPa, referenceThickness_mm);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', baseParams.fmin, baseParams.fmax / 1e3);
fprintf('Branch: %s\n\n', char(branchName));

sweepResults = runParametricSweep(baseParams, options, sweepSpec, ...
    @(pointParams, pointOptions)rlComputeFundamentalLambModes(pointParams, pointOptions));
sweepSummary = summarizeParametricSweepBranch(sweepResults, caseInfo.modelName, branchName);

plotTitle = "Rayleigh-Lamb " + branchName + ...
    " sensitivity to " + string(caseInfo.titleParameter);
fig = plotParametricSweepCp(sweepResults, caseInfo.modelName, branchName, ...
    'Title', plotTitle, ...
    'FrequencyScale', 1e3, ...
    'FrequencyUnit', "kHz", ...
    'StartFrequencyAtZero', true);

outputFolder = "";
figureFolder = "";
if logical(p.Results.WriteOutputs)
    sweepMetadata = struct();
    sweepMetadata.sweepName = sweepName;
    sweepMetadata.branchName = branchName;
    sweepMetadata.sweepSpec = sweepSpec;
    sweepMetadata.referenceMu_kPa = referenceMu_kPa;
    sweepMetadata.referenceThickness_mm = referenceThickness_mm;

    outputFolder = rlWriteSweepOutputs(p.Results.LaunchFolder, ...
        caseInfo.taskName, caseInfo.taskName + "_" + branchName, ...
        baseParams, options, sweepMetadata, sweepResults, sweepSummary);

    scriptFile = string(p.Results.ScriptFile);
    if strlength(scriptFile) > 0
        figureFolder = rlSaveExampleFigure(fig, scriptFile, ...
            caseInfo.taskName, caseInfo.filePrefix + "_" + branchName);
    end
end

if logical(p.Results.AssignToBase)
    [resultName, summaryName] = rlSweepWorkspaceNames(sweepName, branchName);
    assignin('base', resultName, sweepResults);
    assignin('base', summaryName, sweepSummary);
    if strlength(string(outputFolder)) > 0
        assignin('base', [resultName 'OutputFolder'], outputFolder);
    end
    if strlength(string(figureFolder)) > 0
        assignin('base', [resultName 'FigureFolder'], figureFolder);
    end
end
end

function values = getDisplayValues(sweepSpec)
if isfield(sweepSpec, 'displayValues') && ~isempty(sweepSpec.displayValues)
    values = sweepSpec.displayValues;
else
    values = sweepSpec.values ./ sweepSpec.displayScale;
end
end

function [resultName, summaryName] = rlSweepWorkspaceNames(sweepName, branchName)
switch lower(string(sweepName))
    case "thickness"
        prefix = "RayleighLambThicknessSweep";
    otherwise
        error('Unsupported Rayleigh-Lamb sweepName "%s".', char(sweepName));
end
resultName = char(prefix + string(branchName) + "Results");
summaryName = char(prefix + string(branchName) + "Summary");
end
