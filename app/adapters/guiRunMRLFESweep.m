function sweepOutput = guiRunMRLFESweep(request)
%GUIRUNMRLFESWEEP Run an mRLFE one-parameter sweep from a GUI request.
%
% The adapter owns mRLFE-specific options, unit conversion, solver calls, and
% summary generation. SweepTool_GUI should not call runParametricSweep or
% summarizeParametricSweepBranch directly.

params = request.baseParams;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";

controls = request.controls;
if ~isfield(controls, 'robustness') || strlength(string(controls.robustness)) == 0
    controls.robustness = "Fast";
end

options = rlDefaultOptions(string(controls.robustness));
options.computeMRLFEComplexK = false;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = getControlValue(controls, 'fluidDensity', 1000);
options.mrlfeParams.fluidSoundSpeed = getControlValue(controls, 'fluidSoundSpeed', 1500);
options.mrlfeParams.etaS = getControlValue(controls, 'etaS', 0.05);
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;

branchName = string(request.branchName);
options.computeA0 = branchName == "A0Like";
options.computeS0 = branchName == "S0Like";
options.mrlfeComputeA0Like = branchName == "A0Like";
options.mrlfeComputeS0Like = branchName == "S0Like";

[modelName, options] = configureMRLFEModelOptions(options, string(request.modelLabel), string(request.sweepField));
[valuesSolver, displayScale, units] = convertMRLFEDisplayValues(string(request.sweepField), request.sweepValuesDisplay);

sweepSpec = struct();
sweepSpec.parameter = string(request.sweepField);
sweepSpec.values = valuesSolver;
sweepSpec.label = string(request.sweepLabel);
sweepSpec.units = units;
sweepSpec.displayScale = displayScale;

rawResults = runParametricSweep(params, options, sweepSpec);
summaryTable = summarizeParametricSweepBranch(rawResults, modelName, branchName, 'Print', false);
normalized = guiNormalizeMRLFESweep(rawResults, summaryTable, request, modelName, branchName);

sweepOutput = struct();
sweepOutput.request = request;
sweepOutput.modelFamily = "mrlfe";
sweepOutput.modelName = modelName;
sweepOutput.branchName = branchName;
sweepOutput.sweepSpec = sweepSpec;
sweepOutput.rawResults = rawResults;
sweepOutput.summaryTable = summaryTable;
sweepOutput.normalized = normalized;
end

function value = getControlValue(controls, fieldName, defaultValue)
if isstruct(controls) && isfield(controls, fieldName) && ~isempty(controls.(fieldName))
    value = controls.(fieldName);
else
    value = defaultValue;
end
end

function [modelName, options] = configureMRLFEModelOptions(options, modelLabel, sweepParameter)
if modelLabel == "Elastic real-k"
    if sweepParameter == "etaS"
        error('etaS only affects the viscoelastic real-k model. Select Viscoelastic real-k or sweep E/thickness.');
    end
    options.computeMRLFERealK = true;
    options.computeMRLFEHanViscoRealK = false;
    modelName = "mRLFEElasticRealK";
else
    options.computeMRLFERealK = true;
    options.computeMRLFEHanViscoRealK = true;
    modelName = "mRLFEHanViscoRealK";
end
end

function [valuesSolver, displayScale, units] = convertMRLFEDisplayValues(parameter, valuesDisplayed)
switch string(parameter)
    case "etaS"
        valuesSolver = valuesDisplayed;
        displayScale = 1;
        units = "Pa*s";
    case "E"
        valuesSolver = valuesDisplayed * 1e3;
        displayScale = 1e3;
        units = "kPa";
    case "thickness"
        valuesSolver = valuesDisplayed * 1e-3;
        displayScale = 1e-3;
        units = "mm";
    otherwise
        error('Unsupported mRLFE sweep parameter: %s', string(parameter));
end
end
