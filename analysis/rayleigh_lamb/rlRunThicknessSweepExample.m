function [sweepResults, a0Summary, s0Summary, a0Fig, s0Fig, outputFolder, figureFolder] = rlRunThicknessSweepExample(varargin)
%RLRUNTHICKNESSSWEEPEXAMPLE Run the maintained Rayleigh-Lamb thickness sweep.
%
% This helper keeps the public example short while reusing the generic
% parametric sweep and plotting utilities.

p = inputParser;
addParameter(p, 'AssignToBase', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'WriteOutputs', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'LaunchFolder', pwd, @(x)ischar(x) || isstring(x));
addParameter(p, 'ScriptFile', '', @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

[sweepSpec, caseInfo] = rlMakeSweepSpec("thickness");
baseParams = rlDefaultSweepParams();
options = rlDefaultSweepOptions();

referenceMu_kPa = baseParams.E / 3 / 1e3;
referenceThickness_mm = baseParams.thickness * 1e3;

fprintf('\nRayleigh-Lamb thickness sweep\n');
fprintf('Launch folder: %s\n', char(string(p.Results.LaunchFolder)));
fprintf('%s values: %s %s\n', char(string(sweepSpec.label)), mat2str(getDisplayValues(sweepSpec)), char(string(sweepSpec.units)));
fprintf('Elastic reference: mu = %.1f kPa, 2h = %.1f mm\n', referenceMu_kPa, referenceThickness_mm);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n\n', baseParams.fmin, baseParams.fmax / 1e3);

sweepResults = runParametricSweep(baseParams, options, sweepSpec);

a0Title = string({ ...
    sprintf('Rayleigh-Lamb A0 sensitivity to %s', char(caseInfo.titleParameter)); ...
    sprintf('Elastic reference: mu = %.1f kPa', referenceMu_kPa)});
s0Title = string({ ...
    sprintf('Rayleigh-Lamb S0 sensitivity to %s', char(caseInfo.titleParameter)); ...
    sprintf('Elastic reference: mu = %.1f kPa', referenceMu_kPa)});

a0Fig = plotParametricSweepCp(sweepResults, "RayleighLamb", "A0", ...
    'Title', a0Title, ...
    'FrequencyScale', 1e3, ...
    'FrequencyUnit', "kHz", ...
    'StartFrequencyAtZero', true);

s0Fig = plotParametricSweepCp(sweepResults, "RayleighLamb", "S0", ...
    'Title', s0Title, ...
    'FrequencyScale', 1e3, ...
    'FrequencyUnit', "kHz", ...
    'StartFrequencyAtZero', true);

a0Summary = summarizeParametricSweepBranch(sweepResults, "RayleighLamb", "A0");
s0Summary = summarizeParametricSweepBranch(sweepResults, "RayleighLamb", "S0");

outputFolder = "";
figureFolder = "";
if logical(p.Results.WriteOutputs)
    sweepMetadata = struct();
    sweepMetadata.sweepName = "thickness";
    sweepMetadata.sweepSpec = sweepSpec;
    sweepMetadata.referenceMu_kPa = referenceMu_kPa;
    sweepMetadata.referenceThickness_mm = referenceThickness_mm;

    outputFolder = rlWriteSweepOutputs(p.Results.LaunchFolder, ...
        caseInfo.taskName, caseInfo.taskName, baseParams, options, ...
        sweepMetadata, sweepResults, a0Summary, s0Summary);

    scriptFile = string(p.Results.ScriptFile);
    if strlength(scriptFile) > 0
        figureFolder = rlSaveExampleFigure(a0Fig, scriptFile, ...
            caseInfo.taskName, caseInfo.filePrefix + "_A0");
        rlSaveExampleFigure(s0Fig, scriptFile, ...
            caseInfo.taskName, caseInfo.filePrefix + "_S0");
    end
end

if logical(p.Results.AssignToBase)
    assignin('base', 'RayleighLambThicknessSweepResults', sweepResults);
    assignin('base', 'RayleighLambThicknessSweepA0Summary', a0Summary);
    assignin('base', 'RayleighLambThicknessSweepS0Summary', s0Summary);
    if strlength(string(outputFolder)) > 0
        assignin('base', 'RayleighLambThicknessSweepOutputFolder', outputFolder);
    end
    if strlength(string(figureFolder)) > 0
        assignin('base', 'RayleighLambThicknessSweepFigureFolder', figureFolder);
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
