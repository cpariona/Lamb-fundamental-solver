function [sweepResults, sweepSummary, fig, outputFolder, figureFolder] = mrlfeRunSweep(sweepName, branchName, varargin)
%MRLFERUNSWEEP Run a maintained mRLFE sweep workflow.

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

[sweepSpec, caseInfo] = mrlfeMakeSweepSpec(sweepName);
baseParams = mrlfeDefaultSweepParams();
options = mrlfeDefaultSweepOptions(branchName, 'EtaS', caseInfo.fixedEtaS);

referenceMu_kPa = baseParams.mu / 1e3;
referenceThickness_mm = baseParams.thickness * 1e3;
referenceEtaS = caseInfo.fixedEtaS;

fprintf('\nmRLFE %s sweep\n', char(sweepName));
fprintf('Launch folder: %s\n', char(string(p.Results.LaunchFolder)));
fprintf('%s values: %s %s\n', char(string(sweepSpec.label)), mat2str(sweepResultsDisplayValues(sweepSpec)), char(string(sweepSpec.units)));
fprintf('Fixed reference: mu = %.1f kPa, etaS = %.3g Pa*s, 2h = %.1f mm\n', referenceMu_kPa, referenceEtaS, referenceThickness_mm);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', baseParams.fmin, baseParams.fmax / 1e3);
fprintf('Branch: %s\n\n', char(branchName));

sweepResults = runParametricSweep(baseParams, options, sweepSpec, ...
    @(pointParams, pointOptions)evaluateMRLFE(pointParams, pointOptions, branchName));
sweepSummary = summarizeParametricSweepBranch(sweepResults, caseInfo.modelName, branchName);

plotTitle = "mRLFE " + formatBranchForTitle(branchName) + ...
    " sensitivity to " + string(caseInfo.titleParameter);
fig = plotParametricSweepCp(sweepResults, caseInfo.modelName, branchName, ...
    'Title', plotTitle, ...
    'FrequencyScale', 1e3, ...
    'FrequencyUnit', "kHz", ...
    'StartFrequencyAtZero', true, ...
    'ShowLastValidPoint', false);

outputFolder = "";
figureFolder = "";
if logical(p.Results.WriteOutputs)
    sweepMetadata = struct();
    sweepMetadata.sweepName = sweepName;
    sweepMetadata.branchName = branchName;
    sweepMetadata.sweepSpec = sweepSpec;
    sweepMetadata.referenceMu_kPa = referenceMu_kPa;
    sweepMetadata.referenceEtaS_Pa_s = referenceEtaS;
    sweepMetadata.referenceThickness_mm = referenceThickness_mm;

    outputFolder = mrlfeWriteSweepOutputs(p.Results.LaunchFolder, ...
        caseInfo.taskName, caseInfo.taskName, baseParams, options, ...
        sweepMetadata, sweepResults, sweepSummary);

    scriptFile = string(p.Results.ScriptFile);
    if strlength(scriptFile) > 0
        figureFolder = mrlfeSaveExampleFigure(fig, scriptFile, ...
            caseInfo.taskName, caseInfo.filePrefix + "_" + branchName);
    end
end

if logical(p.Results.AssignToBase)
    [resultName, summaryName] = mrlfeSweepWorkspaceNames(sweepName, branchName);
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

function values = sweepResultsDisplayValues(sweepSpec)
if isfield(sweepSpec, 'displayValues') && ~isempty(sweepSpec.displayValues)
    values = sweepSpec.displayValues;
else
    values = sweepSpec.values ./ sweepSpec.displayScale;
end
end

function txt = formatBranchForTitle(branchName)
switch string(branchName)
    case "A0Like"
        txt = "A0-like";
    case "S0Like"
        txt = "S0-like";
    otherwise
        txt = string(branchName);
end
end

function [resultName, summaryName] = mrlfeSweepWorkspaceNames(sweepName, branchName)
switch lower(string(sweepName))
    case {"mu", "stiffness"}
        prefix = "MRLFEMuSweep";
    case "viscosity"
        prefix = "MRLFEViscositySweep";
    case "thickness"
        prefix = "MRLFEThicknessSweep";
    otherwise
        error('Unsupported mRLFE sweepName "%s".', char(sweepName));
end
resultName = char(prefix + string(branchName) + "Results");
summaryName = char(prefix + string(branchName) + "Summary");
end

function result = evaluateMRLFE(params, options, branchName)
frequency_Hz = lamb.grids.buildFrequencyVector(params);
request = lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
result = lamb.models.mrlfe.mrlfeSolve(request);
end
