function [sweepResults, sweepSummary, fig, outputFolder, figureFolder] = mrlfeRunSweepExample(sweepName, branchName, varargin)
%MRLFERUNSWEEPEXAMPLE Run a maintained mRLFE sweep example.
%
% This helper centralizes the shared setup used by the public mRLFE sweep
% entrypoints. Public scripts should define only the sweep and branch.

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

referenceMu_kPa = baseParams.E / 3 / 1e3;
referenceThickness_mm = baseParams.thickness * 1e3;
referenceEtaS = caseInfo.fixedEtaS;

fprintf('\nmRLFE %s sweep\n', char(sweepName));
fprintf('Launch folder: %s\n', char(string(p.Results.LaunchFolder)));
fprintf('%s values: %s %s\n', char(string(sweepSpec.label)), mat2str(sweepResultsDisplayValues(sweepSpec)), char(string(sweepSpec.units)));
fprintf('Fixed reference: mu = %.1f kPa, etaS = %.3g Pa*s, 2h = %.1f mm\n', referenceMu_kPa, referenceEtaS, referenceThickness_mm);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', baseParams.fmin, baseParams.fmax / 1e3);
fprintf('Branch: %s\n\n', char(branchName));

sweepResults = runParametricSweep(baseParams, options, sweepSpec);
sweepSummary = summarizeParametricSweepBranch(sweepResults, ...
    caseInfo.modelName, branchName);

plotTitle = composeMrlfeSweepTitle(branchName, caseInfo.titleParameter, ...
    sweepName, referenceMu_kPa, referenceEtaS, referenceThickness_mm);

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

function titleText = composeMrlfeSweepTitle(branchName, titleParameter, sweepName, referenceMu_kPa, referenceEtaS, referenceThickness_mm)
mainTitle = sprintf('mRLFE %s sensitivity to %s', ...
    char(formatBranchForTitle(branchName)), char(titleParameter));

switch lower(string(sweepName))
    case "mu"
        fixedText = sprintf('Fixed: etaS = %.3g Pa*s, 2h = %.1f mm', referenceEtaS, referenceThickness_mm);
    case "thickness"
        fixedText = sprintf('Fixed: mu = %.1f kPa, etaS = %.3g Pa*s', referenceMu_kPa, referenceEtaS);
    otherwise
        fixedText = sprintf('Fixed: mu = %.1f kPa, 2h = %.1f mm', ...
            referenceMu_kPa, referenceThickness_mm);
end

titleText = string({mainTitle; fixedText});
end

function values = sweepResultsDisplayValues(sweepSpec)
if isfield(sweepSpec, 'displayValues') && ~isempty(sweepSpec.displayValues)
    values = sweepSpec.displayValues;
else
    values = sweepSpec.values ./ sweepSpec.displayScale;
end
end

function txt = formatBranchForTitle(branchName)
branchName = string(branchName);
switch branchName
    case "A0Like"
        txt = "A0-like";
    case "S0Like"
        txt = "S0-like";
    otherwise
        txt = branchName;
end
end

function [resultName, summaryName] = mrlfeSweepWorkspaceNames(sweepName, branchName)
sweepName = lower(string(sweepName));
branchName = string(branchName);

switch sweepName
    case {"mu", "stiffness"}
        prefix = "MRLFEMuSweep";
    case "viscosity"
        prefix = "MRLFEViscositySweep";
    case "thickness"
        prefix = "MRLFEThicknessSweep";
    otherwise
        error('Unsupported mRLFE sweepName "%s".', char(sweepName));
end

resultName = char(prefix + branchName + "Results");
summaryName = char(prefix + branchName + "Summary");
end
